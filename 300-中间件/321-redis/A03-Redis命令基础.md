# Redis命令基础

## 重点
- Redis通用命令的使用
- Redis连接和认证命令
- Redis服务器管理命令
- Redis客户端工具的使用

## Redis通用命令

### 1. 键值操作命令

#### 键管理命令
```bash
# 检查键是否存在
EXISTS key [key ...]

# 删除键
DEL key [key ...]

# 设置键过期时间（秒）
EXPIRE key seconds

# 查看键剩余生存时间（秒）
TTL key

# 移除键的过期时间
PERSIST key

# 重命名键
RENAME key newkey

# 返回键的类型
TYPE key
```

#### 键模式匹配
```bash
# 查找匹配模式的键
KEYS pattern

# 常用模式：
# * 匹配任意字符
# ? 匹配单个字符
# [abc] 匹配a、b、c中的任意一个

# 示例：
KEYS user:*          # 匹配所有以user:开头的键
KEYS user:1??        # 匹配user:1后跟两个字符的键
```

#### 键扫描命令
```bash
# 扫描键（推荐使用，避免阻塞）
SCAN cursor [MATCH pattern] [COUNT count]

# 示例：
SCAN 0 MATCH user:* COUNT 100
```

### 2. 数据库操作命令

```bash
# 选择数据库（0-15）
SELECT index

# 清空当前数据库
FLUSHDB

# 清空所有数据库
FLUSHALL

# 返回当前数据库的键数量
DBSIZE
```

### 3. 服务器信息命令

```bash
# 返回服务器信息
INFO [section]

# 常用section：
# server - 服务器信息
# clients - 客户端连接信息
# memory - 内存使用信息
# stats - 统计信息

# 示例：
INFO memory
INFO stats
```

## Redis连接命令

### 1. 认证命令

```bash
# 认证（设置密码后必须）
AUTH password

# 示例：
AUTH mypassword
```

### 2. 连接管理命令

```bash
# 测试连接
PING

# 关闭连接
QUIT

# 切换数据库
SELECT 0

# 返回当前连接的客户端信息
CLIENT LIST

# 设置客户端名称
CLIENT SETNAME connection-name

# 杀死指定客户端连接
CLIENT KILL [ip:port] [ID client-id]
```

## Redis服务器管理命令

### 1. 服务器控制命令

```bash
# 关闭服务器
SHUTDOWN [SAVE|NOSAVE]

# 保存数据到磁盘
SAVE

# 异步保存数据到磁盘
BGSAVE

# 返回服务器时间
TIME
```

### 2. 配置管理命令

```bash
# 获取配置参数
CONFIG GET parameter

# 设置配置参数
CONFIG SET parameter value

# 重写配置文件
CONFIG REWRITE
```

### 3. 慢查询命令

```bash
# 设置慢查询阈值（微秒）
CONFIG SET slowlog-log-slower-than 10000

# 获取慢查询日志
SLOWLOG GET [count]

# 重置慢查询日志
SLOWLOG RESET
```

## Redis客户端工具

### 1. redis-cli 基础使用

```bash
# 连接到Redis服务器
redis-cli

# 连接到指定主机和端口
redis-cli -h host -p port

# 使用密码认证
redis-cli -a password

# 执行单个命令
redis-cli SET key value

# 交互模式
redis-cli
> SET key value
> GET key
> QUIT
```

### 2. redis-cli 高级功能

```bash
# 监控模式（实时查看命令）
redis-cli MONITOR

# 统计模式（返回命令统计）
redis-cli --stat

# 延迟模式（测试延迟）
redis-cli --latency

# 扫描大键
redis-cli --bigkeys

# 内存使用分析
redis-cli --memkeys
```

## 常用命令示例

### 1. 键值操作示例

```bash
# 设置和获取值
SET user:1 "John Doe"
GET user:1

# 设置过期时间
SETEX session:123 3600 "user_data"
TTL session:123

# 批量操作
MSET user:1 "John" user:2 "Jane" user:3 "Bob"
MGET user:1 user:2 user:3

# 原子递增
INCR counter
INCRBY counter 10
```

### 2. 数据库操作示例

```bash
# 选择数据库
SELECT 1

# 检查数据库大小
DBSIZE

# 清空当前数据库
FLUSHDB

# 扫描键（推荐）
SCAN 0 COUNT 100
```

### 3. 服务器管理示例

```bash
# 检查服务器状态
PING

# 获取服务器信息
INFO server
INFO memory
INFO stats

# 查看客户端连接
CLIENT LIST

# 监控命令执行
MONITOR
```

## 性能优化命令

### 1. 内存优化

```bash
# 查看内存使用
INFO memory

# 查看内存使用详情
MEMORY USAGE key

# 查看内存统计
MEMORY STATS
```

### 2. 性能分析

```bash
# 查看命令统计
INFO stats

# 查看命令执行时间
SLOWLOG GET 10

# 查看大键
redis-cli --bigkeys
```

## 安全相关命令

### 1. 访问控制

```bash
# 设置密码
CONFIG SET requirepass "mypassword"

# 认证
AUTH mypassword
```

### 2. 命令禁用

```bash
# 禁用危险命令
CONFIG SET rename-command FLUSHDB ""
CONFIG SET rename-command FLUSHALL ""
CONFIG SET rename-command KEYS ""
```

## 监控和调试命令

### 1. 实时监控

```bash
# 监控所有命令
MONITOR

# 监控指定模式
redis-cli MONITOR | grep "SET"

# 统计命令执行
redis-cli --stat
```

### 2. 性能分析

```bash
# 测试延迟
redis-cli --latency

# 测试延迟分布
redis-cli --latency-dist

# 测试吞吐量
redis-benchmark -h localhost -p 6379
```

### 3. 调试工具

```bash
# 查看键类型
TYPE key

# 查看键编码
OBJECT ENCODING key

# 查看键引用计数
OBJECT REFCOUNT key
```

## 常见问题解决

### 1. 连接问题

```bash
# 检查连接
redis-cli PING

# 检查端口
netstat -tlnp | grep 6379
```

### 2. 性能问题

```bash
# 查看慢查询
SLOWLOG GET 10

# 查看内存使用
INFO memory

# 查看连接数
INFO clients
```

### 3. 内存问题

```bash
# 查看大键
redis-cli --bigkeys

# 查看内存使用
MEMORY USAGE key
```

## Redis关联的其它知识

### 相关技术栈
- **Redis客户端**：Jedis、Lettuce、redis-py等
- **监控工具**：RedisInsight、Redis Commander
- **性能测试**：redis-benchmark、memtier_benchmark
- **集群管理**：Redis Cluster、Redis Sentinel

### 最佳实践
1. **使用SCAN代替KEYS**：避免阻塞
2. **合理使用管道**：减少网络往返
3. **监控慢查询**：及时发现问题
4. **定期清理过期键**：避免内存泄漏
5. **使用连接池**：提高性能 