# A02 - MyBatis安装配置

## 重点内容

- Maven依赖配置详解
- Spring Boot集成配置
- XML配置文件结构分析
- 环境配置和数据库连接配置
- 日志配置和调试配置

## 1. Maven依赖配置详解

### 1.1 基础依赖配置

```xml
<!-- MyBatis核心依赖 -->
<dependency>
    <groupId>org.mybatis</groupId>
    <artifactId>mybatis</artifactId>
    <version>3.5.13</version>
</dependency>

<!-- MyBatis与Spring集成 -->
<dependency>
    <groupId>org.mybatis</groupId>
    <artifactId>mybatis-spring</artifactId>
    <version>2.1.1</version>
</dependency>

<!-- MyBatis与Spring Boot集成 -->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.3.1</version>
</dependency>
```

### 1.2 数据库驱动依赖

```xml
<!-- MySQL驱动 -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.33</version>
</dependency>

<!-- PostgreSQL驱动 -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.6.0</version>
</dependency>

<!-- Oracle驱动 -->
<dependency>
    <groupId>com.oracle.database.jdbc</groupId>
    <artifactId>ojdbc8</artifactId>
    <version>21.9.0.0</version>
</dependency>
```

### 1.3 连接池依赖

```xml
<!-- HikariCP连接池（推荐） -->
<dependency>
    <groupId>com.zaxxer</groupId>
    <artifactId>HikariCP</artifactId>
    <version>5.0.1</version>
</dependency>

<!-- Druid连接池 -->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>druid-spring-boot-starter</artifactId>
    <version>1.2.18</version>
</dependency>
```

## 2. Spring Boot集成配置

### 2.1 自动配置原理

Spring Boot通过`@EnableAutoConfiguration`注解自动配置MyBatis，主要涉及以下自动配置类：

```java
// MyBatisAutoConfiguration - MyBatis自动配置类
@Configuration
@ConditionalOnClass({SqlSessionFactory.class, SqlSessionFactoryBean.class})
@ConditionalOnSingleCandidate(DataSource.class)
@EnableConfigurationProperties(MybatisProperties.class)
@AutoConfigureAfter({DataSourceAutoConfiguration.class, MybatisLanguageDriverAutoConfiguration.class})
public class MyBatisAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        // 自动创建SqlSessionFactory
    }
    
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionTemplate sqlSessionTemplate(SqlSessionFactory sqlSessionFactory) {
        // 自动创建SqlSessionTemplate
    }
}
```

### 2.2 application.yml配置

```yaml
# 数据源配置
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/mybatis_demo?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: 123456
    # HikariCP连接池配置
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 300000
      max-lifetime: 1200000
      connection-timeout: 20000

# MyBatis配置
mybatis:
  # 映射文件位置
  mapper-locations: classpath:mapper/*.xml
  # 类型别名包路径
  type-aliases-package: com.example.entity
  # 配置文件位置
  config-location: classpath:mybatis-config.xml
  # 全局配置
  configuration:
    # 开启驼峰命名转换
    map-underscore-to-camel-case: true
    # 开启延迟加载
    lazy-loading-enabled: true
    # 开启二级缓存
    cache-enabled: true
    # 日志实现
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
```

### 2.3 启动类配置

```java
@SpringBootApplication
@MapperScan("com.example.mapper") // 扫描Mapper接口
public class MybatisApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(MybatisApplication.class, args);
    }
}
```

## 3. XML配置文件结构分析

### 3.1 mybatis-config.xml配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN" 
    "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    
    <!-- 全局设置 -->
    <settings>
        <!-- 开启驼峰命名转换 -->
        <setting name="mapUnderscoreToCamelCase" value="true"/>
        <!-- 开启延迟加载 -->
        <setting name="lazyLoadingEnabled" value="true"/>
        <!-- 开启二级缓存 -->
        <setting name="cacheEnabled" value="true"/>
        <!-- 日志实现 -->
        <setting name="logImpl" value="STDOUT_LOGGING"/>
    </settings>
    
    <!-- 类型别名 -->
    <typeAliases>
        <package name="com.example.entity"/>
    </typeAliases>
    
    <!-- 类型处理器 -->
    <typeHandlers>
        <typeHandler handler="com.example.handler.JsonTypeHandler"/>
    </typeHandlers>
    
    <!-- 环境配置 -->
    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC"/>
            <dataSource type="POOLED">
                <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
                <property name="url" value="jdbc:mysql://localhost:3306/mybatis_demo"/>
                <property name="username" value="root"/>
                <property name="password" value="123456"/>
            </dataSource>
        </environment>
    </environments>
    
    <!-- 映射器 -->
    <mappers>
        <mapper resource="mapper/UserMapper.xml"/>
        <package name="com.example.mapper"/>
    </mappers>
    
