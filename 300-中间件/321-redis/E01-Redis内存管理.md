# E01 - Redis内存管理

## 概念或介绍
- 重点：
  - 内存分配器选择（jemalloc/tcmalloc/malloc）对碎片率与延迟的影响。
  - 对象模型与编码（SDS、ziplist/listpack、hashtable、intset、skiplist）如何影响内存占用。
  - 内存上限与淘汰策略（maxmemory、maxmemory-policy）及其业务语义。
  - 内存碎片、惰性释放、主动碎片整理（active-defrag）的权衡与配置。
  - 大键、大值与热点、过期键、TTL 设计对内存曲线与抖动的影响。

## 内存分配与对象模型（底层原理）
### 内存分配器
- 默认多为 jemalloc（官方推荐），特性：分级分配、线程局部缓存、减少锁争用，提升吞吐，可能带来内存碎片。
- 可在编译阶段或发行版本中选择：jemalloc、tcmalloc、libc malloc。
- 关键指标：碎片率（used_memory_rss/used_memory）、延迟（分配/释放热点路径）、峰值内存。

### Redis 对象与编码
- String → 编码：raw、embstr、int；底层 SDS（Simple Dynamic String）。embstr 小对象优化，int 编码节省空间。
- List → 早期 ziplist，后续 listpack + quicklist（分片压缩段），兼顾顺序访问与节省内存。
- Hash → 小对象用 ziplist/listpack，超过阈值转 hashtable；参数影响：hash-max-ziplist-entries/ value。
- Set → 小对象用 intset（整型集合），超过阈值转 hashtable。
- ZSet → 小对象用 ziplist/listpack，超过阈值转 skiplist+dict（双结构）。

### 过期与惰性/定期删除
- 惰性删除：访问键时检查 TTL，过期则删除；优点低开销，缺点过期积压。
- 定期删除：周期性采样过期键清理，控制单次耗时，降低抖动。
- AOF/RDB 对内存无直接占用，但过期回放策略影响恢复后的键存活。

## 内存上限与淘汰策略（maxmemory）
### 关键配置
- maxmemory：限制实例可用内存上限，建议保留 10%~20% OS 余量给分配器与内核缓存。
- maxmemory-policy：
  - noeviction：超限后写命令报错；适合强一致但可能影响可用性。
  - allkeys-lru / volatile-lru：基于 LRU 淘汰；volatile 仅在有 TTL 的键中淘汰。
  - allkeys-lfu / volatile-lfu：基于 LFU（访问频次）淘汰，热点友好。
  - allkeys-random / volatile-random：随机淘汰，简单但不可控。
  - volatile-ttl：优先淘汰 TTL 最近到期的键。

### LRU vs LFU 简述
- LRU 关注最近访问时间，适合时间局部性；LFU 关注访问频度，抗抖动更强，防止一次性流量“刷热”。
- 相关参数：
  - lfu-log-factor：调节频次增幅曲线；
  - lfu-decay-time：频次衰减周期，控制热点淘汰速度。

## 内存碎片与整理
### 观测
- info memory：used_memory、used_memory_rss、mem_fragmentation_ratio、allocator_frag_ratio。
- allocator 枚举项（jemalloc stats）可通过 CONFIG SET/GET、MEMORY STATS 获取。

### 主动碎片整理（active-defrag）
- active-defrag yes：后台渐进式整理，降低 RSS；
- 调参与触发：active-defrag-ignore-bytes、active-defrag-threshold-lower/upper 等；
- 风险：整理期间有额外 CPU/内存开销，可能与业务高峰冲突，需限流与窗口化执行。

## 典型问题与治理
### 大键/大值
- 危害：阻塞 I/O、复制/AOF 放大、慢查询、热点倾斜、迁移/备份困难。
- 治理：拆键（hash/list 分片）、拆值（压缩或结构化拆分）、写入限流、最大值约束与拦截。

### 热点键
- 危害：单点瓶颈、QPS/Jitter、网络与内存抖动。
- 治理：读写分摊（副本读）、本地缓存（Caffeine/Guava）、客户端批量与合并、Key 前后缀随机化（防止哈希冲突）。

### 过期风暴
- 原因：大量键同一 TTL，过期瞬间清理+回源打满。
- 治理：TTL 加随机抖动、分层缓存、异步预热、后台刷新、写时分批设置 TTL。

## 监控与诊断
- 指标：used_memory{_rss,_peak}、fragmentation、evicted_keys、expired_keys、keyspace_hits/misses、latency-spike。
- 工具：
  - MEMORY {USAGE,STATS,MALLOC-STATS}、LATENCY DOCTOR、SLOWLOG。
  - 采样：RDB/AOF 大小变化、主从延迟、复制积压缓冲区水位。

## 实践与优化建议
- 选择 jemalloc，观察碎片率与延迟曲线；生产上开启适度 active-defrag，避开高峰。
- 采用 LFU 作为淘汰策略对抗瞬时热点；设置合理的衰减时间。
- 控制 value 大小与结构编码阈值，利用小对象压缩结构（listpack/ziplist）。
- TTL 策略加入随机抖动，避免“整点效应”。
- 关键路径命令优化：避免 KEYS、避免多键大扫描，使用 SCAN；
- 备份/迁移前探测大键，提前拆分与压缩。

## Redis关联的其它知识
- 与缓存架构设计的关系：淘汰策略与回源策略耦合，见《F02-缓存架构设计》。
- 与高并发系统：热点治理与限流熔断策略联动，见《F03-高并发系统设计》。

 