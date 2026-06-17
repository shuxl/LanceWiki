# E02 - Redis网络模型

## 概念或介绍
- 重点：
  - 单线程事件循环 + I/O 多路复用（select/poll/epoll/kqueue）是 Redis 高性能的基础。
  - 文件事件（可读、可写）与时间事件（定期任务）驱动请求处理与后台维护。
  - pipeline、批量、PSYNC 复制与缓冲区管理影响端到端延迟与吞吐。
  - 内核参数、连接管理、协议优化（RESP）对网络性能的决定性影响。

## 事件驱动与 I/O 多路复用（底层原理）
### 事件循环
- 基于 aeEventLoop（不同平台封装后端：epoll/kqueue/evport/select）。
- 文件事件：
  - 读事件：accept 新连接、读请求、主从复制字节流；
  - 写事件：应答发送、复制回放；
  - 辅以可写触发时的缓冲区回排与限速控制。
- 时间事件：
  - serverCron 等周期任务（过期扫描、AOF fsync、统计、复制超时检测）。

### 请求处理路径
1) 连接建立：监听套接字可读→ accept → 生成客户端对象与读事件注册；
2) 读取请求：读事件触发→ 解析 RESP → 命令查找与执行；
3) 写回响应：写缓冲区填充→ 注册写事件→ 内核可写后发送→ 缓冲区回收/限速；
4) 关闭/异常：错误/超时/客户端主动关闭→ 清理资源与订阅/事务状态。

## 协议、缓冲与复制
### RESP 协议
- 简洁文本协议，常见帧：Simple Strings、Errors、Integers、Bulk Strings、Arrays；RESP3 引入更多类型（Map、Set、Attribute）。
- Pipeline：客户端一次发送多命令，减少 RTT；需注意单命令耗时与返回顺序。

### 客户端缓冲区
- server/client-output-buffer-limit：区分 normal、pubsub、slave 类客户端的写缓冲限制，防止内存被慢客户端拖垮；
- 当超限触发硬/软限制，连接将被关闭或延迟写出。

### 复制链路
- PSYNC：支持部分重同步；复制积压缓冲区（replication backlog）用于断线重连快速追赶；
- 复制发送缓冲与磁盘 I/O（RDB/AOF）协同影响带宽与延迟；
- 主从心跳与超时控制保证链路健康。

## 连接管理与内核调优
### 连接生命周期与参数
- timeout、tcp-keepalive：空闲连接回收与存活探测；
- 最大连接数：内核 fd 限制（ulimit -n）、accept backlog（tcp_max_syn_backlog）、somaxconn；
- 网络栈队列：listen 队列满导致丢包与连接抖动。

### 内核与网络优化
- Nagle（TCP_NODELAY）：Redis 默认禁用，降低小包合并延迟；
- TCP 快速打开、RFS/RPS、网卡多队列：在高并发场景优化收包路径；
- net.core.wmem_default/rmem_default 与 tcp_{wmem,rmem}：调大窗口适配带宽时延积；
- 大页和中断绑定：避免 NUMA 交叉访存，提升一致性。

## 高性能实践
- 使用 pipeline 与批量命令，合并小请求；
- 避免大键与阻塞命令，减少单次写回耗时；
- 设置合理的 client-output-buffer-limit，处置慢客户端；
- 复制链路：调大 backlog，部署就近机房，使用局域内复制；
- 业务层做连接池与复用，限制短连接风暴；
- 对外网场景可用 TLS 但评估加解密成本（见 E03 安全机制）。

## 故障与诊断
- 现象：latency spike、丢连接、复制落后、pubsub 堵塞；
- 工具：LATENCY、CLIENT LIST、INFO stats/replication、SLOWLOG、tcpdump；
- 分析：定位是否为慢客户端、单命令阻塞、内核队列拥塞或复制瓶颈。

## Redis关联的其它知识
- 与缓存架构：端到端延迟预算、批量/回源策略；见《F02-缓存架构设计》。
- 与高并发系统：连接池化、限流、熔断、退避重试；见《F03-高并发系统设计》。

 