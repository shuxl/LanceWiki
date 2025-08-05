# Kafka集群部署

## 重点内容

- Kafka集群架构设计和规划
- 硬件配置和网络规划
- 集群部署步骤和配置优化
- 高可用配置和故障恢复
- 监控和运维最佳实践

## Kafka集群概念和介绍

### 什么是Kafka集群

Kafka集群是由多个Broker节点组成的分布式消息系统，通过集群部署实现高可用、高吞吐量和数据持久化。

**集群核心组件：**
- **Broker**：Kafka服务器节点，负责消息存储和转发
- **Controller**：集群控制器，负责分区分配和故障转移
- **Zookeeper**：协调服务，管理集群元数据（Kafka 2.8+可选）
- **Topic**：消息主题，逻辑上的消息分类
- **Partition**：分区，Topic的物理存储单元
- **Replica**：副本，分区的数据备份

### 集群架构设计

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Producer      │    │   Kafka Cluster │    │   Consumer      │
│                 │    │                 │    │                 │
│ 1. 发送消息     │───▶│ 2. Broker1      │───▶│ 3. 消费消息     │
│                 │    │ 3. Broker2      │    │                 │
│                 │    │ 4. Broker3      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Zookeeper     │
                    │   (可选)        │
                    └─────────────────┘
```

### 集群优势

1. **高可用性**：多节点部署，单点故障不影响整体服务
2. **高吞吐量**：多节点并行处理，提高消息处理能力
3. **数据持久化**：多副本机制，确保数据不丢失
4. **水平扩展**：可以动态添加节点，扩展集群容量
5. **负载均衡**：自动分配分区，平衡节点负载

## 集群规划

### 集群规模规划

**节点数量考虑因素：**
- 预期消息吞吐量
- 数据存储需求
- 可用性要求
- 网络带宽限制
- 硬件资源成本

**推荐配置：**
- **小型集群**：3-5个Broker节点
- **中型集群**：6-10个Broker节点
- **大型集群**：10+个Broker节点

### 硬件配置规划

**CPU配置：**
- **推荐**：8-16核心CPU
- **考虑因素**：消息处理、压缩、网络IO
- **优化建议**：使用多核CPU，提高并行处理能力

**内存配置：**
- **推荐**：32-64GB内存
- **考虑因素**：页面缓存、JVM堆内存、网络缓冲区
- **优化建议**：预留足够内存给操作系统页面缓存

**存储配置：**
- **推荐**：SSD或NVMe SSD
- **考虑因素**：IOPS、吞吐量、延迟
- **优化建议**：使用RAID 0或JBOD配置

**网络配置：**
- **推荐**：10Gbps网络
- **考虑因素**：节点间通信、客户端连接
- **优化建议**：专用网络，避免网络拥塞

### 网络规划

**网络拓扑：**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   Kafka Cluster │    │   External      │
│   Network       │    │   Internal      │    │   Network       │
│                 │    │   Network       │    │                 │
│ 192.168.1.0/24 │───▶│ 10.0.0.0/24    │───▶│ 172.16.0.0/16  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 硬件配置

### 服务器配置

**生产环境推荐配置：**
```
CPU: 16核心 Intel Xeon 或 AMD EPYC
内存: 64GB DDR4
存储: 2TB NVMe SSD × 4 (RAID 0)
网络: 10Gbps网卡
操作系统: Linux (CentOS 7+ 或 Ubuntu 18+)
```

**开发/测试环境配置：**
```
CPU: 4-8核心
内存: 16-32GB
存储: 500GB SSD
网络: 1Gbps网卡
操作系统: Linux
```

### JVM配置

**堆内存配置：**
```bash
# 推荐配置
export KAFKA_HEAP_OPTS="-Xmx8g -Xms8g"

# 新生代配置
export KAFKA_JVM_PERFORMANCE_OPTS="-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -XX:MaxInlineLevel=15"
```

## 部署步骤

### 环境准备

**1. 系统要求：**
```bash
# 检查系统版本
cat /etc/os-release

# 检查Java版本
java -version

# 检查内存
free -h

# 检查磁盘
df -h
```

**2. 安装Java：**
```bash
# 安装OpenJDK 8或11
sudo apt update
sudo apt install openjdk-11-jdk
```

**3. 安装Kafka：**
```bash
# 下载Kafka
wget https://downloads.apache.org/kafka/3.5.1/kafka_2.13-3.5.1.tgz
tar -xzf kafka_2.13-3.5.1.tgz
sudo mv kafka_2.13-3.5.1 /opt/kafka
```

### 集群配置

**1. 配置server.properties：**
```properties
# 基本配置
broker.id=1
listeners=PLAINTEXT://broker1:9092
log.dirs=/opt/kafka/logs
num.partitions=3
default.replication.factor=3
min.insync.replicas=2
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=zk1:2181,zk2:2181,zk3:2181
```

**2. 启动集群：**
```bash
# 启动Zookeeper
sudo systemctl start zookeeper

