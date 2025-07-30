 # Spring Boot自动配置

## 重点内容
- Spring Boot自动配置的核心原理和机制
- @EnableAutoConfiguration注解的作用和实现
- 条件注解的使用和自定义条件
- 自动配置类的编写和注册
- 配置文件优先级和属性绑定机制

## Spring Boot自动配置概念或介绍

Spring Boot自动配置是Spring Boot框架的核心特性之一，它能够根据项目的依赖和配置自动配置Spring应用。通过自动配置，开发者可以快速搭建应用而无需编写大量的配置代码。

### 自动配置的优势
1. **简化配置**：减少样板代码，专注于业务逻辑
2. **约定优于配置**：提供合理的默认配置
3. **可定制性**：支持通过配置文件或注解进行定制
4. **条件化配置**：根据环境自动选择配置

### 自动配置的工作原理
Spring Boot通过以下步骤实现自动配置：
1. 扫描classpath中的依赖
2. 读取META-INF/spring.factories文件
3. 根据条件注解决定是否启用配置
4. 创建和配置Bean

## 底层原理

### 关键类和接口

#### @EnableAutoConfiguration注解
```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
    // ...
}
```

#### AutoConfigurationImportSelector类
```java
public class AutoConfigurationImportSelector implements DeferredImportSelector, BeanClassLoaderAware,
        ResourceLoaderAware, BeanFactoryAware, EnvironmentAware, Ordered {
    
    @Override
    public String[] selectImports(AnnotationMetadata annotationMetadata) {
        // 获取自动配置类
        AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
                .loadMetadata(this.beanClassLoader);
        AutoConfigurationEntry autoConfigurationEntry = getAutoConfigurationEntry(
                autoConfigurationMetadata, annotationMetadata);
        return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
    }
}
```

#### 条件注解体系
```java
// 核心条件注解
@ConditionalOnClass
@ConditionalOnMissingClass
@ConditionalOnBean
@ConditionalOnMissingBean
@ConditionalOnProperty
@ConditionalOnResource
@ConditionalOnWebApplication
@ConditionalOnNotWebApplication
```

### 关键类图

```
@SpringBootApplication
    ↓
@EnableAutoConfiguration
    ↓
AutoConfigurationImportSelector
    ↓
SpringFactoriesLoader.loadFactoryNames()
    ↓
META-INF/spring.factories
    ↓
AutoConfigurationClasses
    ↓
@Conditional注解判断
    ↓
BeanDefinition注册
```

### 核心代码讲解

#### 1. spring.factories文件结构
```properties
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
```

#### 2. 自动配置类示例
```java
@Configuration
@ConditionalOnClass({DataSource.class, EmbeddedDatabaseType.class})
@EnableConfigurationProperties(DataSourceProperties.class)
@Import({DataSourcePoolMetadataProvidersConfiguration.class, 
        DataSourceInitializationConfiguration.class})
public class DataSourceAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    public DataSource dataSource(DataSourceProperties properties) {
        // 创建数据源
        return properties.initializeDataSourceBuilder().build();
    }
}
```

#### 3. 条件注解使用示例
```java
@Configuration
@ConditionalOnClass(name = "org.springframework.data.redis.core.RedisTemplate")
@ConditionalOnProperty(prefix = "spring.redis", name = "host")
public class RedisAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        return template;
    }
}
```

### 设计思想

#### 1. 约定优于配置
Spring Boot遵循"约定优于配置"的设计原则，提供合理的默认配置，同时允许开发者进行定制。

#### 2. 条件化配置
通过条件注解实现智能配置，只在满足特定条件时才启用相应的自动配置。

#### 3. 可扩展性
通过spring.factories机制，第三方库可以轻松集成到Spring Boot的自动配置体系中。

## 自定义自动配置

### 创建自动配置类
```java
@Configuration
@ConditionalOnClass(MyService.class)
@EnableConfigurationProperties(MyServiceProperties.class)
public class MyServiceAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    public MyService myService(MyServiceProperties properties) {
        return new MyService(properties);
    }
}
```

### 注册自动配置
在META-INF/spring.factories中添加：
```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.MyServiceAutoConfiguration
```

### 配置属性类
```java
@ConfigurationProperties(prefix = "my.service")
public class MyServiceProperties {
    private String name = "default";
    private int timeout = 30;
    
    // getters and setters
}
```

## 配置文件优先级

Spring Boot配置文件的加载优先级（从高到低）：
1. 命令行参数
2. 系统环境变量
3. application-{profile}.properties/yml
4. application.properties/yml
5. @ConfigurationProperties注解的默认值

## 属性绑定机制

### @ConfigurationProperties注解
```java
@ConfigurationProperties(prefix = "app.config")
public class AppConfig {
    private String name;
    private List<String> features;
    private Map<String, String> settings;
    
    // getters and setters
}
```

### 配置文件示例
```yaml
app:
  config:
    name: "My Application"
    features:
      - "feature1"
      - "feature2"
    settings:
      key1: "value1"
      key2: "value2"
```

## 调试自动配置

### 启用调试模式
```properties
# application.properties
debug=true
logging.level.org.springframework.boot.autoconfigure=DEBUG
```

### 查看自动配置报告
启动应用时添加`--debug`参数：
```bash
java -jar myapp.jar --debug
```

## Spring Boot自动配置关联的其它知识

### 1. Spring Framework核心概念
- [Spring IoC容器](../0101-Spring%20IoC容器.md)
- [Spring Bean生命周期](../0102-Spring%20Bean生命周期.md)
- [Spring依赖注入](../0103-Spring依赖注入.md)

### 2. 配置管理
- [Spring Boot配置管理](0703-Spring%20Boot配置管理.md)
- [Spring Boot启动原理](0702-Spring%20Boot启动原理.md)

### 3. 条件化配置
- [Spring条件注解](../0104-Spring条件注解.md)
- [Spring Profile配置](../0105-Spring%20Profile配置.md)

### 4. 扩展开发
- [Spring Boot监控](0704-Spring%20Boot监控.md)
- [Spring Boot自定义Starter](../0106-Spring%20Boot自定义Starter.md)

### 5. 相关技术
- [Maven依赖管理](../../400-开发工具/420-maven/maven%20命令.md)
- [Java注解机制](../old/100-Java基础-old/基础/注解.md)
- [Java反射机制](../../100-java/100-Java基础/反射/反射.md)