# Redis对象与编码对应关系

## 重点
- Redis对象类型与底层编码的对应关系
- 不同数据类型的编码方式选择策略
- 编码转换机制和触发条件
- 内存优化机制和性能考虑
- 编码方式对操作复杂度的影响

## Redis对象与编码对应关系概念或介绍

Redis的对象系统采用了一种巧妙的设计：每种对象类型都支持多种底层编码方式。这种设计使得Redis能够根据数据特征自动选择最优的存储方式，在保证功能完整性的同时最大化内存使用效率和操作性能。

Redis的对象与编码对应关系体现了以下设计思想：
1. **灵活性**：同一对象类型支持多种编码方式
2. **自适应性**：根据数据特征自动选择最优编码
3. **内存效率**：针对不同场景优化内存使用
4. **性能平衡**：在内存使用和操作性能间找到平衡点

## Redis对象类型与编码对应关系

### 1. 字符串对象（OBJ_STRING）

字符串对象支持三种编码方式：

#### EMBSTR编码
```c
// 嵌入式字符串编码
typedef struct {
    uint32_t len;     // 字符串长度
    uint8_t alloc;    // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];       // 字符串内容
} embstr;
```

**使用条件**：
- 字符串长度 ≤ 44字节
- 字符串内容为简单字符串

**优势**：
- 内存分配一次，减少内存碎片
- 缓存友好，数据局部性好
- 减少指针解引用次数

**内存布局**：
```
[redisObject][embstr结构][字符串内容]
```

#### RAW编码
```c
// 原始字符串编码
typedef struct {
    uint32_t len;     // 字符串长度
    uint32_t alloc;   // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];       // 字符串内容
} sds;
```

**使用条件**：
- 字符串长度 > 44字节
- 需要动态扩容的字符串

**优势**：
- 支持动态扩容
- 适合大字符串存储
- 内存使用灵活

#### INT编码
```c
// 整数编码
// 直接使用void *ptr存储整数值
```

**使用条件**：
- 字符串可以转换为整数
- 整数值在long范围内

**优势**：
- 内存占用最小
- 数值操作效率高
- 支持整数运算

### 2. 列表对象（OBJ_LIST）

列表对象支持两种编码方式：

#### QUICKLIST编码
```c
// 快速列表编码
typedef struct quicklist {
    quicklistNode *head;     // 头节点
    quicklistNode *tail;     // 尾节点
    unsigned long count;     // 总节点数
    unsigned long len;       // 快速列表长度
    int fill : 16;          // 压缩深度
    unsigned int compress : 16; // 压缩深度
} quicklist;

typedef struct quicklistNode {
    struct quicklistNode *prev;  // 前驱节点
    struct quicklistNode *next;  // 后继节点
    unsigned char *zl;           // 压缩列表指针
    unsigned int sz;             // 压缩列表大小
    unsigned int count : 16;     // 节点数量
    unsigned int encoding : 2;   // 编码方式
    unsigned int container : 2;  // 容器类型
    unsigned int recompress : 1; // 重新压缩标志
    unsigned int attempted_compress : 1; // 尝试压缩标志
    unsigned int extra : 10;     // 额外信息
} quicklistNode;
```

**使用条件**：
- 列表元素较多时
- 需要频繁的插入删除操作

**优势**：
- 结合了链表和压缩列表的优点
- 支持分段压缩
- 插入删除效率高

#### ZIPLIST编码
```c
// 压缩列表编码
typedef struct zlentry {
    unsigned int prevrawlensize; // 前一个节点长度编码大小
    unsigned int prevrawlen;     // 前一个节点长度
    unsigned int lensize;        // 当前节点长度编码大小
    unsigned int len;            // 当前节点长度
    unsigned int headersize;     // 头部大小
    unsigned char encoding;      // 编码方式
    unsigned char *p;           // 指向当前节点的指针
} zlentry;
```

**使用条件**：
- 列表元素较少时
- 元素大小相对固定

**优势**：
- 内存紧凑
- 适合小列表
- 缓存友好

### 3. 哈希对象（OBJ_HASH）

哈希对象支持两种编码方式：

#### HT编码（哈希表）
```c
// 哈希表编码
typedef struct dict {
    dictType *type;        // 字典类型
    void *privdata;        // 私有数据
    dictht ht[2];         // 哈希表数组
    long rehashidx;       // 重哈希索引
    unsigned long iterators; // 迭代器数量
} dict;

typedef struct dictht {
    dictEntry **table;     // 哈希表数组
    unsigned long size;    // 哈希表大小
    unsigned long sizemask; // 大小掩码
    unsigned long used;    // 已使用节点数
} dictht;
```

**使用条件**：
- 哈希表元素较多时
- 需要频繁的查找操作

