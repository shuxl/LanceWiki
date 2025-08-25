# Redis监控与运维

## 本文重点

1. **监控指标体系**：掌握Redis的关键监控指标，包括性能指标、内存指标、网络指标等
2. **监控工具使用**：了解Redis自带的监控命令和第三方监控工具的使用方法
3. **日志分析方法**：学会分析Redis日志，识别性能问题和异常情况
4. **性能诊断技巧**：掌握Redis性能问题的诊断方法和优化策略
5. **运维最佳实践**：了解Redis生产环境的运维规范和最佳实践

## Redis监控概念与介绍

### 监控的重要性

Redis作为高性能的内存数据库，在生产环境中需要持续监控其运行状态，确保：

- **性能稳定**：及时发现性能瓶颈和异常
- **资源合理利用**：监控内存、CPU、网络等资源使用情况
- **故障预警**：提前发现潜在问题，避免服务中断
- **容量规划**：为业务增长提供数据支撑

### 监控体系架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   数据采集层     │    │   数据处理层     │    │   数据展示层     │
│                 │    │                 │    │                 │
│ • Redis INFO    │───▶│ • 数据聚合       │───▶│ • Grafana       │
│ • 慢查询日志     │    │ • 告警规则       │    │ • Prometheus    │
│ • 系统指标       │    │ • 数据存储       │    │ • 自定义面板     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Redis监控指标体系

### 1. 性能指标

#### 1.1 吞吐量指标

```bash
# 获取Redis性能统计信息
redis-cli info stats
```

**关键指标：**

- **ops_per_sec**：每秒操作数
- **total_commands_processed**：总处理命令数
- **total_connections_received**：总连接数
- **rejected_connections**：拒绝连接数

#### 1.2 延迟指标

```bash
# 测试Redis延迟
redis-cli --latency
redis-cli --latency-history
redis-cli --latency-dist
```

**关键指标：**

- **平均延迟**：通常应小于1ms
- **P99延迟**：99%的请求延迟
- **P999延迟**：99.9%的请求延迟

### 2. 内存指标

#### 2.1 内存使用情况

```bash
# 获取内存信息
redis-cli info memory
```

**关键指标：**

```latex
\text{内存使用率} = \frac{\text{used_memory}}{\text{maxmemory}} \times 100\%
```

- **used_memory**：Redis实际使用的内存
- **used_memory_rss**：操作系统分配的内存
- **used_memory_peak**：内存使用峰值
- **mem_fragmentation_ratio**：内存碎片率

#### 2.2 内存碎片分析

```bash
# 内存碎片率计算
mem_fragmentation_ratio = used_memory_rss / used_memory
```

**判断标准：**
- **< 1.1**：内存碎片较少
- **1.1 - 1.5**：内存碎片较多，需要关注
- **> 1.5**：内存碎片严重，建议重启

### 3. 网络指标

#### 3.1 连接统计

```bash
# 获取连接信息
redis-cli info clients
```

**关键指标：**
- **connected_clients**：当前连接数
- **blocked_clients**：阻塞连接数
- **maxclients**：最大连接数

#### 3.2 网络I/O

```bash
# 获取网络统计
redis-cli info stats | grep -E "(total_net_input_bytes|total_net_output_bytes)"
```

### 4. 持久化指标

#### 4.1 RDB指标

```bash
# RDB相关信息
redis-cli info persistence
```

**关键指标：**
- **rdb_last_save_time**：最后一次RDB保存时间
- **rdb_changes_since_last_save**：上次保存后的变更数
- **rdb_bgsave_in_progress**：是否正在后台保存

#### 4.2 AOF指标

**关键指标：**
- **aof_enabled**：AOF是否启用
- **aof_rewrite_in_progress**：是否正在重写AOF
- **aof_current_size**：当前AOF文件大小
- **aof_base_size**：上次重写时的AOF大小

## Redis监控工具详解

### 1. Redis自带监控命令

#### 1.1 INFO命令详解

```bash
# 获取所有信息
redis-cli info

# 获取特定部分信息
redis-cli info server      # 服务器信息
redis-cli info clients     # 客户端信息
redis-cli info memory      # 内存信息
redis-cli info persistence # 持久化信息
redis-cli info stats       # 统计信息
redis-cli info replication # 复制信息
redis-cli info cpu         # CPU信息
redis-cli info cluster     # 集群信息
redis-cli info keyspace    # 键空间信息
```

