# Redis基础数据类型详解

## 重点
- Redis的5种基础数据类型：String、List、Hash、Set、ZSet
- 每种数据类型的命令、应用场景和最佳实践
- 数据类型的内存优化和性能考虑
- 实际项目中的应用示例

## Redis基础数据类型

Redis支持5种基础数据类型，每种类型都有其特定的用途和优势。

### 1. String（字符串）

String是Redis最基本的数据类型，可以存储文本、数字或二进制数据。

#### 基本命令

```bash
# 设置值
SET key value [EX seconds] [PX milliseconds] [NX|XX]

# 获取值
GET key

# 批量设置
MSET key1 value1 key2 value2 ...

# 批量获取
MGET key1 key2 ...

# 原子递增/递减
INCR key
INCRBY key increment

# 设置过期时间
SETEX key seconds value
```

#### 应用场景

**1. 缓存**
```python
# 缓存用户信息
def cache_user_info(user_id, user_info):
    redis.setex(f"user:{user_id}", 3600, json.dumps(user_info))

def get_user_info(user_id):
    user_data = redis.get(f"user:{user_id}")
    return json.loads(user_data) if user_data else None
```

**2. 计数器**
```python
# 访问量统计
def increment_page_view(page_id):
    key = f"page_view:{page_id}"
    redis.incr(key)
    redis.expire(key, 86400)  # 24小时过期
```

### 2. List（列表）

List是一个双向链表，支持从两端添加或删除元素。

#### 基本命令

```bash
# 从左侧推入元素
LPUSH key element [element ...]

# 从右侧推入元素
RPUSH key element [element ...]

# 从左侧弹出元素
LPOP key [count]

# 从右侧弹出元素
RPOP key [count]

# 阻塞弹出
BLPOP key [key ...] timeout
BRPOP key [key ...] timeout

# 获取列表长度
LLEN key

# 获取指定范围的元素
LRANGE key start stop

# 修剪列表
LTRIM key start stop
```

#### 应用场景

**1. 消息队列**
```python
# 生产者
def send_message(queue_name, message):
    redis.lpush(queue_name, json.dumps(message))

# 消费者
def consume_message(queue_name):
    message = redis.brpop(queue_name, timeout=1)
    if message:
        return json.loads(message[1])
    return None
```

### 3. Hash（哈希表）

Hash是一个键值对集合，适合存储对象数据。

#### 基本命令

```bash
# 设置字段值
HSET key field value

# 获取字段值
HGET key field

# 批量设置字段
HMSET key field1 value1 field2 value2 ...

# 批量获取字段
HMGET key field1 field2 ...

# 获取所有字段和值
HGETALL key

# 原子递增字段值
HINCRBY key field increment
```

#### 应用场景

**1. 用户信息存储**
```python
# 存储用户信息
def store_user_info(user_id, user_info):
    key = f"user:{user_id}"
    redis.hmset(key, user_info)
    redis.expire(key, 3600)  # 1小时过期

# 获取用户信息
def get_user_info(user_id):
    key = f"user:{user_id}"
    return redis.hgetall(key)
```

### 4. Set（集合）

Set是一个无序的字符串集合，元素唯一。

#### 基本命令

```bash
# 添加元素
SADD key member [member ...]

# 移除元素
SREM key member [member ...]

# 检查元素是否存在
SISMEMBER key member

# 获取集合大小
SCARD key

# 获取所有元素
SMEMBERS key

# 集合运算
SINTER key [key ...]      # 交集
SUNION key [key ...]      # 并集
SDIFF key [key ...]       # 差集
```

#### 应用场景

**1. 标签系统**
```python
# 添加标签
def add_tags(item_id, tags):
    key = f"item_tags:{item_id}"
    redis.sadd(key, *tags)

# 获取标签
def get_tags(item_id):
    key = f"item_tags:{item_id}"
    return redis.smembers(key)
```

### 5. ZSet（有序集合）

ZSet是有序的字符串集合，每个元素都有一个分数用于排序。

#### 基本命令

```bash
# 添加元素
ZADD key score member [score member ...]

# 获取元素分数
ZSCORE key member

# 获取元素排名
ZRANK key member
ZREVRANK key member

# 获取指定范围的元素
ZRANGE key start stop [WITHSCORES]
ZREVRANGE key start stop [WITHSCORES]

# 原子递增分数
ZINCRBY key increment member
```

#### 应用场景

**1. 排行榜**
```python
# 更新用户分数
def update_user_score(user_id, score):
    redis.zadd("leaderboard", {user_id: score})

# 获取排行榜前10名
def get_top_users(limit=10):
    return redis.zrevrange("leaderboard", 0, limit-1, withscores=True)
```

## 数据类型选择指南

### 选择原则

1. **String**：简单键值对、计数器、缓存
2. **List**：队列、栈、最新动态列表
3. **Hash**：对象存储、配置信息
4. **Set**：唯一性检查、标签系统、好友关系
5. **ZSet**：排行榜、时间线、优先级队列

### 性能考虑

```bash
# String适合简单数据
SET user:1 "John Doe"

# Hash适合对象数据
HMSET user:1 name "John" age "30" email "john@example.com"

# List适合队列
LPUSH queue task1
RPOP queue

# Set适合唯一性
SADD unique_items item1

# ZSet适合排序
ZADD leaderboard 100 user1
```

## 内存优化技巧

### 1. 合理使用数据类型

```bash
# 避免使用String存储复杂对象
# 错误示例
SET user:1 '{"name":"John","age":30,"email":"john@example.com"}'

# 正确示例
HMSET user:1 name "John" age "30" email "john@example.com"
```

### 2. 使用压缩

```bash
# 启用压缩
CONFIG SET list-compress-depth 1
CONFIG SET hash-max-ziplist-entries 512
CONFIG SET hash-max-ziplist-value 64
```

### 3. 定期清理

```bash
# 设置过期时间
EXPIRE key 3600

# 使用LTRIM限制列表长度
LTRIM mylist 0 999

# 使用ZREMRANGEBYRANK清理旧数据
ZREMRANGEBYRANK timeline 0 -1000
```

## Redis关联的其它知识

### 相关技术栈
- **Redis客户端**：Jedis、Lettuce、redis-py等
- **序列化**：JSON、MessagePack、Protocol Buffers
- **缓存策略**：LRU、LFU、TTL
- **数据压缩**：LZ4、Snappy

### 最佳实践
1. **选择合适的数据类型**：根据业务需求选择
2. **合理使用过期时间**：避免内存泄漏
3. **批量操作**：减少网络往返
4. **监控内存使用**：及时发现问题
5. **定期清理**：保持数据新鲜度 