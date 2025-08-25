# Redis版本特性详解

## 本文重点

1. **版本演进历程**：了解Redis从早期版本到最新版本的发展历程和重要里程碑
2. **核心特性对比**：掌握各版本之间的主要差异和新增功能
3. **性能改进分析**：理解每个版本在性能方面的优化和提升
4. **新数据类型支持**：了解各版本引入的新数据结构和功能
5. **版本选择策略**：学会根据业务需求选择合适的Redis版本

## Redis版本概念与介绍

### Redis版本命名规则

Redis采用语义化版本控制（Semantic Versioning），版本号格式为：`主版本号.次版本号.修订号`

- **主版本号**：重大功能更新，可能存在不兼容的API变更
- **次版本号**：新功能添加，向后兼容
- **修订号**：Bug修复和安全补丁

### 版本发布周期

```
Redis 3.0 (2015) ──▶ Redis 4.0 (2017) ──▶ Redis 5.0 (2018) ──▶ Redis 6.0 (2020) ──▶ Redis 7.0 (2022) ──▶ Redis 7.2 (2023)
     │                    │                    │                    │                    │                    │
  集群支持              模块系统               Streams              ACL安全             函数计算             性能优化
```

### 版本选择考虑因素

- **稳定性要求**：生产环境通常选择稳定版本
- **功能需求**：根据业务需求选择支持特定功能的版本
- **性能要求**：新版本通常在性能方面有所提升
- **兼容性**：考虑与现有系统的兼容性
- **社区支持**：选择社区活跃、文档完善的版本

## Redis 4.0版本特性详解

### 1. 核心新功能

#### 1.1 模块系统（Modules）

**设计思想：**
Redis 4.0引入了模块系统，允许开发者通过C语言扩展Redis功能，实现自定义数据类型和命令。

**关键特性：**
```c
// 模块开发示例
int RedisModule_OnLoad(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
    // 注册模块
    if (RedisModule_Init(ctx, "mymodule", 1, REDISMODULE_APIVER_1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;
    
    // 注册命令
    if (RedisModule_CreateCommand(ctx, "mymodule.command", MyModule_Command, "readonly", 1, 1, 1) == REDISMODULE_ERR)
        return REDISMODULE_ERR;
    
    return REDISMODULE_OK;
}
```

**应用场景：**
- 自定义数据类型
- 业务逻辑扩展
- 第三方功能集成

#### 1.2 混合持久化（RDB-AOF）

**设计原理：**
结合RDB和AOF的优点，在AOF重写时，将重写点之前的数据以RDB格式写入AOF文件，重写点之后的数据以AOF格式追加。

**配置示例：**
```bash
# 启用混合持久化
aof-use-rdb-preamble yes

# AOF重写时使用RDB格式
# 重写后的AOF文件结构：
# [RDB格式数据][AOF格式增量数据]
```

**优势：**
- 启动速度快（RDB格式加载快）
- 文件体积小（RDB压缩率高）
- 数据安全性高（AOF实时写入）

#### 1.3 内存优化

**内存碎片整理：**
```bash
# 手动触发内存碎片整理
MEMORY PURGE

# 配置自动碎片整理
activedefrag yes
active-defrag-ignore-bytes 100mb
active-defrag-threshold-lower 10
active-defrag-threshold-upper 100
```

**内存统计增强：**
```bash
# 详细内存统计
MEMORY STATS

# 内存使用分析
MEMORY USAGE key
```

### 2. 性能改进

#### 2.1 延迟监控

**延迟监控命令：**
```bash
# 实时延迟监控
redis-cli --latency

# 延迟历史记录
redis-cli --latency-history

# 延迟分布统计
redis-cli --latency-dist
```

#### 2.2 慢查询优化

**慢查询配置增强：**
```bash
# 设置慢查询阈值（微秒）
CONFIG SET slowlog-log-slower-than 10000

# 设置慢查询日志长度
CONFIG SET slowlog-max-len 128

# 查看慢查询日志
SLOWLOG GET 10
```