#### 1.2 MONITOR命令

```bash
# 实时监控Redis命令执行
redis-cli monitor
```

**使用场景：**
- 调试特定问题
- 分析命令模式
- 性能问题排查

**注意事项：**
- 生产环境谨慎使用，会降低性能
- 建议在低峰期使用
- 可以结合grep过滤特定命令

#### 1.3 SLOWLOG命令

```bash
# 查看慢查询日志
redis-cli slowlog get 10   # 获取最近10条慢查询
redis-cli slowlog len      # 获取慢查询日志长度
redis-cli slowlog reset    # 清空慢查询日志
```

**慢查询配置：**
```bash
# 设置慢查询阈值（微秒）
CONFIG SET slowlog-log-slower-than 10000

# 设置慢查询日志长度
CONFIG SET slowlog-max-len 128
```

### 2. 第三方监控工具

#### 2.1 Redis Commander

**特点：**
- Web界面管理Redis
- 实时监控Redis状态
- 支持多Redis实例管理

**安装使用：**
```bash
# 使用Docker安装
docker run --rm --name redis-commander -p 8081:8081 rediscommander/redis-commander:latest

# 访问地址
http://localhost:8081
```

#### 2.2 RedisInsight

**特点：**
- Redis官方GUI工具
- 功能强大，界面友好
- 支持性能分析

**功能特性：**
- 实时监控
- 性能分析
- 内存分析
- 慢查询分析
- 集群管理

#### 2.3 Prometheus + Grafana

**架构设计：**
```
Redis ──▶ Redis Exporter ──▶ Prometheus ──▶ Grafana
```

**配置示例：**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
```

**关键指标：**
- redis_up
- redis_connected_clients
- redis_used_memory_bytes
- redis_commands_processed_total
- redis_keyspace_hits_total
- redis_keyspace_misses_total

## Redis日志分析

### 1. 日志配置

#### 1.1 日志级别设置

```bash
# redis.conf配置
loglevel notice  # 可选：debug, verbose, notice, warning

# 动态设置
CONFIG SET loglevel notice
```

**日志级别说明：**
- **debug**：调试信息，包含大量详细信息
- **verbose**：详细日志，包含很多有用信息
- **notice**：通知信息，生产环境推荐
- **warning**：警告信息，只记录警告和错误

#### 1.2 日志文件配置

```bash
# redis.conf配置
logfile /var/log/redis/redis-server.log

# 日志轮转配置
# 使用logrotate进行日志轮转
```

### 2. 常见日志分析

#### 2.1 连接相关日志

**正常连接日志：**
```
[timestamp] Accepted connection from 127.0.0.1:port
[timestamp] Client closed connection
```

**异常连接日志：**
```
[timestamp] Connection refused
[timestamp] Client timeout
[timestamp] Connection limit reached
```

#### 2.2 内存相关日志

**内存警告：**
```
[timestamp] WARNING overcommit_memory is set to 0!
[timestamp] WARNING you have Transparent Huge Pages (THP) support enabled
[timestamp] WARNING memory usage is high
```

#### 2.3 持久化相关日志

**RDB日志：**
```
[timestamp] Background saving started by pid
[timestamp] Background saving terminated with success
[timestamp] Background saving error
```

**AOF日志：**
```
[timestamp] Background append only file rewriting started by pid
[timestamp] Background AOF rewrite terminated with success
[timestamp] Background AOF rewrite error
```

### 3. 日志分析工具

#### 3.1 使用grep分析

```bash
# 分析错误日志
grep "ERROR" /var/log/redis/redis-server.log

# 分析警告日志
grep "WARNING" /var/log/redis/redis-server.log

# 分析特定时间段的日志
grep "2024-01-01" /var/log/redis/redis-server.log
```

#### 3.2 使用awk分析

```bash
# 统计每小时连接数
awk '/Accepted connection/ {print $1}' /var/log/redis/redis-server.log | \
awk -F: '{print $1":"$2}' | sort | uniq -c

# 统计错误类型
awk '/ERROR/ {print $NF}' /var/log/redis/redis-server.log | sort | uniq -c
```

## Redis性能诊断

### 1. 性能问题识别

#### 1.1 高延迟问题

**症状：**
- 客户端请求延迟增加
- 吞吐量下降
- 连接数增加

**诊断方法：**
```bash
# 检查延迟
redis-cli --latency