**优势**：
- 查找效率高，O(1)平均时间复杂度
- 支持动态扩容
- 适合大哈希表

#### ZIPLIST编码
```c
// 压缩列表编码
// 使用压缩列表存储键值对
```

**使用条件**：
- 哈希表元素较少时
- 键值对大小相对固定

**优势**：
- 内存紧凑
- 适合小哈希表
- 缓存友好

### 4. 集合对象（OBJ_SET）

集合对象支持两种编码方式：

#### HT编码（哈希表）
```c
// 哈希表编码
// 与哈希对象相同的结构
```

**使用条件**：
- 集合元素较多时
- 需要频繁的查找操作

**优势**：
- 查找效率高
- 支持动态扩容
- 适合大集合

#### INTSET编码
```c
// 整数集合编码
typedef struct intset {
    uint32_t encoding;  // 编码方式
    uint32_t length;    // 集合长度
    int8_t contents[];  // 整数数组
} intset;
```

**使用条件**：
- 集合只包含整数
- 集合元素较少时

**优势**：
- 内存占用小
- 查找效率高
- 支持整数升级

### 5. 有序集合对象（OBJ_ZSET）

有序集合对象支持两种编码方式：

#### SKIPLIST编码
```c
// 跳跃表编码
typedef struct zskiplist {
    struct zskiplistNode *header, *tail; // 头尾节点
    unsigned long length;                 // 节点数量
    int level;                           // 最大层数
} zskiplist;

typedef struct zskiplistNode {
    robj *obj;                           // 成员对象
    double score;                        // 分值
    struct zskiplistNode *backward;      // 后退指针
    struct zskiplistLevel {
        struct zskiplistNode *forward;   // 前进指针
        unsigned int span;               // 跨度
    } level[];                          // 层
} zskiplistNode;
```

**使用条件**：
- 有序集合元素较多时
- 需要范围查询操作

**优势**：
- 支持范围查询
- 查找效率高，O(log n)
- 支持按分值排序

#### ZIPLIST编码
```c
// 压缩列表编码
// 使用压缩列表存储成员和分值
```

**使用条件**：
- 有序集合元素较少时
- 成员和分值大小相对固定

**优势**：
- 内存紧凑
- 适合小有序集合
- 缓存友好

## 编码选择策略

### 1. 字符串对象编码选择

```c
// 字符串对象编码选择逻辑
robj *createStringObject(const char *ptr, size_t len) {
    if (len <= 44) {
        // 使用EMBSTR编码
        return createEmbeddedStringObject(ptr, len);
    } else {
        // 使用RAW编码
        return createRawStringObject(ptr, len);
    }
}

// 尝试转换为整数编码
void tryObjectEncoding(robj *o) {
    long value;
    sds s = o->ptr;
    size_t len;
    
    if (o->type == OBJ_STRING && o->encoding == OBJ_ENCODING_RAW) {
        if (string2l(s, sdslen(s), &value)) {
            o->encoding = OBJ_ENCODING_INT;
            o->ptr = (void*) value;
            sdsfree(s);
        }
    }
}
```

### 2. 列表对象编码选择

```c
// 列表对象编码选择逻辑
robj *createListObject(void) {
    robj *o = createObject(OBJ_LIST, NULL);
    o->encoding = OBJ_ENCODING_QUICKLIST; // 默认使用快速列表
    o->ptr = quicklistCreate();
    return o;
}

// 编码转换触发条件
void listTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_ZIPLIST &&
        sdsEncodedObject(value) &&
        sdslen(value->ptr) > server.list_max_ziplist_value) {
        // 转换为QUICKLIST编码
        listTypeConvert(subject, OBJ_ENCODING_QUICKLIST);
    }
}
```

### 3. 哈希对象编码选择

```c
// 哈希对象编码选择逻辑
robj *createHashObject(void) {
    robj *o = createObject(OBJ_HASH, NULL);
    o->encoding = OBJ_ENCODING_ZIPLIST; // 默认使用压缩列表
    o->ptr = ziplistNew();
    return o;
}

// 编码转换触发条件
void hashTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_ZIPLIST &&
        sdsEncodedObject(value) &&
        sdslen(value->ptr) > server.hash_max_ziplist_value) {
        // 转换为HT编码
        hashTypeConvert(subject, OBJ_ENCODING_HT);
    }
}
```

### 4. 集合对象编码选择

```c
// 集合对象编码选择逻辑
robj *createSetObject(void) {
    robj *o = createObject(OBJ_SET, NULL);
    o->encoding = OBJ_ENCODING_INTSET; // 默认使用整数集合
    o->ptr = intsetNew();
    return o;
}

// 编码转换触发条件
void setTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_INTSET &&
        !isSdsRepresentableAsLongLong(value, NULL)) {
        // 转换为HT编码
        setTypeConvert(subject, OBJ_ENCODING_HT);
    }
}
```

