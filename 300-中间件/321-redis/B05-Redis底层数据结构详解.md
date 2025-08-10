# Redis底层数据结构详解

## 重点
- Redis底层数据结构的实现原理和设计思想
- 简单动态字符串(SDS)的内存布局和扩容机制
- 字典的哈希表实现和渐进式rehash机制
- 跳跃表的数据结构和查找算法
- 整数集合的升级机制和内存优化
- 压缩列表的紧凑存储和编码方式
- 各种数据结构的时间复杂度和空间复杂度分析

## Redis底层数据结构概念或介绍

Redis的底层数据结构是其高性能的基础，每种数据类型都基于特定的底层数据结构实现。Redis的底层数据结构包括：简单动态字符串(SDS)、链表、字典、跳跃表、整数集合、压缩列表等。这些数据结构经过精心设计，在保证功能完整性的同时，最大化内存使用效率和操作性能。

Redis底层数据结构的设计原则：
1. **内存效率**：尽可能减少内存占用
2. **操作效率**：支持高效的增删改查操作
3. **灵活性**：支持动态扩容和收缩
4. **兼容性**：与上层数据类型无缝集成

## 简单动态字符串(SDS)

### SDS结构设计

```c
// SDS结构体（Redis 3.2版本）
struct __attribute__ ((__packed__)) sdshdr8 {
    uint8_t len;        // 字符串长度
    uint8_t alloc;      // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];         // 字符串内容
};

struct __attribute__ ((__packed__)) sdshdr16 {
    uint16_t len;       // 字符串长度
    uint16_t alloc;     // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];         // 字符串内容
};

struct __attribute__ ((__packed__)) sdshdr32 {
    uint32_t len;       // 字符串长度
    uint32_t alloc;     // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];         // 字符串内容
};

struct __attribute__ ((__packed__)) sdshdr64 {
    uint64_t len;       // 字符串长度
    uint64_t alloc;     // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];         // 字符串内容
};
```

### SDS的优势

**1. 常数时间复杂度获取长度**
```c
// 获取字符串长度，O(1)时间复杂度
static inline size_t sdslen(const sds s) {
    unsigned char flags = s[-1];
    switch(flags&SDS_TYPE_MASK) {
        case SDS_TYPE_8:
            return SDS_HDR(8,s)->len;
        case SDS_TYPE_16:
            return SDS_HDR(16,s)->len;
        case SDS_TYPE_32:
            return SDS_HDR(32,s)->len;
        case SDS_TYPE_64:
            return SDS_HDR(64,s)->len;
    }
    return 0;
}
```

**2. 杜绝缓冲区溢出**
```c
// SDS在修改前会检查空间是否足够
sds sdsMakeRoomFor(sds s, size_t addlen) {
    void *sh, *newsh;
    size_t avail = sdsavail(s);
    size_t len, newlen;
    char type, oldtype = s[-1] & SDS_TYPE_MASK;
    int hdrlen;

    if (avail >= addlen) return s;  // 空间足够，直接返回

    len = sdslen(s);
    sh = (char*)s-sdsHdrSize(oldtype);
    newlen = (len+addlen);
    if (newlen < SDS_MAX_PREALLOC)
        newlen *= 2;
    else
        newlen += SDS_MAX_PREALLOC;
    // ... 扩容逻辑
}
```

**3. 减少内存重分配次数**
```c
// 预分配策略
#define SDS_MAX_PREALLOC (1024*1024)  // 1MB

// 扩容策略：
// 1. 如果新长度小于1MB，则新空间为新长度的2倍
// 2. 如果新长度大于等于1MB，则新空间为新长度+1MB
```

### SDS的内存布局

```
内存布局示例（sdshdr8）：
+--------+--------+--------+------------------+
|  len   | alloc  | flags  |      buf[]       |
|  (1B)  |  (1B)  |  (1B)  |   (实际内容)     |
+--------+--------+--------+------------------+
```

## 链表

### 链表结构设计

```c
// 链表节点
typedef struct listNode {
    struct listNode *prev;  // 前驱节点
    struct listNode *next;  // 后继节点
    void *value;           // 节点值
} listNode;

// 链表结构
typedef struct list {
    listNode *head;        // 头节点
    listNode *tail;        // 尾节点
    void *(*dup)(void *ptr);     // 复制函数
    void (*free)(void *ptr);     // 释放函数
    int (*match)(void *ptr, void *key); // 比较函数
    unsigned long len;     // 链表长度
} list;
```