# 检查慢查询
redis-cli slowlog get 10

# 检查内存使用
redis-cli info memory

# 检查网络连接
redis-cli info clients
```

#### 1.2 内存问题

**症状：**
- 内存使用率过高
- 频繁触发内存淘汰
- 内存碎片严重

**诊断方法：**
```bash
# 检查内存使用情况
redis-cli info memory

# 检查内存策略
redis-cli config get maxmemory-policy

# 分析大key
redis-cli --bigkeys

# 检查内存碎片
redis-cli info memory | grep mem_fragmentation_ratio
```

#### 1.3 网络问题

**症状：**
- 连接数过多
- 网络I/O瓶颈
- 客户端超时

**诊断方法：**
```bash
# 检查连接数
redis-cli info clients

# 检查网络统计
redis-cli info stats | grep -E "(total_net_input_bytes|total_net_output_bytes)"

# 检查网络延迟
redis-cli --latency
```

### 2. 性能优化策略

#### 2.1 内存优化

**大key优化：**
```bash
# 查找大key
redis-cli --bigkeys

# 分批删除大key
redis-cli --scan --pattern "large_key:*" | xargs -L 100 redis-cli del
```

**内存策略优化：**
```bash
# 设置合适的内存淘汰策略
CONFIG SET maxmemory-policy allkeys-lru

# 设置内存上限
CONFIG SET maxmemory 2gb
```

#### 2.2 网络优化

**连接池优化：**
```java
// Java客户端连接池配置
JedisPoolConfig config = new JedisPoolConfig();
config.setMaxTotal(100);        // 最大连接数
config.setMaxIdle(20);          // 最大空闲连接数
config.setMinIdle(5);           // 最小空闲连接数
config.setMaxWaitMillis(3000);  // 最大等待时间
```

**批量操作优化：**
```bash
# 使用pipeline批量操作
redis-cli --pipe < commands.txt

# 使用multi/exec事务
redis-cli multi
redis-cli set key1 value1
redis-cli set key2 value2
redis-cli exec
```

#### 2.3 持久化优化

**RDB优化：**
```bash
# 调整RDB保存策略
CONFIG SET save "900 1 300 10 60 10000"

# 禁用RDB（如果不需要）
CONFIG SET save ""
```

**AOF优化：**
```bash
# 调整AOF重写策略
CONFIG SET auto-aof-rewrite-percentage 100
CONFIG SET auto-aof-rewrite-min-size 64mb

# 使用AOF重写
BGREWRITEAOF
```

## Redis运维最佳实践

### 1. 部署最佳实践

#### 1.1 系统配置优化

**内核参数优化：**
```bash
# /etc/sysctl.conf
# 禁用透明大页
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# 调整overcommit_memory
echo 1 > /proc/sys/vm/overcommit_memory

# 调整TCP参数
echo 511 > /proc/sys/net/core/somaxconn
```

**文件描述符限制：**
```bash
# /etc/security/limits.conf
redis soft nofile 65536
redis hard nofile 65536
```

#### 1.2 Redis配置优化

**基础配置：**
```bash
# redis.conf
# 绑定地址
bind 127.0.0.1

# 端口
port 6379

# 守护进程
daemonize yes

# 日志级别
loglevel notice

# 日志文件
logfile /var/log/redis/redis-server.log

# 数据目录
dir /var/lib/redis

# 内存配置
maxmemory 2gb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000

