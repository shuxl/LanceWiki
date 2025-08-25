如果你比较熟悉 MySQL，在切换到 **OceanBase（MySQL 兼容模式）** 开发时，整体学习成本不会很高，但有几个关键差异需要特别注意，否则在企业环境中可能踩坑。

我帮你分成 **SQL/功能差异**、**性能与架构差异**、**开发和调优注意点** 三个方面整理。

---

## **1. SQL 与功能差异**

  

虽然 OceanBase MySQL 模式兼容 MySQL 5.7 协议，但它并不是 MySQL 内核，所以底层实现和部分特性不一样。

|**类别**|**MySQL**|**OceanBase MySQL 模式**|**注意点**|
|---|---|---|---|
|数据类型|全部 MySQL 5.7 类型|大部分兼容，但部分类型长度限制不同|TEXT/BLOB 最大长度限制不同；DECIMAL 精度范围要确认|
|自增主键|AUTO_INCREMENT 单机生成|分布式生成，可能不是连续递增|不要依赖连续性做业务逻辑|
|分区表|MySQL 有 PARTITION，但使用较少|OceanBase 默认使用分区存储|需要了解 HASH / RANGE 分区策略，影响 SQL 路由|
|函数|MySQL 所有函数|大部分支持，部分函数行为不同|如 NOW() 默认返回 UTC，需要调整时区|
|DDL|MySQL ALTER 较快（单机元数据）|分布式 DDL 较慢（全局同步）|频繁 DDL 会影响性能|
|存储过程/触发器|完全支持|部分版本支持有限|如果依赖大量存储过程，需要提前验证|

---

## **2. 性能与架构差异**

  

OceanBase 是 **分布式数据库**，你的 SQL 会在多个节点间路由执行，这和 MySQL 单机或主从模式很不一样。

1. **跨分区查询**
    
    - 如果查询的条件没有命中分区键，会触发跨分区查询（Distributed Execution），性能会比单分区查询慢。
        
    - 开发时要了解分区键设计，尤其在大表和高并发业务里很关键。
        
    
2. **主键选择**
    
    - OceanBase 会自动将主键作为分区键（默认 HASH 分区），这影响数据分布和访问性能。
        
    - 如果业务查询经常不走主键，要考虑二级索引和全局索引。
        
    
3. **事务代价**
    
    - OceanBase 支持分布式事务（Paxos + 2PC），但跨分区事务比单分区事务慢。
        
    - 在业务上尽量把事务范围限定在一个分区内。
        
    
4. **JOIN 策略**
    
    - 多表 JOIN 如果不在同一个分区，会触发数据重分发（Data Shuffle），代价很高。
        
    - 能用本地 JOIN（同分区 JOIN）尽量用本地 JOIN。
        
    

---

## **3. 开发与调优注意点**

1. **连接配置**
    
    - JDBC URL 尽量加 rewriteBatchedStatements=true、useServerPrepStmts=true 以提升批量插入性能。
        
    
2. **时区问题**
    
    - OceanBase 默认 UTC，需要在 JDBC URL 或会话中设置 serverTimezone=Asia/Shanghai。
        
    
3. **批量写入**
    
    - OceanBase 分布式事务开销比 MySQL 大，所以批量插入要合并成大事务，减少 commit 次数。
        
    
4. **索引策略**
    
    - OceanBase 索引是全局/本地两种，和 MySQL 单机索引不同，二级索引的代价和路由要特别关注。
        
    
5. **监控与调优**
    
    - OceanBase 有自己的一套系统表（oceanbase.*、gv$*），调优时需要学会看执行计划（EXPLAIN EXTENDED）和监控指标。
        
    

---

## **总结建议**

  

如果你是 MySQL 老手，在切换到 OceanBase 时建议的适应步骤是：

1. **先在 MySQL 模式下用熟悉的 MySQL 工具链跑起来**（MySQL 驱动、MyBatis/JPA、常规 SQL）。
    
2. **学习分布式特性**（分区、路由、跨分区事务）——这是最大差别。
    
3. **基于业务特点调整表结构与索引设计**，尽量减少跨分区操作。
    
4. **熟悉 OceanBase 系统表和调优工具**，替代你在 MySQL 里的 information_schema 和慢查询分析。
    