### 3. 集群功能增强

#### 3.1 集群节点管理

**节点操作命令：**
```bash
# 添加从节点
CLUSTER REPLICATE node-id

# 移除节点
CLUSTER FORGET node-id

# 重新分片
CLUSTER RESHARD
```

#### 3.2 集群配置优化

**配置示例：**
```bash
# 集群配置
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes
```

## Redis 5.0版本特性详解

### 1. 核心新功能

#### 1.1 Stream数据类型

**设计思想：**
Redis Stream是专门为消息队列设计的数据类型，借鉴了Kafka的设计理念，支持多播、可持久化的消息队列功能。

**基本操作：**
```bash
# 添加消息到Stream
XADD mystream * sensor-id 1234 temperature 19.8 humidity 80

# 读取消息
XREAD COUNT 2 STREAMS mystream 0

# 消费者组操作
XGROUP CREATE mystream mygroup 0
XREADGROUP GROUP mygroup consumer1 COUNT 1 STREAMS mystream >
```

**关键特性：**
- **消息ID**：自动生成或手动指定
- **消费者组**：支持负载均衡和故障转移
- **确认机制**：消息确认和重试机制
- **持久化**：支持RDB和AOF持久化

#### 1.2 新的排序集合命令

**新增命令：**
```bash
# 弹出最大/最小元素
ZPOPMAX key [count]
ZPOPMIN key [count]

# 阻塞弹出
BZPOPMAX key [key ...] timeout
BZPOPMIN key [key ...] timeout

# 集合操作
ZUNIONSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
ZINTERSTORE destination numkeys key [key ...] [WEIGHTS weight [weight ...]] [AGGREGATE SUM|MIN|MAX]
```

#### 1.3 客户端缓存

**设计原理：**
Redis 5.0引入了客户端缓存功能，允许客户端缓存数据，减少网络往返。

**实现方式：**
```bash
# 客户端跟踪
CLIENT TRACKING on REDIRECT client-id

# 失效通知
CLIENT TRACKING on BCAST REDIRECT client-id
```

### 2. 性能优化

#### 2.1 内存优化

**内存统计增强：**
```bash
# 详细内存使用统计
MEMORY STATS

# 内存使用分析
MEMORY USAGE key [SAMPLES count]

# 内存医生
MEMORY DOCTOR
```

#### 2.2 网络优化

**连接管理：**
```bash
# 客户端列表增强
CLIENT LIST [TYPE normal|master|replica|pubsub]

# 客户端信息
CLIENT INFO

# 客户端暂停
CLIENT PAUSE timeout [WRITE|ALL]
```

### 3. 集群功能

#### 3.1 集群管理

**集群操作：**
```bash
# 集群节点信息
CLUSTER NODES

# 集群槽位信息
CLUSTER SLOTS

# 集群键分布
CLUSTER KEYSLOT key
```

## Redis 6.0版本特性详解

### 1. 核心新功能

#### 1.1 ACL访问控制

**设计思想：**
Redis 6.0引入了细粒度的访问控制列表（ACL），可以精确控制用户对命令和键的访问权限。

**ACL配置：**
```bash
# 创建用户
ACL SETUSER alice on >password123 ~cached:* +get +set

# 用户权限说明
# alice: 用户名
# on: 启用用户
# >password123: 密码
# ~cached:*: 可访问的键模式
# +get +set: 允许的命令

# 查看用户信息
ACL GETUSER alice

# 列出所有用户
ACL LIST
```

**权限类别：**
- **命令权限**：`+command`（允许）、`-command`（禁止）
- **键权限**：`~pattern`（可访问的键模式）
- **选择数据库**：`allkeys`、`resetkeys`
- **通道权限**：`&pattern`（可订阅的通道）

#### 1.2 客户端缓存

**设计原理：**
Redis 6.0的客户端缓存功能更加完善，支持基于键的失效通知。

