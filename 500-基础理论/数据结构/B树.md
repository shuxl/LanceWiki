

# 1 B树概念或介绍

**重点内容：**
- B树是一种多路平衡搜索树，专为磁盘存储设计
- 每个节点可以包含多个键值和子节点指针
- 所有叶子节点都在同一层，确保树的高度平衡
- 通过节点分裂和合并来维护平衡
- 时间复杂度：查找、插入、删除均为O(log n)
- 广泛应用于数据库和文件系统的索引结构

B树（B-Tree）是由Rudolf Bayer和Edward M. McCreight在1972年发明的一种自平衡的多路搜索树。它专门为磁盘存储系统设计，能够有效减少磁盘I/O操作次数。

## 1.1 基本特性

1. **多路搜索树**：每个节点可以有多个子节点（通常为3-5个）
2. **平衡性质**：所有叶子节点都在同一层
3. **键值有序**：每个节点内的键值按升序排列
4. **节点填充度**：除根节点外，每个节点至少有⌈m/2⌉-1个键值，最多有m-1个键值（m为B树的阶）

## 1.2 B树的阶（Order）

B树的阶m决定了每个节点的最大子节点数量：
- 每个节点最多有m个子节点
- 每个节点最多有m-1个键值
- 每个节点至少有⌈m/2⌉个子节点（除根节点外）
- 每个节点至少有⌈m/2⌉-1个键值（除根节点外）

# 2 B树的结构

## 2.1 节点结构

每个B树节点包含：
- 键值数组：存储有序的键值
- 子节点指针数组：指向子节点的指针
- 键值数量：当前节点包含的键值个数
- 是否为叶子节点：标识是否为叶子节点

## 2.2 示例结构

以3阶B树为例（m=3）：
- 每个节点最多有3个子节点
- 每个节点最多有2个键值
- 每个节点至少有2个子节点（除根节点外）
- 每个节点至少有1个键值（除根节点外）

```
        [10, 20]
       /   |   \
   [5,8] [15,18] [25,30]
```

# 3 查找操作

B树的查找操作类似于二叉搜索树，但在每个节点内需要线性搜索：

## 3.1 查找算法

```python
def search(self, key):
    return self._search_recursive(self.root, key)

def _search_recursive(self, node, key):
    if node is None:
        return None
    
    # 在节点内查找键值
    i = 0
    while i < node.num_keys and key > node.keys[i]:
        i += 1
    
    # 如果找到键值
    if i < node.num_keys and key == node.keys[i]:
        return node
    
    # 如果是叶子节点且没找到
    if node.is_leaf:
        return None
    
    # 递归查找子节点
    return self._search_recursive(node.children[i], key)
```

## 3.2 查找复杂度

- **时间复杂度**：O(log n)
- **磁盘I/O次数**：O(log_m n)，其中m是B树的阶
- **空间复杂度**：O(1)（不考虑递归栈）

# 4 插入操作

插入操作是B树最复杂的操作之一，需要处理节点分裂：

## 4.1 插入步骤

1. **查找插入位置**：从根节点开始查找合适的叶子节点
2. **插入键值**：在叶子节点中插入键值
3. **检查节点容量**：如果节点键值数量超过上限，进行分裂
4. **向上传播**：分裂可能向上传播到父节点

## 4.2 节点分裂

当节点键值数量超过m-1时，需要进行分裂：

```python
def _split_child(self, parent, index, child):
    # 创建新的右子节点
    new_child = BTreeNode()
    new_child.is_leaf = child.is_leaf
    
    # 计算分裂点
    mid = self.order // 2
    
    # 移动键值到新节点
    for i in range(mid + 1, child.num_keys):
        new_child.keys[i - mid - 1] = child.keys[i]
        new_child.num_keys += 1
    
    # 如果不是叶子节点，移动子节点指针
    if not child.is_leaf:
        for i in range(mid + 1, child.num_keys + 1):
            new_child.children[i - mid - 1] = child.children[i]
    
    # 更新原节点的键值数量
    child.num_keys = mid
    
    # 在父节点中插入中间键值
    for i in range(parent.num_keys, index, -1):
        parent.keys[i] = parent.keys[i - 1]
        parent.children[i + 1] = parent.children[i]
    
    parent.keys[index] = child.keys[mid]
    parent.children[index + 1] = new_child
    parent.num_keys += 1
```