</configuration>
```

### 3.2 配置文件解析机制

MyBatis使用XML解析器解析配置文件，主要涉及以下类：

```java
// XMLConfigBuilder - 配置文件构建器
public class XMLConfigBuilder extends BaseBuilder {
    
    public Configuration parse() {
        if (parsed) {
            throw new BuilderException("Each XMLConfigBuilder can only be used once.");
        }
        parsed = true;
        parseConfiguration(parser.evalNode("/configuration"));
        return configuration;
    }
    
    private void parseConfiguration(XNode root) {
        try {
            // 解析properties
            propertiesElement(root.evalNode("properties"));
            // 解析settings
            settingsElement(root.evalNode("settings"));
            // 解析typeAliases
            typeAliasesElement(root.evalNode("typeAliases"));
            // 解析plugins
            pluginElement(root.evalNode("plugins"));
            // 解析objectFactory
            objectFactoryElement(root.evalNode("objectFactory"));
            // 解析objectWrapperFactory
            objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
            // 解析reflectorFactory
            reflectorFactoryElement(root.evalNode("reflectorFactory"));
            // 解析environments
            environmentsElement(root.evalNode("environments"));
            // 解析databaseIdProvider
            databaseIdProviderElement(root.evalNode("databaseIdProvider"));
            // 解析mappers
            mapperElement(root.evalNode("mappers"));
        } catch (Exception e) {
            throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + e, e);
        }
    }
}
```

## 4. 环境配置和数据库连接配置

### 4.1 多环境配置

```xml
<environments default="development">
    <!-- 开发环境 -->
    <environment id="development">
        <transactionManager type="JDBC"/>
        <dataSource type="POOLED">
            <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
            <property name="url" value="jdbc:mysql://localhost:3306/mybatis_dev"/>
            <property name="username" value="dev_user"/>
            <property name="password" value="dev_pass"/>
            <property name="poolMaximumActiveConnections" value="10"/>
            <property name="poolMaximumIdleConnections" value="5"/>
        </dataSource>
    </environment>
    
    <!-- 测试环境 -->
    <environment id="test">
        <transactionManager type="JDBC"/>
        <dataSource type="POOLED">
            <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
            <property name="url" value="jdbc:mysql://test-server:3306/mybatis_test"/>
            <property name="username" value="test_user"/>
            <property name="password" value="test_pass"/>
        </dataSource>
    </environment>
    
    <!-- 生产环境 -->
    <environment id="production">
        <transactionManager type="JDBC"/>
        <dataSource type="POOLED">
            <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
            <property name="url" value="jdbc:mysql://prod-server:3306/mybatis_prod"/>
            <property name="username" value="prod_user"/>
            <property name="password" value="prod_pass"/>
        </dataSource>
    </environment>
</environments>
```

### 4.2 数据源类型

MyBatis支持三种数据源类型：

```java
// UNPOOLED - 不使用连接池
public class UnpooledDataSource implements DataSource {
    // 每次请求都创建新的连接
}

// POOLED - 使用连接池
public class PooledDataSource implements DataSource {
    // 使用连接池管理连接
}

// JNDI - 使用JNDI数据源
public class JndiDataSourceFactory implements DataSourceFactory {
    // 从JNDI容器获取数据源
}
```

### 4.3 连接池配置详解

```xml
<dataSource type="POOLED">
    <!-- 基本配置 -->
    <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
    <property name="url" value="jdbc:mysql://localhost:3306/mybatis_demo"/>
    <property name="username" value="root"/>
    <property name="password" value="123456"/>
    
    <!-- 连接池配置 -->
    <property name="poolMaximumActiveConnections" value="20"/>
    <property name="poolMaximumIdleConnections" value="10"/>
    <property name="poolMaximumCheckoutTime" value="20000"/>
    <property name="poolTimeToWait" value="20000"/>
    <property name="poolMaximumLocalBadConnectionTolerance" value="3"/>
    <property name="poolPingQuery" value="SELECT 1"/>
    <property name="poolPingEnabled" value="true"/>
    <property name="poolPingConnectionsNotUsedFor" value="3600000"/>
