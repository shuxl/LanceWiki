# Redis主从复制详解

## 重点
- Redis主从复制的核心概念和工作原理
- 全量复制和增量复制的机制和流程
- 复制偏移量和复制积压缓冲区的作用
- 主从复制的配置和部署方法
- 复制过程中的数据一致性和性能考虑

## Redis主从复制概念或介绍

### 什么是主从复制

Redis主从复制是指将一台Redis服务器的数据复制到其他Redis服务器，实现数据的冗余备份和读写分离。其中，提供数据的服务器称为主服务器（Master），接收数据的服务器称为从服务器（Slave/Replica）。

**核心特点：**
- **数据冗余**：主从服务器数据一致，提供数据备份
- **读写分离**：主服务器负责写操作，从服务器负责读操作
- **故障恢复**：主服务器故障时，从服务器可以提升为主服务器
- **负载分担**：读请求可以分散到多个从服务器

### 主从复制的基本概念

**1. 主服务器(Master)**
- 提供数据的Redis服务器
- 处理写操作和读操作
- 向从服务器同步数据

**2. 从服务器(Slave/Replica)**
- 接收主服务器数据的Redis服务器
- 主要处理读操作
- 可以配置为只读模式

**3. 复制偏移量(Replication Offset)**
- 记录复制进度的数值
- 用于判断主从数据同步状态
- 支持断点续传

**4. 复制积压缓冲区(Replication Backlog)**
- 主服务器维护的固定大小缓冲区
- 存储最近写入的命令
- 支持增量复制

## Redis主从复制原理

### 复制过程概述

Redis主从复制分为三个阶段：
1. **建立连接阶段**：从服务器连接到主服务器
2. **数据同步阶段**：主服务器向从服务器同步数据
3. **命令传播阶段**：主服务器将写命令传播给从服务器

### 复制流程详解

#### 1. 建立连接阶段

```bash
# 从服务器执行
SLAVEOF master_ip master_port
# 或者
REPLICAOF master_ip master_port
```

**连接建立过程：**
1. 从服务器向主服务器发送`PING`命令
2. 主服务器回复`PONG`
3. 从服务器发送`AUTH`命令（如果设置了密码）
4. 从服务器发送`REPLCONF`命令，告知主服务器自己的端口
5. 从服务器发送`PSYNC`命令，开始同步

#### 2. 数据同步阶段

**全量复制(Full Resynchronization)**
- 适用场景：首次同步或复制偏移量不匹配
- 过程：
  1. 主服务器执行`BGSAVE`生成RDB文件
  2. 将RDB文件发送给从服务器
  3. 从服务器清空数据，加载RDB文件
  4. 主服务器将RDB生成期间的写命令发送给从服务器

**增量复制(Partial Resynchronization)**
- 适用场景：网络中断后重新连接
- 过程：
  1. 从服务器发送`PSYNC`命令，包含复制偏移量
  2. 主服务器检查复制积压缓冲区
  3. 如果偏移量在缓冲区内，发送缺失的命令
  4. 如果偏移量不在缓冲区内，执行全量复制

#### 3. 命令传播阶段

- 主服务器接收写命令
- 执行写命令
- 将写命令发送给所有从服务器
- 从服务器执行相同的写命令

### 复制偏移量机制

**复制偏移量的作用：**
- 记录主从服务器的复制进度
- 用于判断数据同步状态
- 支持断点续传

**偏移量的更新：**
- 主服务器每处理一个写命令，偏移量增加
- 从服务器每执行一个写命令，偏移量增加
- 偏移量相同表示数据同步

```bash
# 查看复制偏移量
INFO replication
```

### 复制积压缓冲区

**缓冲区的作用：**
- 存储主服务器最近写入的命令
- 支持增量复制
- 提高复制效率

**缓冲区配置：**
```bash
# 设置缓冲区大小（字节）
repl-backlog-size 1mb

# 设置缓冲区过期时间（秒）
repl-backlog-ttl 3600
```

## Redis主从复制配置

### 主服务器配置

```bash
# 基本配置
port 6379
bind 0.0.0.0
daemonize yes

# 持久化配置
save 900 1
save 300 10
save 60 10000
dbfilename dump.rdb
dir ./

# 复制相关配置
repl-backlog-size 1mb
repl-backlog-ttl 3600
repl-diskless-sync no
repl-diskless-sync-delay 5
```

### 从服务器配置

```bash
# 基本配置
port 6380
bind 0.0.0.0
daemonize yes

# 主从复制配置
slaveof 127.0.0.1 6379
# 或者使用新命令
# replicaof 127.0.0.1 6379

# 从服务器只读模式
slave-read-only yes
# 或者
replica-read-only yes

# 复制超时时间
repl-timeout 60

# 复制缓冲区大小
repl-backlog-size 1mb
```

