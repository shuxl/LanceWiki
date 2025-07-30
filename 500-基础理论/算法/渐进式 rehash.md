

# 1 渐进式 rehash 概念或介绍

**重点内容：**
- 渐进式 rehash 的核心思想：将大量数据迁移工作分散到多次操作中
- 双哈希表结构：使用两个哈希表实现平滑迁移
- 迁移策略：每次操作时迁移少量数据，避免长时间阻塞
- 负载因子控制：扩容和收缩的触发条件
- 应用场景：Redis dict、Java HashMap 等高性能哈希表实现

渐进式 rehash 是一种哈希表扩容/收缩的优化策略，通过将原本需要一次性完成的大量数据迁移工作分散到多次操作中，避免在数据量较大时出现长时间的阻塞，保证系统的响应性能。

**注意**：本文档基于Redis的渐进式rehash实现，这是最经典和广泛应用的渐进式rehash算法。其他实现可能有所不同，但核心思想是一致的。

## 1.1 核心思想

传统的哈希表扩容需要一次性将所有数据从旧表迁移到新表，当数据量很大时，这个过程会占用大量时间，导致系统暂时不可用。渐进式 rehash 通过以下方式解决这个问题：

1. **双哈希表结构**：维护两个哈希表（ht[0] 主表和 ht[1] 新表）
2. **分步迁移**：每次增删查操作时"顺便"迁移1～N个桶
3. **平滑过渡**：在迁移过程中，新数据直接写入新表ht[1]，查询时先查新表再查旧表
4. **完成切换**：迁移完成后，将ht[1]设为新的主表，清空ht[0]

# 2 实现机制

## 2.1 数据结构设计

```python
class Dict:
    def __init__(self):
        self.ht = [HashTable(), HashTable()]  # 两个哈希表
        self.rehashidx = -1  # rehash 进度索引，-1表示未进行rehash
        self.used = [0, 0]   # 两个表的使用量
```

## 2.2 迁移策略

渐进式 rehash 的迁移策略通常包括：

1. **触发条件**：
   - 扩容：负载因子 > 1（元素数量 / 桶数量）
   - 收缩：负载因子 < 0.1

2. **迁移过程**：
   - 分配新表空间（扩容时2倍，收缩时1/2）
   - 设置 rehashidx = 0，标记开始 rehash
   - 每次增删查操作时"顺便"迁移1～N个桶
   - 迁移完成后 rehashidx++

3. **操作处理**：
   - 新增：直接写入新表 ht[1]
   - 查询：先查新表 ht[1]，再查旧表 ht[0]
   - 删除：先查新表 ht[1]，再查旧表 ht[0]

## 2.3 迁移算法

```python
def dict_rehash_step(dict_obj, n=1):
    """
    执行 n 步 rehash 操作
    每次迁移 n 个桶（通常 n=1，但可以根据需要调整）
    """
    if dict_obj.rehashidx == -1:
        return 0
    
    # 限制单次迁移的桶数量，避免阻塞时间过长
    max_steps = min(n, 10)  # 最多迁移10个桶
    
    while max_steps > 0 and dict_obj.rehashidx < dict_obj.ht[0].size:
        # 获取当前要迁移的桶
        bucket = dict_obj.ht[0].table[dict_obj.rehashidx]
        
        # 迁移该桶中的所有元素
        while bucket:
            next_bucket = bucket.next
            # 重新计算哈希值，插入到新表 ht[1]
            new_index = hash(bucket.key) % dict_obj.ht[1].size
            bucket.next = dict_obj.ht[1].table[new_index]
            dict_obj.ht[1].table[new_index] = bucket
            dict_obj.used[1] += 1
            bucket = next_bucket
        
        # 清空旧桶
        dict_obj.ht[0].table[dict_obj.rehashidx] = None
        dict_obj.used[0] -= 1
        dict_obj.rehashidx += 1
        max_steps -= 1
    
    # 检查是否完成迁移
    if dict_obj.rehashidx >= dict_obj.ht[0].size:
        # 迁移完成，将 ht[1] 设为新的主表，清空 ht[0]
        dict_obj.ht[0] = dict_obj.ht[1]
        dict_obj.ht[1] = HashTable()  # 创建新的空表
        dict_obj.used[0] = dict_obj.used[1]
        dict_obj.used[1] = 0
        dict_obj.rehashidx = -1
        return 0
    
    return 1  # 还有数据需要迁移
```

# 3 操作实现

## 3.1 查找操作