</dataSource>
```

## 5. 日志配置和调试配置

### 5.1 日志实现配置

MyBatis支持多种日志实现：

```xml
<settings>
    <!-- 标准输出日志 -->
    <setting name="logImpl" value="STDOUT_LOGGING"/>
    
    <!-- 或者使用SLF4J -->
    <!-- <setting name="logImpl" value="SLF4J"/> -->
    
    <!-- 或者使用Log4j -->
    <!-- <setting name="logImpl" value="LOG4J"/> -->
    
    <!-- 或者使用Log4j2 -->
    <!-- <setting name="logImpl" value="LOG4J2"/> -->
    
    <!-- 或者使用JDK日志 -->
    <!-- <setting name="logImpl" value="JDK_LOGGING"/> -->
    
    <!-- 或者使用Commons Logging -->
    <!-- <setting name="logImpl" value="COMMONS_LOGGING"/> -->
    
    <!-- 或者使用No Logging -->
    <!-- <setting name="logImpl" value="NO_LOGGING"/> -->
</settings>
```

### 5.2 Log4j配置示例

```properties
# log4j.properties
log4j.rootLogger=DEBUG, stdout

log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%5p [%t] - %m%n

# MyBatis日志配置
log4j.logger.com.example.mapper=DEBUG
log4j.logger.org.apache.ibatis=DEBUG
```

### 5.3 调试配置

```yaml
# application.yml
mybatis:
  configuration:
    # 开启SQL日志
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
    # 开启延迟加载
    lazy-loading-enabled: true
    # 开启积极延迟加载
    aggressive-lazy-loading: false
    # 开启自动映射
    auto-mapping-behavior: PARTIAL
    # 开启自动映射未知列
    auto-mapping-unknown-column-behavior: WARNING
    # 开启默认执行器类型
    default-executor-type: SIMPLE
    # 开启默认语句超时时间
    default-statement-timeout: 30
    # 开启默认获取结果集大小
    default-fetch-size: 100
    # 开启默认滚动
    default-result-set-type: DEFAULT
    # 开启安全行边界
    safe-row-bounds-enabled: false
    # 开启安全结果处理器
    safe-result-handler-enabled: true
    # 开启映射下划线到驼峰
    map-underscore-to-camel-case: true
    # 开启本地缓存作用域
    local-cache-scope: SESSION
    # 开启JdbcType为空时的处理
    jdbc-type-for-null: OTHER
    # 开启延迟加载触发方法
    lazy-load-trigger-methods: equals,clone,hashCode,toString
    # 开启调用setter方法
    call-setters-on-nulls: false
    # 开启返回值类型
    return-instance-for-empty-row: false
    # 开启日志前缀
    log-prefix: MyBatis
```

## 6. 配置加载的优先级

MyBatis配置加载的优先级如下：

1. **Spring Boot自动配置**：最高优先级
2. **application.yml/properties**：次高优先级
3. **mybatis-config.xml**：中等优先级
4. **代码配置**：最低优先级

```java
// 配置优先级示例
@Configuration
public class MybatisConfig {
    
    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean factory = new SqlSessionFactoryBean();
        factory.setDataSource(dataSource);
        
        // 代码配置（最低优先级）
        org.apache.ibatis.session.Configuration configuration = 
            new org.apache.ibatis.session.Configuration();
        configuration.setMapUnderscoreToCamelCase(true);
        configuration.setCacheEnabled(true);
        factory.setConfiguration(configuration);
        
        return factory.getObject();
    }
}
```

## 7. 注意事项

1. **版本兼容性**：确保MyBatis、Spring、数据库驱动版本兼容
2. **连接池选择**：生产环境推荐使用HikariCP或Druid
3. **配置优先级**：了解配置加载优先级，避免配置冲突
4. **日志级别**：生产环境建议关闭SQL日志，避免性能影响
5. **数据源配置**：合理配置连接池参数，避免连接泄露
6. **环境隔离**：使用不同配置文件管理不同环境

## 8. 关联的其它知识

- [MyBatis概念和基础](A01-MyBatis概念和基础.md)
- [MyBatis核心组件](A03-MyBatis核心组件.md)
- [MyBatis XML配置详解](B01-MyBatis%20XML配置详解.md)
- [Spring Boot集成MyBatis](../200-Spring/Spring%20Boot集成MyBatis.md)
- [数据库连接池](../300-中间件/数据库连接池.md)