### 动态配置

```bash
# 动态设置主从关系
SLAVEOF 127.0.0.1 6379

# 取消主从关系
SLAVEOF NO ONE

# 查看复制信息
INFO replication

# 查看从服务器列表
CLIENT LIST
```

## 主从复制部署

### 单主单从部署

```bash
# 启动主服务器
redis-server --port 6379

# 启动从服务器
redis-server --port 6380 --slaveof 127.0.0.1 6379
```

### 单主多从部署

```bash
# 启动主服务器
redis-server --port 6379

# 启动从服务器1
redis-server --port 6380 --slaveof 127.0.0.1 6379

# 启动从服务器2
redis-server --port 6381 --slaveof 127.0.0.1 6379

# 启动从服务器3
redis-server --port 6382 --slaveof 127.0.0.1 6379
```

### 级联复制部署

```bash
# 主服务器
redis-server --port 6379

# 一级从服务器
redis-server --port 6380 --slaveof 127.0.0.1 6379

# 二级从服务器
redis-server --port 6381 --slaveof 127.0.0.1 6380
```

## 主从复制监控

### 复制状态监控

```bash
# 查看复制信息
INFO replication

# 输出示例
role:master
connected_slaves:2
slave0:ip=127.0.0.1,port=6380,state=online,offset=12345,lag=0
slave1:ip=127.0.0.1,port=6381,state=online,offset=12345,lag=0
master_replid:1234567890abcdef
master_replid2:0000000000000000
master_repl_offset:12345
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:12345
```

### 复制延迟监控

```bash
# 查看复制延迟
redis-cli -p 6379 info replication | grep lag

# 监控复制状态
redis-cli -p 6379 --latency
```

## 主从复制优化

### 网络优化

```bash
# 设置TCP keepalive
tcp-keepalive 300

# 设置复制超时时间
repl-timeout 60

# 设置复制缓冲区大小
repl-backlog-size 10mb
```

### 性能优化

```bash
# 启用无盘复制
repl-diskless-sync yes

# 设置无盘复制延迟
repl-diskless-sync-delay 5

# 优化RDB配置
save 900 1
save 300 10
save 60 10000
rdbcompression yes
```

### 内存优化

```bash
# 设置最大内存
maxmemory 2gb

# 设置内存策略
maxmemory-policy allkeys-lru

# 启用内存优化
activedefrag yes
```

## 主从复制故障处理

### 常见问题

**1. 复制中断**
- 原因：网络问题、主服务器重启
- 解决：检查网络连接，重启从服务器

**2. 复制延迟**
- 原因：网络延迟、主服务器负载高
- 解决：优化网络，增加复制缓冲区

**3. 数据不一致**
- 原因：复制偏移量不匹配
- 解决：执行全量复制

### 故障恢复

```bash
# 检查复制状态
INFO replication

# 重新建立复制关系
SLAVEOF 127.0.0.1 6379

# 强制全量复制
SLAVEOF NO ONE
SLAVEOF 127.0.0.1 6379
```

## 主从复制最佳实践

### 部署建议

1. **网络配置**：主从服务器部署在同一网络
2. **硬件配置**：从服务器配置不低于主服务器
3. **监控告警**：设置复制状态监控和告警
4. **备份策略**：定期备份主服务器数据

### 性能优化

1. **读写分离**：写操作在主服务器，读操作在从服务器
2. **负载均衡**：使用多个从服务器分担读负载
3. **网络优化**：使用专用网络连接主从服务器
4. **内存优化**：合理配置内存和持久化参数

### 安全考虑

1. **访问控制**：设置Redis密码
2. **网络隔离**：限制网络访问
3. **数据加密**：敏感数据加密存储
4. **审计日志**：记录访问日志

## Redis主从复制关联的其它知识

### 相关技术

- **[Redis哨兵机制详解](C06-Redis哨兵机制详解.md)**：主从复制的故障检测和自动故障转移
- **[Redis集群详解](C07-Redis集群详解.md)**：基于主从复制的集群架构
- **[Redis持久化机制详解](C01-Redis持久化机制详解.md)**：主从复制的数据同步基础
- **[Redis事务机制详解](C03-Redis事务机制详解.md)**：主从复制中的事务处理

### 扩展阅读

- **分布式系统理论**：CAP理论、一致性模型
- **网络协议**：TCP协议、网络延迟处理
- **数据库复制**：MySQL主从复制、MongoDB复制集
- **高可用架构**：故障转移、负载均衡 