### 5. 有序集合对象编码选择

```c
// 有序集合对象编码选择逻辑
robj *createZsetObject(void) {
    robj *o = createObject(OBJ_ZSET, NULL);
    o->encoding = OBJ_ENCODING_ZIPLIST; // 默认使用压缩列表
    o->ptr = ziplistNew();
    return o;
}

// 编码转换触发条件
void zsetTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_ZIPLIST &&
        sdsEncodedObject(value) &&
        sdslen(value->ptr) > server.zset_max_ziplist_value) {
        // 转换为SKIPLIST编码
        zsetTypeConvert(subject, OBJ_ENCODING_SKIPLIST);
    }
}
```

## 编码转换机制

### 1. 编码升级策略

Redis根据数据特征自动进行编码升级：

```c
// 字符串对象编码升级
void tryObjectEncoding(robj *o) {
    long value;
    sds s = o->ptr;
    size_t len;
    
    // RAW -> INT 转换
    if (o->type == OBJ_STRING && o->encoding == OBJ_ENCODING_RAW) {
        if (string2l(s, sdslen(s), &value)) {
            o->encoding = OBJ_ENCODING_INT;
            o->ptr = (void*) value;
            sdsfree(s);
        }
    }
}

// 列表对象编码升级
void listTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_ZIPLIST &&
        sdsEncodedObject(value) &&
        sdslen(value->ptr) > server.list_max_ziplist_value) {
        listTypeConvert(subject, OBJ_ENCODING_QUICKLIST);
    }
}
```

### 2. 编码降级策略

在某些情况下，Redis也会进行编码降级：

```c
// 集合对象编码降级
void setTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_HT &&
        isSdsRepresentableAsLongLong(value, NULL) &&
        intsetLen(subject->ptr) < server.set_max_intset_entries) {
        // HT -> INTSET 转换
        setTypeConvert(subject, OBJ_ENCODING_INTSET);
    }
}
```

### 3. 编码转换触发条件

| 对象类型 | 编码转换 | 触发条件 |
|----------|----------|----------|
| 字符串 | RAW → INT | 字符串可转换为整数 |
| 字符串 | EMBSTR → RAW | 字符串长度 > 44字节 |
| 列表 | ZIPLIST → QUICKLIST | 元素大小超过限制 |
| 哈希 | ZIPLIST → HT | 元素数量或大小超过限制 |
| 集合 | INTSET → HT | 包含非整数元素或元素过多 |
| 有序集合 | ZIPLIST → SKIPLIST | 元素数量或大小超过限制 |

## 内存优化机制

### 1. 内存使用对比

| 编码方式 | 内存效率 | 适用场景 |
|----------|----------|----------|
| EMBSTR | 最高 | 短字符串 |
| INT | 最高 | 整数字符串 |
| ZIPLIST | 高 | 小列表/哈希/有序集合 |
| INTSET | 高 | 小整数集合 |
| QUICKLIST | 中 | 大列表 |
| HT | 中 | 大哈希/集合 |
| SKIPLIST | 中 | 大有序集合 |
| RAW | 中 | 长字符串 |

### 2. 内存优化策略

```c
// 内存优化配置参数
struct redisServer {
    // 列表编码转换阈值
    size_t list_max_ziplist_value;
    size_t list_max_ziplist_entries;
    
    // 哈希编码转换阈值
    size_t hash_max_ziplist_value;
    size_t hash_max_ziplist_entries;
    
    // 集合编码转换阈值
    size_t set_max_intset_entries;
    
    // 有序集合编码转换阈值
    size_t zset_max_ziplist_value;
    size_t zset_max_ziplist_entries;
};
```

### 3. 性能考虑

```c
// 操作复杂度对比
struct operation_complexity {
    // 字符串操作
    struct {
        int get;      // O(1)
        int set;      // O(1)
        int append;   // O(1)
        int incr;     // O(1)
    } string;
    
    // 列表操作
    struct {
        int push;     // O(1)
        int pop;      // O(1)
        int index;    // O(n) ZIPLIST, O(log n) QUICKLIST
        int range;    // O(n)
    } list;
    
    // 哈希操作
    struct {
        int get;      // O(1) HT, O(n) ZIPLIST
        int set;      // O(1) HT, O(n) ZIPLIST
        int exists;   // O(1) HT, O(n) ZIPLIST
    } hash;
    
    // 集合操作
    struct {
        int add;      // O(1) HT, O(log n) INTSET
        int remove;   // O(1) HT, O(log n) INTSET
        int exists;   // O(1) HT, O(log n) INTSET
    } set;
    
    // 有序集合操作
    struct {
        int add;      // O(log n) SKIPLIST, O(n) ZIPLIST
        int remove;   // O(log n) SKIPLIST, O(n) ZIPLIST
        int score;    // O(log n) SKIPLIST, O(n) ZIPLIST
        int range;    // O(log n + m) SKIPLIST, O(n) ZIPLIST
    } zset;
};
```

