# 简介
+ 反转控制

# 主要实现策略
+ 依赖查找
+ 依赖注入

# IoC容器职责
+ 依赖处理
    - 依赖查找
    - 依赖注入
+ 生命周期管理
    - 容器
    - 托管的资源（Java Beans 或 其它的资源）
+ 配置
    - 容器
    - 外部化配置
    - 托管的资源（Java Beans 或 其它的资源）

# IoC 容器的实现
+ Java SE 
    - Java Beans 
    - Java ServiceLoader SPI 
    - JNDI（Java Naming and Directory Interface） 
+ Java EE 
    - EJB（Enterprise Java Beans） 
    - Servlet 
+ 开源
    - Apache Avalon（http://avalon.apache.org/closed.html） 
    - PicoContainer（http://picocontainer.com/） 
    - Google Guice（https://github.com/google/guice） 
    - Spring Framework（https://spring.io/projects/spring-framework）