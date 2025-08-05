# Redis对象机制详解

## 重点
- Redis对象结构(redisObject)的设计原理和核心字段
- Redis的5种对象类型和8种编码方式
- 对象引用计数机制和内存回收策略
- 对象共享机制和内存优化技术
- 对象系统的设计思想和性能考虑

## Redis对象机制概念或介绍

Redis的对象系统是其核心设计之一，所有数据类型在Redis内部都被封装为对象。这种设计提供了统一的对象接口，同时支持多种编码方式以优化不同场景下的内存使用和性能。

Redis对象系统的主要特点：
1. **统一接口**：所有数据类型都通过redisObject结构体表示
2. **多编码支持**：每种对象类型支持多种底层编码
3. **引用计数**：支持对象共享和自动内存回收
4. **类型安全**：运行时类型检查和错误处理
5. **内存优化**：根据数据特征自动选择最优编码

## Redis对象结构设计

### redisObject核心结构

```c
// Redis对象结构体（简化版）
typedef struct redisObject {
    unsigned type:4;        // 对象类型（4位）
    unsigned encoding:4;    // 编码方式（4位）
    unsigned lru:LRU_BITS; // LRU信息或LFU信息
    int refcount;          // 引用计数
    void *ptr;             // 指向实际数据的指针
} robj;
```

### 对象类型定义

```c
// 对象类型枚举
#define OBJ_STRING 0    // 字符串对象
#define OBJ_LIST 1      // 列表对象
#define OBJ_SET 2       // 集合对象
#define OBJ_ZSET 3      // 有序集合对象
#define OBJ_HASH 4      // 哈希对象
#define OBJ_MODULE 5    // 模块对象
#define OBJ_STREAM 6    // 流对象
```

### 编码方式定义

```c
// 编码方式枚举
#define OBJ_ENCODING_RAW 0        // 原始字符串编码
#define OBJ_ENCODING_INT 1        // 整数编码
#define OBJ_ENCODING_HT 2         // 哈希表编码
#define OBJ_ENCODING_ZIPMAP 3     // 压缩映射编码（已废弃）
#define OBJ_ENCODING_LINKEDLIST 4 // 链表编码
#define OBJ_ENCODING_ZIPLIST 5    // 压缩列表编码
#define OBJ_ENCODING_INTSET 6     // 整数集合编码
#define OBJ_ENCODING_SKIPLIST 7   // 跳跃表编码
#define OBJ_ENCODING_EMBSTR 8     // 嵌入式字符串编码
#define OBJ_ENCODING_QUICKLIST 9  // 快速列表编码
#define OBJ_ENCODING_STREAM 10    // 流编码
```

## 对象类型详解

### 1. 字符串对象（OBJ_STRING）

字符串对象支持三种编码方式：

#### EMBSTR编码
```c
// 嵌入式字符串结构
typedef struct {
    uint32_t len;     // 字符串长度
    uint8_t alloc;    // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];       // 字符串内容
} embstr;
```

**使用条件**：字符串长度 ≤ 44字节
**优势**：内存分配一次，减少内存碎片

#### RAW编码
```c
// 原始字符串结构
typedef struct {
    uint32_t len;     // 字符串长度
    uint32_t alloc;   // 分配的空间大小
    unsigned char flags; // 标志位
    char buf[];       // 字符串内容
} sds;
```

**使用条件**：字符串长度 > 44字节
**优势**：支持动态扩容

#### INT编码
```c
// 整数编码（直接存储在ptr中）
typedef struct redisObject {
    unsigned type:4;
    unsigned encoding:4;
    unsigned lru:LRU_BITS;
    int refcount;
    long long ptr;    // 直接存储整数值
} robj;
```

**使用条件**：字符串可以表示为长整型
**优势**：内存占用最小

### 2. 列表对象（OBJ_LIST）

列表对象支持两种编码方式：

#### QUICKLIST编码
```c
// 快速列表结构
typedef struct quicklist {
    quicklistNode *head;     // 头节点
    quicklistNode *tail;     // 尾节点
    unsigned long count;      // 总节点数
    unsigned long len;        // 节点数量
    int fill : 16;           // 每个节点的最大大小
    unsigned int compress : 16; // 压缩深度
} quicklist;

typedef struct quicklistNode {
    struct quicklistNode *prev;
    struct quicklistNode *next;
    unsigned char *zl;        // 指向ziplist的指针
    unsigned int sz;          // ziplist的大小
    unsigned int count : 16;  // ziplist中的条目数
    unsigned int encoding : 2; // 编码方式
    unsigned int container : 2; // 容器类型
    unsigned int recompress : 1; // 是否重新压缩
    unsigned int attempted_compress : 1; // 是否尝试压缩
    unsigned int extra : 10;  // 额外信息
} quicklistNode;
```

**使用条件**：默认编码方式
**优势**：结合了链表和压缩列表的优点

#### ZIPLIST编码
```c
// 压缩列表结构
typedef struct zlentry {
    unsigned int prevrawlensize; // 前一个节点长度字段的大小
    unsigned int prevrawlen;     // 前一个节点的长度
    unsigned int lensize;        // 当前节点长度字段的大小
    unsigned int len;            // 当前节点的长度
    unsigned int headersize;     // 头部大小
    unsigned char encoding;      // 编码方式
    unsigned char *p;           // 指向当前节点的指针
} zlentry;
```

**使用条件**：列表元素较少且较小时
**优势**：内存紧凑，减少内存碎片

### 3. 哈希对象（OBJ_HASH）

哈希对象支持两种编码方式：