**实现方式：**
```bash
# 启用客户端跟踪
CLIENT TRACKING on REDIRECT client-id

# 广播模式
CLIENT TRACKING on BCAST REDIRECT client-id

# 选择性跟踪
CLIENT TRACKING on OPTIN REDIRECT client-id
```

#### 1.3 RESP3协议

**协议改进：**
- 支持更多数据类型
- 更好的错误处理
- 改进的客户端库支持

### 2. 性能优化

#### 2.1 多线程I/O

**设计原理：**
Redis 6.0引入了多线程I/O处理，将网络I/O操作从主线程中分离出来。

**配置示例：**
```bash
# 启用多线程I/O
io-threads 4

# 启用多线程I/O写入
io-threads-do-reads yes
```

**性能提升：**
- 网络I/O性能提升2-3倍
- 减少主线程阻塞
- 更好的并发处理能力

#### 2.2 内存优化

**内存统计增强：**
```bash
# 内存使用详情
MEMORY STATS

# 内存医生诊断
MEMORY DOCTOR

# 内存使用分析
MEMORY USAGE key [SAMPLES count]
```

### 3. 集群功能

#### 3.1 集群管理

**集群操作增强：**
```bash
# 集群节点信息
CLUSTER NODES

# 集群槽位信息
CLUSTER SLOTS

# 集群重新分片
CLUSTER RESHARD

# 集群故障转移
CLUSTER FAILOVER [FORCE|TAKEOVER]
```

## Redis 7.0版本特性详解

### 1. 核心新功能

#### 1.1 Redis Functions

**设计思想：**
Redis 7.0引入了函数计算功能，允许在Redis服务器端执行自定义逻辑，类似于存储过程。

**函数定义：**
```lua
-- 定义函数
redis.register_function('my_function', function(keys, args)
    local key = keys[1]
    local value = args[1]
    redis.call('SET', key, value)
    return redis.call('GET', key)
end)

-- 调用函数
FCALL my_function 1 mykey "hello world"
```

**函数管理：**
```bash
# 列出所有函数
FUNCTION LIST

# 删除函数
FUNCTION DELETE my_function

# 函数统计
FUNCTION STATS
```

#### 1.2 新的数据类型和命令

**新增命令：**
```bash
# 字符串命令增强
SET key value [EX seconds] [PX milliseconds] [NX|XX] [KEEPTTL]

# 列表命令增强
LMOVE source destination LEFT|RIGHT LEFT|RIGHT

# 集合命令增强
SINTERCARD numkeys key [key ...] [LIMIT limit]

# 有序集合命令增强
ZMPOP numkeys key [key ...] MIN|MAX [COUNT count]
```

#### 1.3 客户端缓存增强

**功能改进：**
- 更好的失效通知机制
- 支持选择性跟踪
- 改进的性能和可靠性

### 2. 性能优化

#### 2.1 内存优化

**内存管理改进：**
```bash
# 内存碎片整理增强
MEMORY PURGE

# 内存使用分析增强
MEMORY USAGE key [SAMPLES count]

# 内存统计增强
MEMORY STATS
```

#### 2.2 网络优化

**连接管理增强：**
```bash
# 客户端信息增强
CLIENT INFO

# 客户端列表增强
CLIENT LIST [TYPE normal|master|replica|pubsub]

# 客户端暂停增强
CLIENT PAUSE timeout [WRITE|ALL]
```

### 3. 集群功能

#### 3.1 集群管理增强

**集群操作：**
```bash
# 集群节点管理
CLUSTER NODES

# 集群槽位管理
CLUSTER SLOTS

# 集群重新分片
CLUSTER RESHARD

# 集群故障转移
CLUSTER FAILOVER [FORCE|TAKEOVER]
```

## Redis 7.2版本特性详解

### 1. 核心新功能

#### 1.1 性能优化

**主要改进：**
- 内存使用优化
- 网络I/O性能提升
- 命令执行效率提升

#### 1.2 功能增强

**新增特性：**
- 更好的错误处理
- 改进的日志记录
- 增强的监控功能

### 2. 稳定性改进