# 安全配置
requirepass your_password
```

### 2. 监控告警配置

#### 2.1 关键指标告警

**内存告警：**
```bash
# 内存使用率超过80%告警
if [ $(redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r') -gt 80 ]; then
    echo "Redis memory usage is high" | mail -s "Redis Alert" admin@example.com
fi
```

**连接数告警：**
```bash
# 连接数超过1000告警
connected_clients=$(redis-cli info clients | grep connected_clients | cut -d: -f2)
if [ $connected_clients -gt 1000 ]; then
    echo "Redis connection count is high: $connected_clients" | mail -s "Redis Alert" admin@example.com
fi
```

#### 2.2 自动化监控脚本

```bash
#!/bin/bash
# redis_monitor.sh

REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD="your_password"

# 检查Redis是否运行
check_redis_running() {
    if ! redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping > /dev/null 2>&1; then
        echo "Redis is not running"
        exit 1
    fi
}

# 检查内存使用
check_memory_usage() {
    memory_usage=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    echo "Memory usage: $memory_usage"
}

# 检查连接数
check_connections() {
    connections=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD info clients | grep connected_clients | cut -d: -f2)
    echo "Connected clients: $connections"
}

# 主函数
main() {
    check_redis_running
    check_memory_usage
    check_connections
}

main
```

### 3. 备份与恢复

#### 3.1 数据备份策略

**RDB备份：**
```bash
# 手动触发RDB备份
redis-cli BGSAVE

# 检查备份状态
redis-cli info persistence

# 复制RDB文件
cp /var/lib/redis/dump.rdb /backup/redis_$(date +%Y%m%d_%H%M%S).rdb
```

**AOF备份：**
```bash
# 手动触发AOF重写
redis-cli BGREWRITEAOF

# 复制AOF文件
cp /var/lib/redis/appendonly.aof /backup/redis_aof_$(date +%Y%m%d_%H%M%S).aof
```

#### 3.2 数据恢复

**RDB恢复：**
```bash
# 停止Redis
systemctl stop redis

# 替换RDB文件
cp /backup/redis_20240101_120000.rdb /var/lib/redis/dump.rdb

# 启动Redis
systemctl start redis
```

**AOF恢复：**
```bash
# 停止Redis
systemctl stop redis

# 替换AOF文件
cp /backup/redis_aof_20240101_120000.aof /var/lib/redis/appendonly.aof

# 启动Redis
systemctl start redis
```

### 4. 故障处理

#### 4.1 常见故障处理

**Redis无法启动：**
```bash
# 检查配置文件语法
redis-server /etc/redis/redis.conf --test

# 检查端口占用
netstat -tlnp | grep 6379

# 检查权限
ls -la /var/lib/redis/
ls -la /var/log/redis/
```

**内存不足：**
```bash
# 检查内存使用
free -h

# 清理内存
echo 1 > /proc/sys/vm/drop_caches

# 重启Redis
systemctl restart redis
```

**连接数过多：**
```bash
# 检查连接数
redis-cli info clients

# 杀死空闲连接
redis-cli client list | grep idle= | awk '{print $1}' | cut -d= -f2 | xargs -I {} redis-cli client kill id {}
```

#### 4.2 紧急处理流程

1. **立即响应**：确认问题影响范围
2. **快速诊断**：使用监控工具快速定位问题
3. **临时解决**：采取临时措施恢复服务
4. **根本解决**：分析根本原因并彻底解决
5. **总结改进**：记录问题处理过程，改进监控和预防措施

## Redis监控与运维关联的其它知识

### 1. 系统监控

- **[Linux系统监控](../400-开发工具/linux监控.md)**：系统资源监控、性能分析
- **[网络监控](../400-开发工具/网络监控.md)**：网络流量监控、网络性能分析
- **[日志分析](../400-开发工具/日志分析.md)**：日志收集、分析、告警

### 2. 数据库监控

- **[MySQL监控](../310-mysql/mysql监控.md)**：MySQL性能监控、优化
- **[MongoDB监控](../330-mongo/mongo监控.md)**：MongoDB监控、运维
- **[数据库性能优化](../500-基础理论/数据库性能优化.md)**：数据库性能调优理论

### 3. 运维自动化

- **[Docker监控](../412-docker/docker监控.md)**：容器监控、资源管理
- **[Kubernetes监控](../412-docker/kubernetes监控.md)**：K8s集群监控
- **[CI/CD监控](../400-开发工具/CI-CD监控.md)**：持续集成/部署监控

### 4. 监控工具

- **[Prometheus详解](../400-开发工具/prometheus详解.md)**：监控系统搭建
- **[Grafana使用](../400-开发工具/grafana使用.md)**：数据可视化
- **[ELK Stack](../400-开发工具/elk-stack.md)**：日志分析平台

### 5. 性能优化

- **[系统性能优化](../500-基础理论/系统性能优化.md)**：系统级性能调优
- **[应用性能优化](../500-基础理论/应用性能优化.md)**：应用级性能调优
- **[网络性能优化](../500-基础理论/网络性能优化.md)**：网络性能调优 