## 4.3 插入算法

```python
def insert(self, key):
    root = self.root
    
    # 如果根节点已满，需要分裂根节点
    if root.num_keys == 2 * self.order - 1:
        new_root = BTreeNode()
        new_root.is_leaf = False
        new_root.children[0] = root
        self.root = new_root
        self._split_child(new_root, 0, root)
        self._insert_non_full(new_root, key)
    else:
        self._insert_non_full(root, key)

def _insert_non_full(self, node, key):
    i = node.num_keys - 1
    
    if node.is_leaf:
        # 在叶子节点中插入
        while i >= 0 and key < node.keys[i]:
            node.keys[i + 1] = node.keys[i]
            i -= 1
        node.keys[i + 1] = key
        node.num_keys += 1
    else:
        # 找到合适的子节点
        while i >= 0 and key < node.keys[i]:
            i -= 1
        i += 1
        
        # 如果子节点已满，先分裂
        if node.children[i].num_keys == 2 * self.order - 1:
            self._split_child(node, i, node.children[i])
            if key > node.keys[i]:
                i += 1
        
        self._insert_non_full(node.children[i], key)
```

# 5 删除操作

删除操作比插入更复杂，需要处理多种情况：

## 5.1 删除的三种情况

1. **叶子节点删除**：直接删除键值
2. **内部节点删除**：用前驱或后继替换，然后删除前驱或后继
3. **合并操作**：当节点键值数量不足时，需要与兄弟节点合并

## 5.2 删除算法

```python
def delete(self, key):
    if self.root is None:
        return
    
    self._delete_recursive(self.root, key)
    
    # 如果根节点为空且不是叶子节点，更新根节点
    if self.root.num_keys == 0 and not self.root.is_leaf:
        self.root = self.root.children[0]

def _delete_recursive(self, node, key):
    # 查找键值在节点中的位置
    i = 0
    while i < node.num_keys and key > node.keys[i]:
        i += 1
    
    if i < node.num_keys and key == node.keys[i]:
        # 找到键值
        if node.is_leaf:
            # 情况1：叶子节点删除
            self._delete_from_leaf(node, i)
        else:
            # 情况2：内部节点删除
            self._delete_from_internal(node, i)
    else:
        # 键值不在当前节点，递归查找
        if node.is_leaf:
            return  # 键值不存在
        
        # 确保子节点有足够的键值
        if node.children[i].num_keys < self.order:
            self._fill_child(node, i)
        
        # 递归删除
        if i > 0 and i == node.num_keys:
            self._delete_recursive(node.children[i - 1], key)
        else:
            self._delete_recursive(node.children[i], key)
```

# 6 时间复杂度分析

## 6.1 各操作复杂度

- **查找**：O(log n) - 树的高度为log_m n
- **插入**：O(log n) - 需要查找插入位置 + 可能的节点分裂
- **删除**：O(log n) - 需要查找删除位置 + 可能的节点合并
- **空间复杂度**：O(n) - 存储n个键值

## 6.2 磁盘I/O分析

B树的主要优势在于减少磁盘I/O次数：
- **查找I/O次数**：O(log_m n)
- **插入I/O次数**：O(log_m n)
- **删除I/O次数**：O(log_m n)

其中m是B树的阶，通常m很大（如100-1000），使得log_m n很小。

# 7 与B+树的比较

| 特性 | B树 | B+树 |
|------|-----|------|
| 数据存储 | 所有节点都存储数据 | 只有叶子节点存储数据 |
| 叶子节点 | 不连接 | 通过链表连接 |
| 范围查询 | 需要遍历树 | 叶子节点链表遍历 |
| 空间利用率 | 较低 | 较高 |
| 应用场景 | 内存数据库 | 磁盘数据库 |

