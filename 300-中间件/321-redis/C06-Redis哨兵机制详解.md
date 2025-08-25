# Redis哨兵机制详解

## 重点
- Redis Sentinel哨兵机制的核心概念和工作原理
- 哨兵的监控、通知、自动故障转移功能
- 哨兵的部署配置和最佳实践
- 哨兵的故障检测和主观/客观下线机制
- 哨兵集群的选举和领导者哨兵的作用

## Redis哨兵机制概念或介绍

### 什么是哨兵机制

Redis Sentinel（哨兵）是Redis官方提供的高可用解决方案，用于监控Redis主从服务器的运行状态，并在主服务器出现故障时自动进行故障转移，将从服务器提升为新的主服务器。

**核心功能：**
- **监控(Monitoring)**：持续监控主从服务器是否按预期工作
- **通知(Notification)**：当被监控的服务器出现问题时，通过API向管理员或其他应用程序发送通知
- **自动故障转移(Automatic failover)**：当主服务器不能正常工作时，自动将一个从服务器升级为新的主服务器
- **配置提供者(Configuration provider)**：客户端连接Redis服务器时，会先询问哨兵，获取当前主服务器的地址

### 哨兵机制的基本概念

**1. 哨兵(Sentinel)**
- 运行在特殊模式下的Redis服务器
- 监控主从服务器的运行状态
- 执行故障检测和故障转移

**2. 主观下线(Subjective Down)**
- 单个哨兵认为某个服务器不可用
- 基于哨兵自身的网络连接判断
- 需要其他哨兵确认

**3. 客观下线(Objective Down)**
- 多个哨兵认为某个服务器不可用
- 基于投票机制达成共识
- 触发故障转移流程

**4. 领导者哨兵(Leader Sentinel)**
- 负责执行故障转移的哨兵
- 通过Raft算法选举产生
- 确保故障转移的唯一性

## Redis哨兵机制原理

### 哨兵工作流程

#### 1. 监控阶段

哨兵通过以下方式监控Redis服务器：

**心跳检测：**
- 哨兵每秒向主从服务器发送`PING`命令
- 服务器回复`PONG`表示正常
- 超时未回复表示可能故障

**信息收集：**
```bash
# 哨兵向主服务器发送INFO命令
INFO replication

# 获取从服务器列表
INFO replication

# 获取主服务器信息
INFO server
```

#### 2. 故障检测阶段

**主观下线检测：**
- 哨兵向服务器发送`PING`命令
- 如果在`down-after-milliseconds`时间内没有收到有效回复
- 哨兵将该服务器标记为主观下线

**客观下线检测：**
- 当主观下线的服务器是主服务器时
- 哨兵询问其他哨兵是否也认为该主服务器主观下线
- 如果超过`quorum`数量的哨兵认为主观下线
- 则将该主服务器标记为客观下线

#### 3. 故障转移阶段

**领导者选举：**
- 发现主服务器客观下线的哨兵成为候选者
- 候选者向其他哨兵发送投票请求
- 获得多数票的哨兵成为领导者

**故障转移执行：**
1. 领导者哨兵从从服务器中选择新的主服务器
2. 向选中的从服务器发送`SLAVEOF NO ONE`命令
3. 向其他从服务器发送`SLAVEOF`命令，指向新的主服务器
4. 更新哨兵的配置信息

### 哨兵选举机制

#### Raft算法

哨兵使用Raft算法进行领导者选举：

**选举过程：**
1. 哨兵启动时进入Follower状态
2. 如果超时未收到Leader心跳，转为Candidate
3. Candidate向其他哨兵请求投票
4. 获得多数票的Candidate成为Leader
5. Leader定期发送心跳维持地位

**投票规则：**
- 每个哨兵只能投一票
- 先到先得，投票后不能更改
- 需要获得超过半数的票数

### 故障转移策略

#### 从服务器选择策略

哨兵选择新主服务器的优先级：

1. **优先级**：`slave-priority`配置项，数值越小优先级越高
2. **复制偏移量**：选择复制偏移量最大的从服务器
3. **运行ID**：选择运行ID最小的从服务器

#### 故障转移配置

```bash
# 故障转移超时时间
sentinel failover-timeout mymaster 180000

# 并行同步从服务器数量
sentinel parallel-syncs mymaster 1

# 故障转移期间允许的最大延迟
sentinel down-after-milliseconds mymaster 30000
```

## Redis哨兵配置

### 哨兵配置文件

```bash
# 哨兵配置文件 sentinel.conf

# 哨兵端口
port 26379

# 哨兵工作目录
dir /tmp

# 监控主服务器
sentinel monitor mymaster 127.0.0.1 6379 2

# 主观下线时间
sentinel down-after-milliseconds mymaster 30000

# 故障转移超时时间
sentinel failover-timeout mymaster 180000

# 并行同步从服务器数量
sentinel parallel-syncs mymaster 1

# 认证密码
sentinel auth-pass mymaster mypassword

# 通知脚本
sentinel notification-script mymaster /path/to/notification.sh

# 客户端重新配置脚本
sentinel client-reconfig-script mymaster /path/to/reconfig.sh
```

### 哨兵启动命令

```bash
# 启动哨兵
redis-sentinel sentinel.conf

# 或者使用redis-server启动
redis-server sentinel.conf --sentinel
```

