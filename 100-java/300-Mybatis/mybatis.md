# MyBatis知识大纲

## A. MyBatis基础概念
### [A01 - MyBatis概念和基础](A01-MyBatis概念和基础.md)
**核心内容概括：** MyBatis是一款优秀的持久层框架，它支持自定义SQL、存储过程以及高级映射。MyBatis避免了几乎所有的JDBC代码和手动设置参数以及获取结果集。MyBatis可以使用简单的XML或注解来配置和映射原生信息，将接口和Java的POJOs映射成数据库中的记录。

### [A02 - MyBatis安装配置](A02-MyBatis安装配置.md)
**核心内容概括：** MyBatis的Maven依赖配置，Spring Boot集成配置，XML配置文件详解，环境配置，数据源配置等。

### [A03 - MyBatis核心组件](A03-MyBatis核心组件.md)
**核心内容概括：** MyBatis的核心组件：SqlSessionFactory、SqlSession、Mapper接口、Executor、StatementHandler、ResultSetHandler、ParameterHandler等组件的职责和关系。

## B. MyBatis配置与映射
### [B01 - MyBatis XML配置详解](B01-MyBatis XML配置详解.md)
**核心内容概括：** MyBatis的XML配置文件结构，environments、settings、typeAliases、typeHandlers、objectFactory、plugins、mappers等配置项的详细说明。

### [B02 - MyBatis映射文件详解](B02-MyBatis映射文件详解.md)
**核心内容概括：** MyBatis映射文件的编写，select、insert、update、delete语句的配置，参数映射，结果映射，动态SQL等。

### [B03 - MyBatis注解配置详解](B03-MyBatis注解配置详解.md)
**核心内容概括：** MyBatis注解的使用，@Select、@Insert、@Update、@Delete、@Results、@Result、@One、@Many等注解的用法和最佳实践。

### [B04 - MyBatis动态SQL详解](B04-MyBatis动态SQL详解.md)
**核心内容概括：** MyBatis动态SQL的实现，if、choose、when、otherwise、trim、where、set、foreach等标签的使用，动态SQL的性能优化。

### [B05 - MyBatis类型处理器详解](B05-MyBatis类型处理器详解.md)
**核心内容概括：** MyBatis类型处理器的原理，内置类型处理器，自定义类型处理器的开发，枚举类型处理，JSON类型处理等。

## C. MyBatis核心机制
### [C01 - MyBatis执行器机制详解](C01-MyBatis执行器机制详解.md)
**核心内容概括：** MyBatis的三种执行器：SimpleExecutor、ReuseExecutor、BatchExecutor的实现原理，执行器的选择策略，一级缓存和二级缓存机制。

### [C02 - MyBatis缓存机制详解](C02-MyBatis缓存机制详解.md)
**核心内容概括：** MyBatis的一级缓存（SqlSession级别）和二级缓存（Mapper级别）的实现原理，缓存配置，缓存更新策略，分布式缓存集成。

### [C03 - MyBatis插件机制详解](C03-MyBatis插件机制详解.md)
**核心内容概括：** MyBatis插件（Interceptor）的开发原理，插件的拦截点，分页插件、性能监控插件、SQL打印插件等常用插件的实现。

### [C04 - MyBatis事务机制详解](C04-MyBatis事务机制详解.md)
**核心内容概括：** MyBatis与Spring事务的集成，事务管理器的配置，事务传播行为，事务隔离级别，事务回滚机制等。

### [C05 - MyBatis结果映射详解](C05-MyBatis结果映射详解.md)
**核心内容概括：** MyBatis的结果映射机制，自动映射，手动映射，关联映射（一对一、一对多、多对多），延迟加载等。

## D. MyBatis高级特性
### [D01 - MyBatis分页查询详解](D01-MyBatis分页查询详解.md)
**核心内容概括：** MyBatis分页查询的实现方式，RowBounds分页，分页插件（PageHelper）的使用，分页性能优化，大数据量分页处理。

### [D02 - MyBatis批量操作详解](D02-MyBatis批量操作详解.md)
**核心内容概括：** MyBatis批量插入、批量更新、批量删除的实现，BatchExecutor的使用，批量操作的性能优化和注意事项。