### 链表操作示例

```c
// 创建新节点
listNode *listCreateNode(void *value) {
    listNode *node = zmalloc(sizeof(*node));
    if (node == NULL) return NULL;
    node->value = value;
    return node;
}

// 在链表头部插入节点
list *listAddNodeHead(list *list, void *value) {
    listNode *node;
    
    if ((node = zmalloc(sizeof(*node))) == NULL)
        return NULL;
    node->value = value;
    if (list->len == 0) {
        list->head = list->tail = node;
        node->prev = node->next = NULL;
    } else {
        node->prev = NULL;
        node->next = list->head;
        list->head->prev = node;
        list->head = node;
    }
    list->len++;
    return list;
}
```

### 链表的特点

1. **双向链表**：支持从两端快速访问
2. **无环链表**：头节点的prev和尾节点的next都为NULL
3. **带长度计数器**：O(1)时间复杂度获取长度
4. **多态**：通过void*指针支持不同类型的值

## 字典

### 字典结构设计

```c
// 字典结构
typedef struct dict {
    dictType *type;        // 类型特定函数
    void *privdata;        // 私有数据
    dictht ht[2];         // 哈希表数组
    long rehashidx;        // rehash索引
    unsigned long iterators; // 迭代器数量
} dict;

// 哈希表结构
typedef struct dictht {
    dictEntry **table;     // 哈希表数组
    unsigned long size;    // 哈希表大小
    unsigned long sizemask; // 大小掩码
    unsigned long used;    // 已使用节点数量
} dictht;

// 哈希表节点
typedef struct dictEntry {
    void *key;             // 键
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v;                   // 值
    struct dictEntry *next; // 指向下一个节点
} dictEntry;
```

### 哈希算法

```c
// MurmurHash2算法
unsigned int dictGenHashFunction(const void *key, int len) {
    // MurmurHash2实现
    const unsigned int m = 0x5bd1e995;
    const int r = 24;
    unsigned int h = seed ^ len;
    const unsigned char *data = (const unsigned char *)key;
    
    while(len >= 4) {
        unsigned int k = *(unsigned int*)data;
        k *= m;
        k ^= k >> r;
        k *= m;
        h *= m;
        h ^= k;
        data += 4;
        len -= 4;
    }
    
    switch(len) {
        case 3: h ^= data[2] << 16;
        case 2: h ^= data[1] << 8;
        case 1: h ^= data[0];
                h *= m;
    };
    
    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;
    
    return (unsigned int)h;
}
```

### 渐进式Rehash

```c
// 渐进式rehash的核心逻辑
int dictRehash(dict *d, int n) {
    int empty_visits = n*10; // 最大空桶访问次数
    
    if (!dictIsRehashing(d)) return 0;
    
    while(n-- && d->ht[0].used != 0) {
        dictEntry *de, *nextde;
        
        // 确保rehashidx不越界
        assert(d->ht[0].size > (unsigned long)d->rehashidx);
        
        while(d->ht[0].table[d->rehashidx] == NULL) {
            d->rehashidx++;
            if (--empty_visits == 0) return 1;
        }
        
        de = d->ht[0].table[d->rehashidx];
        // 将整个链表迁移到新表
        while(de) {
            unsigned int h;
            nextde = de->next;
            
            // 计算在新表中的索引
            h = dictHashKey(d, de->key) & d->ht[1].sizemask;
            de->next = d->ht[1].table[h];
            d->ht[1].table[h] = de;
            d->ht[0].used--;
            d->ht[1].used++;
            de = nextde;
        }
        d->ht[0].table[d->rehashidx] = NULL;
        d->rehashidx++;
    }
    
    // 检查是否完成rehash
    if (d->ht[0].used == 0) {
        zfree(d->ht[0].table);
        d->ht[0] = d->ht[1];
        _dictReset(&d->ht[1]);
        d->rehashidx = -1;
        return 0;
    }
    
    return 1;
}
```

## 跳跃表

### 跳跃表结构设计

```c
// 跳跃表节点
typedef struct zskiplistNode {
    robj *obj;                    // 成员对象
    double score;                 // 分值
    struct zskiplistNode *backward; // 后退指针
    struct zskiplistLevel {
        struct zskiplistNode *forward; // 前进指针
        unsigned int span;             // 跨度
    } level[];                        // 层
} zskiplistNode;

// 跳跃表结构
typedef struct zskiplist {
    struct zskiplistNode *header, *tail; // 头节点和尾节点
    unsigned long length;                 // 节点数量
    int level;                           // 最大层数
} zskiplist;
```