# 启动Kafka
sudo systemctl start kafka

# 检查状态
sudo systemctl status kafka
```

**3. 验证集群：**
```bash
# 创建测试Topic
/opt/kafka/bin/kafka-topics.sh --create \
  --topic test-topic \
  --bootstrap-server broker1:9092 \
  --partitions 3 \
  --replication-factor 3

# 查看Topic信息
/opt/kafka/bin/kafka-topics.sh --describe \
  --topic test-topic \
  --bootstrap-server broker1:9092
```

## 配置优化

### Broker配置优化

**性能相关配置：**
```properties
# 网络配置
num.network.threads=8
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

# 日志配置
num.partitions=8
default.replication.factor=3
min.insync.replicas=2
log.flush.interval.messages=10000
log.flush.interval.ms=1000

# 内存配置
log.retention.bytes=-1
log.retention.hours=168
log.segment.bytes=1073741824
log.index.interval.bytes=4096
```

**高可用配置：**
```properties
# 副本配置
default.replication.factor=3
min.insync.replicas=2
unclean.leader.election.enable=false

# 控制器配置
controlled.shutdown.enable=true
controlled.shutdown.max.retries=3
controlled.shutdown.retry.backoff.ms=5000
```

### 客户端配置优化

**Producer配置：**
```properties
# 批量发送
batch.size=16384
linger.ms=5
compression.type=snappy

# 可靠性
acks=all
retries=3
max.in.flight.requests.per.connection=5
```

**Consumer配置：**
```properties
# 消费配置
fetch.min.bytes=1
fetch.max.wait.ms=500
max.partition.fetch.bytes=1048576

# 提交配置
enable.auto.commit=true
auto.commit.interval.ms=1000
```

## 高可用配置

### 副本策略

**副本分配策略：**
1. **机架感知**：将副本分配到不同机架
2. **可用区感知**：将副本分配到不同可用区
3. **手动分配**：手动指定副本分配

**副本配置示例：**
```bash
# 创建Topic时指定副本分配
/opt/kafka/bin/kafka-topics.sh --create \
  --topic important-topic \
  --bootstrap-server broker1:9092 \
  --partitions 6 \
  --replication-factor 3 \
  --config min.insync.replicas=2
```

### 故障转移

**自动故障转移：**
- Controller自动检测Broker故障
- 自动重新分配分区
- 自动选举新的Leader

**手动故障转移：**
```bash
# 手动触发Leader选举
/opt/kafka/bin/kafka-leader-election.sh \
  --bootstrap-server broker1:9092 \
  --election-type PREFERRED \
  --all-topic-partitions
```

## 监控和运维

### 监控工具

**内置监控：**
- JMX指标
- Kafka Manager
- Kafka Tool

**第三方监控：**
- Prometheus + Grafana
- Datadog
- New Relic

### 关键监控指标

**Broker指标：**
- 在线/离线状态
- 消息吞吐量
- 请求延迟
- 磁盘使用率

**Topic指标：**
- 分区数量
- 副本状态
- 消息积压
- 消费延迟

### 日志管理

**日志配置：**
```properties
# 日志级别
log4j.rootLogger=INFO, stdout, kafkaAppender

# 日志轮转
log4j.appender.kafkaAppender=org.apache.log4j.DailyRollingFileAppender
log4j.appender.kafkaAppender.File=${kafka.logs.dir}/server.log
log4j.appender.kafkaAppender.DatePattern='.'yyyy-MM-dd-HH
```

### 备份和恢复

**数据备份：**
```bash
# 备份Topic数据
/opt/kafka/bin/kafka-run-class.sh kafka.tools.ExportZkOffsets \
  --zkconnect zk1:2181 \
  --group my-group \
  --output-file /backup/offsets.txt

# 备份配置
cp /opt/kafka/config/server.properties /backup/
```

## Kafka集群关联的其它知识

### 与容器化技术

- **Docker部署**：使用Docker容器部署Kafka集群
- **Kubernetes部署**：在K8s上部署和管理Kafka
- **Helm Charts**：使用Helm简化Kafka部署

### 与云原生技术

- **云服务集成**：与AWS MSK、Azure Event Hubs集成
- **服务网格**：与Istio、Linkerd集成
- **监控集成**：与Prometheus、Grafana集成

### 与大数据生态

- **Spark集成**：Spark Streaming消费Kafka数据
- **Flink集成**：Apache Flink与Kafka集成
- **Hadoop集成**：与HDFS、HBase集成

### 扩展应用场景

- **微服务通信**：在微服务架构中使用Kafka
- **事件驱动架构**：作为事件驱动架构的核心组件
- **数据管道**：构建实时数据管道
- **日志收集**：集中收集和分析日志数据 