```python
def dict_find(dict_obj, key):
    """
    在字典中查找键值对
    """
    # 如果正在进行 rehash，先执行一步迁移
    if dict_obj.rehashidx != -1:
        dict_rehash_step(dict_obj, 1)
    
    # 计算哈希值
    hash_value = hash(key)
    
    # 先在新表 ht[1] 中查找（如果正在 rehash）
    if dict_obj.rehashidx != -1 and dict_obj.ht[1].size > 0:
        index = hash_value % dict_obj.ht[1].size
        bucket = dict_obj.ht[1].table[index]
        while bucket:
            if bucket.key == key:
                return bucket.value
            bucket = bucket.next
    
    # 再在主表 ht[0] 中查找
    if dict_obj.ht[0].size > 0:
        index = hash_value % dict_obj.ht[0].size
        bucket = dict_obj.ht[0].table[index]
        while bucket:
            if bucket.key == key:
                return bucket.value
            bucket = bucket.next
    
    return None
```

## 3.2 插入操作

```python
def dict_add(dict_obj, key, value):
    """
    向字典中添加键值对
    """
    # 如果正在进行 rehash，先执行一步迁移
    if dict_obj.rehashidx != -1:
        dict_rehash_step(dict_obj, 1)
    
    # 检查是否需要开始 rehash
    if dict_obj.rehashidx == -1:
        load_factor = dict_obj.used[0] / dict_obj.ht[0].size
        if load_factor > 1:  # 需要扩容
            dict_expand(dict_obj, dict_obj.ht[0].size * 2)
    
    # 创建新节点
    new_node = Node(key, value)
    hash_value = hash(key)
    
    # 如果正在 rehash，新数据直接写入新表 ht[1]
    # 否则写入主表 ht[0]
    target_table = 1 if dict_obj.rehashidx != -1 else 0
    index = hash_value % dict_obj.ht[target_table].size
    
    # 使用头插法
    new_node.next = dict_obj.ht[target_table].table[index]
    dict_obj.ht[target_table].table[index] = new_node
    dict_obj.used[target_table] += 1
```

# 4 性能分析

## 4.1 时间复杂度

- **单次操作**：O(1) 平均情况
- **迁移过程**：O(n) 总时间，但分散到多次操作中
- **内存使用**：迁移期间需要双倍内存

## 4.2 优势

1. **响应性**：避免长时间阻塞
2. **平滑性**：系统性能不会出现明显波动
3. **可中断性**：迁移过程可以随时暂停和恢复

## 4.3 劣势

1. **内存开销**：迁移期间需要双倍内存
2. **查找开销**：查询时可能需要查找两个表
3. **实现复杂度**：比传统扩容更复杂

# 5 应用场景

## 5.1 Redis Dict

Redis 的字典实现是渐进式 rehash 的典型应用：

- 使用两个哈希表 ht[0]（主表）和 ht[1]（新表）
- 通过 rehashidx 记录迁移进度（-1表示未进行rehash，>=0表示正在rehash）
- 在每次增删改查操作时"顺便"迁移1～N个桶
- 新数据直接写入新表ht[1]，查询时先查新表再查旧表
- 迁移完成后，将ht[1]设为新的主表，清空ht[0]

## 5.2 Java HashMap

Java 8+ 的 HashMap 也采用了类似的思想：

- 使用红黑树优化链表过长的情况
- 扩容时采用分步迁移策略
- 通过 resize() 方法实现平滑扩容

# 6 渐进式 rehash 关联的其它知识

## 6.1 相关数据结构

- [哈希表](../数据结构/哈希表.md)：渐进式 rehash 的基础数据结构
- [开放寻址法（Open Addressing）](./开放寻址法（Open%20Addressing）.md)：另一种哈希冲突解决方法

## 6.2 相关算法

- [分布式蓄水池算法](./分布式蓄水池算法.md)：另一种分步处理大量数据的算法
- [渐进式 rehash](./渐进式%20rehash.md)：本文主题

## 6.3 实际应用
- **Redis**：字典数据结构的核心实现
- **Java Collections**：HashMap、ConcurrentHashMap 的扩容机制
- **数据库索引**：B+树的分裂和合并操作
- **缓存系统**：内存缓存的扩容策略

## 6.4 性能优化
- **负载均衡**：通过合理的负载因子控制扩容时机
- **内存管理**：在内存敏感场景下的优化策略
- **并发控制**：多线程环境下的 rehash 安全保证