### 跳跃表查找算法

```c
// 跳跃表查找实现
zskiplistNode *zslSearch(zskiplist *zsl, double score, robj *obj) {
    zskiplistNode *x;
    int i;
    
    x = zsl->header;
    for (i = zsl->level-1; i >= 0; i--) {
        while (x->level[i].forward &&
               (x->level[i].forward->score < score ||
                (x->level[i].forward->score == score &&
                 compareStringObjects(x->level[i].forward->obj,obj) < 0))) {
            x = x->level[i].forward;
        }
    }
    
    x = x->level[0].forward;
    if (x && score == x->score &&
        equalStringObjects(x->obj,obj)) {
        return x;
    }
    return NULL;
}
```

### 跳跃表插入算法

```c
// 跳跃表插入实现
zskiplistNode *zslInsert(zskiplist *zsl, double score, robj *obj) {
    zskiplistNode *update[ZSKIPLIST_MAXLEVEL], *x;
    unsigned int rank[ZSKIPLIST_MAXLEVEL];
    int i, level;
    
    x = zsl->header;
    for (i = zsl->level-1; i >= 0; i--) {
        rank[i] = i == (zsl->level-1) ? 0 : rank[i+1];
        while (x->level[i].forward &&
               (x->level[i].forward->score < score ||
                (x->level[i].forward->score == score &&
                 compareStringObjects(x->level[i].forward->obj,obj) < 0))) {
            rank[i] += x->level[i].span;
            x = x->level[i].forward;
        }
        update[i] = x;
    }
    
    level = zslRandomLevel();
    if (level > zsl->level) {
        for (i = zsl->level; i < level; i++) {
            rank[i] = 0;
            update[i] = zsl->header;
            update[i]->level[i].span = zsl->length;
        }
        zsl->level = level;
    }
    
    x = zslCreateNode(level,score,obj);
    for (i = 0; i < level; i++) {
        x->level[i].forward = update[i]->level[i].forward;
        update[i]->level[i].forward = x;
        
        x->level[i].span = update[i]->level[i].span - (rank[0] - rank[i]);
        update[i]->level[i].span = (rank[0] - rank[i]) + 1;
    }
    
    for (i = level; i < zsl->level; i++) {
        update[i]->level[i].span++;
    }
    
    x->backward = (update[0] == zsl->header) ? NULL : update[0];
    if (x->level[0].forward)
        x->level[0].forward->backward = x;
    else
        zsl->tail = x;
    zsl->length++;
    return x;
}
```

## 整数集合

### 整数集合结构设计

```c
// 整数集合结构
typedef struct intset {
    uint32_t encoding;  // 编码方式
    uint32_t length;    // 集合长度
    int8_t contents[];  // 保存元素的数组
} intset;

// 编码方式
#define INTSET_ENC_INT16 (sizeof(int16_t))
#define INTSET_ENC_INT32 (sizeof(int32_t))
#define INTSET_ENC_INT64 (sizeof(int64_t))
```

### 整数集合升级机制

```c
// 整数集合升级实现
static intset *intsetUpgradeAndAdd(intset *is, int64_t value) {
    uint8_t curenc = intrev32ifbe(is->encoding);
    uint8_t newenc = _intsetValueEncoding(value);
    int length = intrev32ifbe(is->length);
    int prepend = value < 0 ? 1 : 0;
    
    // 设置新编码
    is->encoding = intrev32ifbe(newenc);
    is = intsetResize(is,intrev32ifbe(is->length)+1);
    
    // 从后往前重新设置元素
    while(length--)
        _intsetSet(is,length+prepend,_intsetGetEncoded(is,length,curenc));
    
    // 设置新值
    if (prepend)
        _intsetSet(is,0,value);
    else
        _intsetSet(is,intrev32ifbe(is->length),value);
    is->length = intrev32ifbe(intrev32ifbe(is->length)+1);
    return is;
}
```

### 整数集合查找算法