### [D03 - MyBatis多数据源配置](D03-MyBatis多数据源配置.md)
**核心内容概括：** MyBatis多数据源的配置方案，动态数据源切换，读写分离配置，分库分表的数据源管理。

### [D04 - MyBatis代码生成器](D04-MyBatis代码生成器.md)
**核心内容概括：** MyBatis Generator的使用，代码生成器的配置，自定义代码生成模板，逆向工程的最佳实践。

### [D05 - MyBatis性能优化](D05-MyBatis性能优化.md)
**核心内容概括：** MyBatis性能优化的各个方面：SQL优化、缓存优化、连接池优化、批量操作优化、延迟加载优化等。

## E. MyBatis应用实践
### [E01 - MyBatis与Spring Boot集成](E01-MyBatis与Spring Boot集成.md)
**核心内容概括：** MyBatis与Spring Boot的集成配置，自动配置原理，多数据源配置，事务管理，监控和日志配置。

### [E02 - MyBatis最佳实践](E02-MyBatis最佳实践.md)
**核心内容概括：** MyBatis开发中的最佳实践，命名规范，SQL编写规范，映射文件组织，性能优化建议等。

### [E03 - MyBatis常见问题解决](E03-MyBatis常见问题解决.md)
**核心内容概括：** MyBatis使用中的常见问题和解决方案，N+1查询问题，缓存问题，事务问题，性能问题等。

### [E04 - MyBatis监控与调试](E04-MyBatis监控与调试.md)
**核心内容概括：** MyBatis的监控工具，SQL日志打印，性能监控，慢查询分析，调试技巧等。

### [E05 - MyBatis版本特性详解](E05-MyBatis版本特性详解.md)
**核心内容概括：** MyBatis各版本的新特性、改进和重要更新，版本升级指南，兼容性说明等。

## F. MyBatis底层原理
### [F01 - MyBatis源码分析](F01-MyBatis源码分析.md)
**核心内容概括：** MyBatis核心模块的源码分析，关键类的设计原理，执行流程分析，设计思想和架构模式。

### [F02 - MyBatis设计模式](F02-MyBatis设计模式.md)
**核心内容概括：** MyBatis中使用的设计模式，建造者模式、代理模式、模板方法模式、策略模式等在MyBatis中的应用。

### [F03 - MyBatis反射机制](F03-MyBatis反射机制.md)
**核心内容概括：** MyBatis中反射机制的使用，参数映射、结果映射、类型转换等场景中反射的应用原理。

### [F04 - MyBatis动态代理](F04-MyBatis动态代理.md)
**核心内容概括：** MyBatis中动态代理的实现原理，Mapper接口的代理机制，代理对象的创建和执行过程。

### [F05 - MyBatis解析器机制](F05-MyBatis解析器机制.md)
**核心内容概括：** MyBatis的XML解析机制，配置文件的解析过程，映射文件的解析，动态SQL的解析和构建。

## G. MyBatis关联的其它知识
### [G01 - ORM框架对比](G01-ORM框架对比.md)
**核心内容概括：** MyBatis与Hibernate、JPA、MyBatis-Plus等ORM框架的对比分析，适用场景，选择建议等。

### [G02 - 数据库连接池](G02-数据库连接池.md)
**核心内容概括：** 数据库连接池的原理，Druid、HikariCP、C3P0等连接池的特点，与MyBatis的集成配置。

### [G03 - SQL优化技术](G03-SQL优化技术.md)
**核心内容概括：** SQL优化的基本原则，索引优化，查询优化，执行计划分析，与MyBatis相关的SQL优化技巧。

### [G04 - 分布式事务](G04-分布式事务.md)
**核心内容概括：** 分布式事务的理论基础，2PC、3PC、TCC、Saga等分布式事务模式，与MyBatis多数据源场景的结合。

### [G05 - 微服务数据架构](G05-微服务数据架构.md)
**核心内容概括：** 微服务架构下的数据管理策略，数据一致性，数据分片，读写分离，与MyBatis在微服务中的应用。