### 动态配置

```bash
# 添加监控的主服务器
SENTINEL MONITOR mymaster 127.0.0.1 6379 2

# 移除监控的主服务器
SENTINEL REMOVE mymaster

# 设置主观下线时间
SENTINEL SET mymaster down-after-milliseconds 30000

# 强制故障转移
SENTINEL FAILOVER mymaster
```

## 哨兵部署架构

### 单哨兵部署

```bash
# 主服务器
redis-server --port 6379

# 从服务器1
redis-server --port 6380 --slaveof 127.0.0.1 6379

# 从服务器2
redis-server --port 6381 --slaveof 127.0.0.1 6379

# 哨兵
redis-sentinel sentinel.conf
```

### 多哨兵部署

```bash
# 主从服务器配置同上

# 哨兵1
redis-sentinel sentinel1.conf

# 哨兵2
redis-sentinel sentinel2.conf

# 哨兵3
redis-sentinel sentinel3.conf
```

### 哨兵配置文件示例

**sentinel1.conf:**
```bash
port 26379
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
```

**sentinel2.conf:**
```bash
port 26380
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
```

**sentinel3.conf:**
```bash
port 26381
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
```

## 哨兵监控和运维

### 哨兵状态监控

```bash
# 查看哨兵信息
INFO sentinel

# 输出示例
sentinel_masters:1
sentinel_slaves:2
sentinel_sentinels:3
sentinel_master0:name=mymaster,status=ok,address=127.0.0.1:6379,slaves=2,sentinels=3
```

### 哨兵命令

```bash
# 查看监控的主服务器
SENTINEL MASTERS

# 查看指定主服务器的从服务器
SENTINEL SLAVES mymaster

# 查看哨兵信息
SENTINEL SENTINELS mymaster

# 查看主服务器地址
SENTINEL GET-MASTER-ADDR-BY-NAME mymaster

# 重置指定主服务器的状态
SENTINEL RESET mymaster

# 检查哨兵配置
SENTINEL CKQUORUM mymaster
```

### 客户端连接

```bash
# 使用哨兵连接Redis
redis-cli -h 127.0.0.1 -p 26379

# 获取主服务器地址
SENTINEL GET-MASTER-ADDR-BY-NAME mymaster

# 直接连接主服务器
redis-cli -h 127.0.0.1 -p 6379
```

## 哨兵故障处理

### 常见问题

**1. 哨兵网络分区**
- 原因：哨兵之间网络不通
- 解决：检查网络连接，重启哨兵

**2. 故障转移失败**
- 原因：从服务器配置问题
- 解决：检查从服务器状态，手动执行故障转移

**3. 脑裂问题**
- 原因：网络分区导致多个主服务器
- 解决：配置`min-slaves-to-write`和`min-slaves-max-lag`

### 故障恢复

```bash
# 检查哨兵状态
INFO sentinel

# 检查主从复制状态
INFO replication

# 手动故障转移
SENTINEL FAILOVER mymaster

# 重置哨兵状态
SENTINEL RESET mymaster
```

## 哨兵最佳实践

### 部署建议

1. **哨兵数量**：至少部署3个哨兵，推荐5个
2. **网络配置**：哨兵部署在不同机器上
3. **监控告警**：设置哨兵状态监控和告警
4. **备份策略**：定期备份哨兵配置文件

### 配置优化

```bash
# 优化主观下线时间
sentinel down-after-milliseconds mymaster 30000

# 优化故障转移超时时间
sentinel failover-timeout mymaster 180000

# 优化并行同步数量
sentinel parallel-syncs mymaster 1

# 启用通知脚本
sentinel notification-script mymaster /path/to/notification.sh
```

### 安全考虑

1. **访问控制**：设置哨兵密码
2. **网络隔离**：限制哨兵网络访问
3. **日志记录**：记录哨兵操作日志
4. **监控告警**：设置故障转移告警

## 哨兵与其他高可用方案对比

### 哨兵 vs 集群

| 特性 | 哨兵 | 集群 |
|------|------|------|
| 数据分片 | 不支持 | 支持 |
| 故障转移 | 支持 | 支持 |
| 扩展性 | 有限 | 高 |
| 复杂度 | 低 | 高 |
| 适用场景 | 中小规模 | 大规模 |

### 哨兵 vs 代理

| 特性 | 哨兵 | 代理 |
|------|------|------|
| 故障转移 | 自动 | 手动 |
| 负载均衡 | 不支持 | 支持 |
| 协议支持 | Redis协议 | 多种协议 |
| 性能开销 | 低 | 中等 |

## Redis哨兵机制关联的其它知识

### 相关技术

- **[Redis主从复制详解](C05-Redis主从复制详解.md)**：哨兵监控的基础架构
- **[Redis集群详解](C07-Redis集群详解.md)**：另一种高可用解决方案
- **[Redis持久化机制详解](C01-Redis持久化机制详解.md)**：数据安全的基础
- **[Redis事务机制详解](C03-Redis事务机制详解.md)**：故障转移中的事务处理

### 扩展阅读

- **分布式系统理论**：CAP理论、一致性算法
- **高可用架构**：故障检测、故障转移、负载均衡
- **网络协议**：TCP协议、网络分区处理
- **监控告警**：Prometheus、Grafana、告警机制 