# 8 实现示例

## 8.1 Python实现

```python
class BTreeNode:
    def __init__(self, order):
        self.order = order
        self.keys = [None] * (2 * order - 1)
        self.children = [None] * (2 * order)
        self.num_keys = 0
        self.is_leaf = True

class BTree:
    def __init__(self, order=3):
        self.root = BTreeNode(order)
        self.order = order
    
    def search(self, key):
        """查找键值"""
        return self._search_recursive(self.root, key)
    
    def _search_recursive(self, node, key):
        if node is None:
            return None
        
        i = 0
        while i < node.num_keys and key > node.keys[i]:
            i += 1
        
        if i < node.num_keys and key == node.keys[i]:
            return node
        
        if node.is_leaf:
            return None
        
        return self._search_recursive(node.children[i], key)
    
    def insert(self, key):
        """插入键值"""
        root = self.root
        
        if root.num_keys == 2 * self.order - 1:
            new_root = BTreeNode(self.order)
            new_root.is_leaf = False
            new_root.children[0] = root
            self.root = new_root
            self._split_child(new_root, 0, root)
            self._insert_non_full(new_root, key)
        else:
            self._insert_non_full(root, key)
    
    def _split_child(self, parent, index, child):
        """分裂子节点"""
        new_child = BTreeNode(self.order)
        new_child.is_leaf = child.is_leaf
        
        mid = self.order - 1
        
        # 移动键值
        for i in range(mid + 1, child.num_keys):
            new_child.keys[i - mid - 1] = child.keys[i]
            new_child.num_keys += 1
        
        # 移动子节点指针
        if not child.is_leaf:
            for i in range(mid + 1, child.num_keys + 1):
                new_child.children[i - mid - 1] = child.children[i]
        
        child.num_keys = mid
        
        # 在父节点中插入中间键值
        for i in range(parent.num_keys, index, -1):
            parent.keys[i] = parent.keys[i - 1]
            parent.children[i + 1] = parent.children[i]
        
        parent.keys[index] = child.keys[mid]
        parent.children[index + 1] = new_child
        parent.num_keys += 1
    
    def _insert_non_full(self, node, key):
        """在非满节点中插入键值"""
        i = node.num_keys - 1
        
        if node.is_leaf:
            while i >= 0 and key < node.keys[i]:
                node.keys[i + 1] = node.keys[i]
                i -= 1
            node.keys[i + 1] = key
            node.num_keys += 1
        else:
            while i >= 0 and key < node.keys[i]:
                i -= 1
            i += 1
            
            if node.children[i].num_keys == 2 * self.order - 1:
                self._split_child(node, i, node.children[i])
                if key > node.keys[i]:
                    i += 1
            
            self._insert_non_full(node.children[i], key)
```

# 9 B树关联的其它知识

## 9.1 相关数据结构

- **B\+树**：B树的变种，广泛应用于数据库索引
- **B\*树**：B树的另一种变种，具有更好的空间利用率
- **[红黑树](红黑树.md)**：内存中的自平衡二叉搜索树
- **[AVL树](AVL树.md)**：严格平衡的二叉搜索树

## 9.2 应用场景

1. **数据库索引**：MySQL、PostgreSQL等数据库的索引结构
2. **文件系统**：NTFS、ext4等文件系统的目录结构
3. **内存数据库**：某些内存数据库的索引实现
4. **网络路由表**：路由器中的路由表存储

## 9.3 算法思想

- **多路搜索**：通过增加每个节点的分支数来减少树的高度
- **磁盘优化**：设计时考虑磁盘I/O的特性
- **自平衡机制**：通过分裂和合并操作维护树的平衡
- **批量操作**：一次I/O操作处理多个键值

## 9.4 扩展知识

- **LSM树**：日志结构合并树，用于写入密集型应用
- **跳表**：基于链表的概率性平衡数据结构
- **Trie树**：前缀树，用于字符串搜索
- **R树**：空间索引结构，用于多维数据