```c
// 整数集合二分查找
static uint8_t intsetSearch(intset *is, int64_t value, uint32_t *pos) {
    int min = 0, max = intrev32ifbe(is->length)-1, mid = -1;
    int64_t cur = -1;
    
    if (intrev32ifbe(is->length) == 0) {
        if (pos) *pos = 0;
        return 0;
    } else {
        if (value > _intsetGet(is,max)) {
            if (pos) *pos = intrev32ifbe(is->length);
            return 0;
        } else if (value < _intsetGet(is,0)) {
            if (pos) *pos = 0;
            return 0;
        }
    }
    
    while(max >= min) {
        mid = ((unsigned int)min + (unsigned int)max) >> 1;
        cur = _intsetGet(is,mid);
        if (value > cur) {
            min = mid+1;
        } else if (value < cur) {
            max = mid-1;
        } else {
            break;
        }
    }
    
    if (value == cur) {
        if (pos) *pos = mid;
        return 1;
    } else {
        if (pos) *pos = min;
        return 0;
    }
}
```

## 压缩列表

### 压缩列表结构设计

```c
// 压缩列表结构
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

### 压缩列表编码方式

```c
// 字符串编码
#define ZIP_STR_06B (0 << 6)  // 长度小于等于63字节
#define ZIP_STR_14B (1 << 6)  // 长度小于等于16383字节
#define ZIP_STR_32B (2 << 6)  // 长度小于等于4294967295字节

// 整数编码
#define ZIP_INT_16B (0xc0 | 0<<4)  // 16位整数
#define ZIP_INT_32B (0xc0 | 1<<4)  // 32位整数
#define ZIP_INT_64B (0xc0 | 2<<4)  // 64位整数
#define ZIP_INT_24B (0xc0 | 3<<4)  // 24位整数
#define ZIP_INT_8B 0xfe             // 8位整数
```

### 压缩列表操作示例

```c
// 压缩列表查找实现
unsigned char *ziplistFind(unsigned char *p, unsigned char *vstr, unsigned int vlen, unsigned int skip) {
    int skipcnt = 0;
    unsigned char vencoding = 0;
    long long vll = 0;
    
    while (p[0] != ZIP_END) {
        struct zlentry e;
        unsigned char *q;
        
        zipEntry(p, &e);
        q = p + e.prevrawlensize + e.lensize;
        
        if (skipcnt == 0) {
            if (ZIP_IS_STR(e.encoding)) {
                if (e.len == vlen && memcmp(q, vstr, vlen) == 0) {
                    return p;
                }
            } else {
                if (vencoding == 0) {
                    if (!zipTryEncoding(vstr, vlen, &vll, &vencoding)) {
                        vencoding = UCHAR_MAX;
                    }
                }
                if (vencoding != UCHAR_MAX) {
                    long long ll = zipLoadInteger(q, e.encoding);
                    if (ll == vll) {
                        return p;
                    }
                }
            }
            skipcnt = skip;
        } else {
            skipcnt--;
        }
        p = q + e.len;
    }
    return NULL;
}
```

## 数据结构性能对比

### 时间复杂度对比

| 操作 | SDS | 链表 | 字典 | 跳跃表 | 整数集合 | 压缩列表 |
|------|-----|------|------|--------|----------|----------|
| 查找 | O(n) | O(n) | O(1) | O(log n) | O(log n) | O(n) |
| 插入 | O(1) | O(1) | O(1) | O(log n) | O(n) | O(n) |
| 删除 | O(1) | O(1) | O(1) | O(log n) | O(n) | O(n) |
| 范围查询 | O(n) | O(n) | O(n) | O(log n) | O(n) | O(n) |

### 空间复杂度对比

| 数据结构 | 额外空间开销 | 内存效率 |
|----------|-------------|----------|
| SDS | 3-8字节头部 | 高 |
| 链表 | 24字节/节点 | 中 |
| 字典 | 哈希表开销 | 中 |
| 跳跃表 | 层数相关 | 中 |
| 整数集合 | 无额外开销 | 高 |
| 压缩列表 | 最小开销 | 最高 |

## 底层数据结构关联的其它知识

### 1. 内存管理
- [Redis内存管理](../E01-Redis内存管理.md)
- [Redis对象机制详解](../B04-Redis对象机制详解.md)

### 2. 算法复杂度
- [算法基础](../../500-基础理论/算法/)
- [数据结构基础](../../500-基础理论/数据结构/)

### 3. 性能优化
- [Redis性能优化](../D02-Redis性能优化.md)
- [高并发系统设计](../F03-高并发系统设计.md)

### 4. 源码分析
- [Redis源码分析](../E05-Redis源码分析.md)
- [Redis网络模型](../E02-Redis网络模型.md) 