#### HT编码（哈希表）
```c
// 哈希表结构
typedef struct dict {
    dictType *type;        // 类型特定函数
    void *privdata;        // 私有数据
    dictht ht[2];          // 哈希表数组
    long rehashidx;        // 重哈希索引
    unsigned long iterators; // 迭代器数量
} dict;

typedef struct dictht {
    dictEntry **table;     // 哈希表数组
    unsigned long size;    // 哈希表大小
    unsigned long sizemask; // 大小掩码
    unsigned long used;    // 已使用节点数
} dictht;
```

**使用条件**：哈希表元素较多或较大时
**优势**：查找效率高，支持动态扩容

#### ZIPLIST编码
```c
// 压缩列表编码（与列表相同）
```

**使用条件**：哈希表元素较少且较小时
**优势**：内存紧凑，适合小哈希表

### 4. 集合对象（OBJ_SET）

集合对象支持两种编码方式：

#### HT编码（哈希表）
```c
// 使用哈希表实现集合
typedef struct dict {
    // 与哈希对象相同的结构
} dict;
```

**使用条件**：集合元素较多时
**优势**：查找效率高

#### INTSET编码
```c
// 整数集合结构
typedef struct intset {
    uint32_t encoding;     // 编码方式
    uint32_t length;       // 集合长度
    int8_t contents[];     // 整数数组
} intset;
```

**使用条件**：集合只包含整数且元素较少时
**优势**：内存占用小，查找效率高

### 5. 有序集合对象（OBJ_ZSET）

有序集合对象支持两种编码方式：

#### SKIPLIST编码
```c
// 跳跃表结构
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

**使用条件**：有序集合元素较多时
**优势**：支持范围查询，查找效率高

#### ZIPLIST编码
```c
// 压缩列表编码
```

**使用条件**：有序集合元素较少时
**优势**：内存紧凑

## 对象编码转换机制

### 编码升级策略

Redis根据数据特征自动选择最优编码，并在需要时进行编码转换：

```c
// 字符串对象编码转换示例
void tryObjectEncoding(robj *o) {
    long value;
    sds s = o->ptr;
    size_t len;
    
    // 尝试转换为整数编码
    if (o->type == OBJ_STRING && o->encoding == OBJ_ENCODING_RAW) {
        if (string2l(s, sdslen(s), &value)) {
            o->encoding = OBJ_ENCODING_INT;
            o->ptr = (void*) value;
            sdsfree(s);
        }
    }
}

// 列表对象编码转换示例
void listTypeTryConversion(robj *subject, robj *value) {
    if (subject->encoding == OBJ_ENCODING_ZIPLIST &&
        sdsEncodedObject(value) &&
        sdslen(value->ptr) > server.list_max_ziplist_value) {
        // 转换为QUICKLIST编码
        listTypeConvert(subject, OBJ_ENCODING_QUICKLIST);
    }
}
```

### 编码选择策略

```c
// 哈希对象编码选择
robj *createHashObject(void) {
    robj *o = createObject(OBJ_HASH, NULL);
    o->encoding = OBJ_ENCODING_ZIPLIST; // 默认使用压缩列表
    o->ptr = ziplistNew();
    return o;
}

// 集合对象编码选择
robj *createSetObject(void) {
    robj *o = createObject(OBJ_SET, NULL);
    o->encoding = OBJ_ENCODING_INTSET; // 默认使用整数集合
    o->ptr = intsetNew();
    return o;
}
```

## 对象引用计数机制

### 引用计数操作

```c
// 增加引用计数
void incrRefCount(robj *o) {
    if (o->refcount != OBJ_SHARED_REFCOUNT) {
        o->refcount++;
    }
}

// 减少引用计数
void decrRefCount(robj *o) {
    if (o->refcount == 1) {
        // 引用计数为1，释放对象
        freeStringObject(o);
    } else if (o->refcount != OBJ_SHARED_REFCOUNT) {
        o->refcount--;
    }
}

// 创建共享对象
robj *createSharedString(const char *str) {
    robj *o = createObject(OBJ_STRING, sdsnew(str));
    o->refcount = OBJ_SHARED_REFCOUNT;
    return o;
}
```

### 对象共享机制

Redis使用对象共享来减少内存使用：

```c
// 共享对象池
static robj *shared;
static robj *shared_integers[OBJ_SHARED_INTEGERS];

// 初始化共享对象
void createSharedObjects(void) {
    int j;
    
    // 创建共享字符串
    shared.crlf = createObject(OBJ_STRING, sdsnew("\r\n"));
    shared.ok = createObject(OBJ_STRING, sdsnew("+OK\r\n"));
    shared.emptybulk = createObject(OBJ_STRING, sdsnew("$0\r\n\r\n"));
    shared.czero = createObject(OBJ_STRING, sdsnew(":0\r\n"));
    shared.cone = createObject(OBJ_STRING, sdsnew(":1\r\n"));
    shared.ctwo = createObject(OBJ_STRING, sdsnew(":2\r\n"));
    
    // 设置引用计数为共享
    shared.crlf->refcount = OBJ_SHARED_REFCOUNT;
    shared.ok->refcount = OBJ_SHARED_REFCOUNT;
    shared.emptybulk->refcount = OBJ_SHARED_REFCOUNT;
    shared.czero->refcount = OBJ_SHARED_REFCOUNT;
    shared.cone->refcount = OBJ_SHARED_REFCOUNT;
    shared.ctwo->refcount = OBJ_SHARED_REFCOUNT;
    
    // 创建共享整数对象
    for (j = 0; j < OBJ_SHARED_INTEGERS; j++) {
        shared_integers[j] = makeObjectShared(createStringObjectFromLongLong(j));
    }
}
``` 