**Bug修复：**
- 修复已知的内存泄漏问题
- 改进集群稳定性
- 增强网络连接处理

## 版本选择策略

### 1. 版本选择考虑因素

#### 1.1 功能需求

**按功能选择版本：**
- **集群需求**：Redis 3.0+
- **模块扩展**：Redis 4.0+
- **消息队列**：Redis 5.0+（Stream）
- **安全控制**：Redis 6.0+（ACL）
- **函数计算**：Redis 7.0+（Functions）

#### 1.2 性能需求

**性能对比：**
```
Redis 4.0: 基础性能
Redis 5.0: Stream性能优化
Redis 6.0: 多线程I/O，性能提升2-3倍
Redis 7.0: 进一步性能优化
Redis 7.2: 最新性能优化
```

#### 1.3 稳定性需求

**稳定性建议：**
- **生产环境**：选择稳定版本（如6.0、7.0）
- **测试环境**：可以使用最新版本
- **新项目**：建议使用较新版本
- **老项目**：谨慎升级，充分测试

### 2. 升级策略

#### 2.1 升级准备

**升级前检查：**
```bash
# 检查当前版本
redis-cli info server | grep redis_version

# 检查配置兼容性
redis-server --test

# 备份数据
redis-cli BGSAVE
```

#### 2.2 升级步骤

**升级流程：**
1. **环境准备**：准备新版本环境
2. **数据备份**：完整备份现有数据
3. **配置迁移**：迁移配置文件
4. **功能测试**：测试新功能
5. **性能测试**：验证性能表现
6. **生产部署**：正式升级

#### 2.3 回滚策略

**回滚准备：**
```bash
# 保留旧版本
# 准备回滚脚本
# 监控升级过程
# 准备快速回滚方案
```

### 3. 版本兼容性

#### 3.1 客户端兼容性

**客户端库版本：**
```java
// Java客户端版本对应
// Redis 4.0: Jedis 2.9+
// Redis 5.0: Jedis 3.0+
// Redis 6.0: Jedis 3.3+
// Redis 7.0: Jedis 4.0+
```

#### 3.2 协议兼容性

**RESP协议版本：**
- **RESP2**：Redis 2.0-5.0
- **RESP3**：Redis 6.0+

## Redis版本特性关联的其它知识

### 1. 数据库版本管理

- **[MySQL版本特性](../310-mysql/mysql版本特性.md)**：MySQL各版本新特性对比
- **[MongoDB版本特性](../330-mongo/mongo版本特性.md)**：MongoDB版本演进
- **[数据库升级策略](../500-基础理论/数据库升级策略.md)**：数据库版本升级最佳实践

### 2. 缓存技术演进

- **[缓存技术发展](../500-基础理论/缓存技术发展.md)**：缓存技术的演进历程
- **[分布式缓存架构](../500-基础理论/分布式缓存架构.md)**：分布式缓存设计模式
- **[缓存性能优化](../500-基础理论/缓存性能优化.md)**：缓存性能调优策略

### 3. 消息队列技术

- **[Kafka版本特性](../340-kafka/kafka版本特性.md)**：Kafka版本对比
- **[RabbitMQ版本特性](../350-rabbitMQ/rabbitmq版本特性.md)**：RabbitMQ版本演进
- **[消息队列架构设计](../500-基础理论/消息队列架构设计.md)**：消息队列设计模式

### 4. 系统架构演进

- **[微服务架构演进](../500-基础理论/微服务架构演进.md)**：微服务架构发展历程
- **[分布式系统设计](../500-基础理论/分布式系统设计.md)**：分布式系统设计原则
- **[高可用架构设计](../500-基础理论/高可用架构设计.md)**：高可用系统设计模式

### 5. 性能优化技术

- **[系统性能优化](../500-基础理论/系统性能优化.md)**：系统级性能调优
- **[应用性能优化](../500-基础理论/应用性能优化.md)**：应用级性能调优
- **[数据库性能优化](../500-基础理论/数据库性能优化.md)**：数据库性能调优 