## 编码方式对操作复杂度的影响

### 1. 查找操作复杂度

| 对象类型 | 编码方式 | 查找复杂度 | 适用场景 |
|----------|----------|------------|----------|
| 字符串 | 所有编码 | O(1) | 所有场景 |
| 列表 | ZIPLIST | O(n) | 小列表 |
| 列表 | QUICKLIST | O(log n) | 大列表 |
| 哈希 | ZIPLIST | O(n) | 小哈希 |
| 哈希 | HT | O(1) | 大哈希 |
| 集合 | INTSET | O(log n) | 小整数集合 |
| 集合 | HT | O(1) | 大集合 |
| 有序集合 | ZIPLIST | O(n) | 小有序集合 |
| 有序集合 | SKIPLIST | O(log n) | 大有序集合 |

### 2. 插入操作复杂度

| 对象类型 | 编码方式 | 插入复杂度 | 适用场景 |
|----------|----------|------------|----------|
| 字符串 | 所有编码 | O(1) | 所有场景 |
| 列表 | ZIPLIST | O(n) | 小列表 |
| 列表 | QUICKLIST | O(1) | 大列表 |
| 哈希 | ZIPLIST | O(n) | 小哈希 |
| 哈希 | HT | O(1) | 大哈希 |
| 集合 | INTSET | O(log n) | 小整数集合 |
| 集合 | HT | O(1) | 大集合 |
| 有序集合 | ZIPLIST | O(n) | 小有序集合 |
| 有序集合 | SKIPLIST | O(log n) | 大有序集合 |

### 3. 范围查询复杂度

| 对象类型 | 编码方式 | 范围查询复杂度 | 适用场景 |
|----------|----------|----------------|----------|
| 列表 | ZIPLIST | O(n) | 小列表 |
| 列表 | QUICKLIST | O(n) | 大列表 |
| 哈希 | 所有编码 | O(n) | 所有场景 |
| 集合 | 所有编码 | O(n) | 所有场景 |
| 有序集合 | ZIPLIST | O(n) | 小有序集合 |
| 有序集合 | SKIPLIST | O(log n + m) | 大有序集合 |

## 实际应用中的编码选择

### 1. 缓存场景

```c
// 缓存场景的编码选择
void cacheOptimization() {
    // 短字符串使用EMBSTR
    redisCommand("SET", "key1", "short_value");
    
    // 整数值使用INT编码
    redisCommand("SET", "counter", "123");
    
    // 小列表使用ZIPLIST
    redisCommand("LPUSH", "small_list", "item1", "item2", "item3");
    
    // 小哈希使用ZIPLIST
    redisCommand("HSET", "user:1", "name", "John", "age", "25");
}
```

### 2. 计数器场景

```c
// 计数器场景的编码选择
void counterOptimization() {
    // 使用INT编码的字符串
    redisCommand("INCR", "page_views");
    redisCommand("INCRBY", "user_count", "100");
    
    // 使用INTSET编码的集合
    redisCommand("SADD", "active_users", "1", "2", "3", "4", "5");
}
```

### 3. 排行榜场景

```c
// 排行榜场景的编码选择
void leaderboardOptimization() {
    // 小排行榜使用ZIPLIST
    redisCommand("ZADD", "small_leaderboard", "100", "user1", "90", "user2");
    
    // 大排行榜使用SKIPLIST
    redisCommand("ZADD", "large_leaderboard", "1000", "user1000", "999", "user999");
}
```

## Redis对象与编码对应关系关联的其它知识

### 1. 内存管理
- [Redis内存管理](../E01-Redis内存管理.md)
- [Redis对象机制详解](../B04-Redis对象机制详解.md)

### 2. 底层数据结构
- [Redis底层数据结构详解](../B05-Redis底层数据结构详解.md)
- [数据结构基础](../../500-基础理论/数据结构/)

### 3. 性能优化
- [Redis性能优化](../D02-Redis性能优化.md)
- [高并发系统设计](../F03-高并发系统设计.md)

### 4. 源码分析
- [Redis源码分析](../E05-Redis源码分析.md)
- [Redis网络模型](../E02-Redis网络模型.md)

### 5. 算法复杂度
- [算法基础](../../500-基础理论/算法/)
- [动态规划算法](../../500-基础理论/算法/动态规划算法.md) 