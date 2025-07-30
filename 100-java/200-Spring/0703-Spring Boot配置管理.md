# Spring Boot配置管理

## 重点内容
- Spring Boot配置文件的加载顺序和优先级
- 配置属性的绑定机制和@ConfigurationProperties注解
- 环境配置和Profile机制
- 外部化配置和配置源
- 配置加密和安全性
- 配置验证和类型转换

## Spring Boot配置管理概念或介绍

Spring Boot配置管理是Spring Boot框架中负责管理应用配置的核心机制。它提供了灵活、强大的配置管理能力，支持多种配置源、环境隔离、配置验证等功能。通过统一的配置管理，开发者可以轻松管理不同环境的配置，实现配置的外部化和动态化。

### 配置管理的特点
1. **外部化配置**：支持从外部文件、环境变量、命令行参数等加载配置
2. **环境隔离**：通过Profile机制实现不同环境的配置隔离
3. **类型安全**：支持强类型配置属性绑定
4. **配置验证**：提供配置验证和错误提示
5. **动态刷新**：支持配置的动态刷新（配合Spring Cloud）

## 底层原理

### 关键类和接口

#### ConfigurationPropertiesBindingPostProcessor
```java
public class ConfigurationPropertiesBindingPostProcessor implements BeanFactoryPostProcessor, PriorityOrdered {
    
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        // 处理@ConfigurationProperties注解的Bean
        Set<String> names = getNames(beanFactory);
        for (String name : names) {
            try {
                bindConfigurationProperties(beanFactory, name);
            } catch (Exception ex) {
                // 处理绑定异常
            }
        }
    }
    
    private void bindConfigurationProperties(ConfigurableListableBeanFactory beanFactory, String name) {
        BeanDefinition beanDefinition = beanFactory.getBeanDefinition(name);
        ConfigurationProperties annotation = getAnnotation(beanDefinition, ConfigurationProperties.class);
        if (annotation != null) {
            // 执行属性绑定
            bind(beanFactory, name, annotation);
        }
    }
}
```

#### ConfigurationPropertiesBindingPostProcessor
```java
public class ConfigurationPropertiesBindingPostProcessor implements BeanFactoryPostProcessor, PriorityOrdered {
    
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        // 处理@ConfigurationProperties注解的Bean
        Set<String> names = getNames(beanFactory);
        for (String name : names) {
            try {
                bindConfigurationProperties(beanFactory, name);
            } catch (Exception ex) {
                // 处理绑定异常
            }
        }
    }
    
    private void bindConfigurationProperties(ConfigurableListableBeanFactory beanFactory, String name) {
        BeanDefinition beanDefinition = beanFactory.getBeanDefinition(name);
        ConfigurationProperties annotation = getAnnotation(beanDefinition, ConfigurationProperties.class);
        if (annotation != null) {
            // 执行属性绑定
            bind(beanFactory, name, annotation);
        }
    }
}
```

#### PropertySourcesLoader
```java
public class PropertySourcesLoader {
    
    public static PropertySourcesLoader load(Resource resource) throws IOException {
        PropertySourcesLoader loader = new PropertySourcesLoader();
        loader.load(resource);
        return loader;
    }
    
    public void load(Resource resource) throws IOException {
        String filename = resource.getFilename();
        if (filename != null && filename.endsWith(".yml")) {
            loadYaml(resource);
        } else {
            loadProperties(resource);
        }
    }
    
    private void loadYaml(Resource resource) throws IOException {
        YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
        factory.setResources(resource);
        factory.afterPropertiesSet();
        Properties properties = factory.getObject();
        // 添加到PropertySources
        addPropertySource(resource, properties);
    }
}
```

### 关键类图

```
ConfigurationPropertiesBindingPostProcessor
    ↓
ConfigurationPropertiesBinder
    ↓
ConfigurationPropertiesBindingPostProcessor
    ↓
PropertySourcesLoader
    ↓
PropertySource
    ↓
Environment
    ↓
ApplicationContext
```

### 核心代码讲解

#### 1. 配置属性绑定
```java
@ConfigurationProperties(prefix = "app.config")
public class AppConfig {
    
    private String name;
    private int port = 8080;
    private List<String> features = new ArrayList<>();
    private Map<String, String> settings = new HashMap<>();
    
    // getters and setters
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public int getPort() {
        return port;
    }
    
    public void setPort(int port) {
        this.port = port;
    }
    
    public List<String> getFeatures() {
        return features;
    }
    
    public void setFeatures(List<String> features) {
        this.features = features;
    }
    
    public Map<String, String> getSettings() {
        return settings;
    }
    
    public void setSettings(Map<String, String> settings) {
        this.settings = settings;
    }
}
```

#### 2. 配置验证
```java
@ConfigurationProperties(prefix = "app.config")
@Validated
public class AppConfig {
    
    @NotBlank(message = "应用名称不能为空")
    private String name;
    
    @Min(value = 1, message = "端口号必须大于0")
    @Max(value = 65535, message = "端口号不能超过65535")
    private int port = 8080;
    
    @Size(min = 1, message = "至少需要一个特性")
    private List<String> features = new ArrayList<>();
    
    // getters and setters
}
```

#### 3. 配置转换器
```java
@Component
public class CustomConverter implements Converter<String, CustomType> {
    
    @Override
    public CustomType convert(String source) {
        // 自定义转换逻辑
        return new CustomType(source);
    }
}
```

### 设计思想

#### 1. 外部化配置
将配置从代码中分离，支持从外部文件、环境变量等加载配置。

#### 2. 类型安全
通过强类型绑定，提供编译时类型检查和运行时类型转换。

#### 3. 环境隔离
通过Profile机制，实现不同环境的配置隔离和管理。

#### 4. 配置验证
提供配置验证机制，确保配置的正确性和完整性。

## 配置文件加载顺序

### 配置源优先级（从高到低）
1. **命令行参数**
   ```bash
   java -jar app.jar --server.port=9090
   ```

2. **系统环境变量**
   ```bash
   export SERVER_PORT=9090
   ```

3. **操作系统环境变量**
   ```bash
   set SERVER_PORT=9090
   ```

4. **配置文件（按优先级）**
   - `application-{profile}.properties/yml`
   - `application.properties/yml`
   - `application-{profile}.properties/yml`（classpath外）
   - `application.properties/yml`（classpath外）

5. **@ConfigurationProperties注解的默认值**

### 配置文件示例

#### application.yml
```yaml
spring:
  profiles:
    active: dev
  application:
    name: my-application

server:
  port: 8080

app:
  config:
    name: "My Application"
    port: 8080
    features:
      - "feature1"
      - "feature2"
    settings:
      key1: "value1"
      key2: "value2"
```

#### application-dev.yml
```yaml
server:
  port: 8081

app:
  config:
    name: "My Application (Dev)"
    settings:
      debug: "true"
```

#### application-prod.yml
```yaml
server:
  port: 80

app:
  config:
    name: "My Application (Prod)"
    settings:
      debug: "false"
```

## 配置属性绑定

### @ConfigurationProperties注解
```java
@ConfigurationProperties(prefix = "app.config")
@Component
public class AppConfig {
    
    @Value("${app.config.name:default}")
    private String name;
    
    @Value("${app.config.port:8080}")
    private int port;
    
    // 嵌套配置
    private Database database = new Database();
    
    public static class Database {
        private String url;
        private String username;
        private String password;
        
        // getters and setters
    }
    
    // getters and setters
}
```

### 配置属性验证
```java
@ConfigurationProperties(prefix = "app.config")
@Validated
public class AppConfig {
    
    @NotBlank(message = "应用名称不能为空")
    private String name;
    
    @Min(value = 1, message = "端口号必须大于0")
    @Max(value = 65535, message = "端口号不能超过65535")
    private int port;
    
    @Valid
    private Database database;
    
    @ConfigurationProperties(prefix = "app.config.database")
    @Validated
    public static class Database {
        
        @NotBlank(message = "数据库URL不能为空")
        private String url;
        
        @NotBlank(message = "数据库用户名不能为空")
        private String username;
        
        @NotBlank(message = "数据库密码不能为空")
        private String password;
        
        // getters and setters
    }
    
    // getters and setters
}
```

## 环境配置和Profile

### Profile激活
```properties
# application.properties
spring.profiles.active=dev
```

```yaml
# application.yml
spring:
  profiles:
    active: dev
```

### 命令行激活Profile
```bash
java -jar app.jar --spring.profiles.active=prod
```

### 环境变量激活Profile
```bash
export SPRING_PROFILES_ACTIVE=prod
```

### Profile特定配置
```yaml
# application-dev.yml
server:
  port: 8081
logging:
  level: DEBUG

# application-prod.yml
server:
  port: 80
logging:
  level: WARN
```

## 外部化配置

### 配置文件位置
Spring Boot按以下顺序查找配置文件：
1. `file:./config/`
2. `file:./`
3. `classpath:/config/`
4. `classpath:/`

### 自定义配置文件位置
```bash
java -jar app.jar --spring.config.location=classpath:/custom-config/
```

### 配置属性源
```java
@Configuration
public class CustomConfigSource {
    
    @Bean
    public PropertySource<?> customPropertySource() {
        Properties properties = new Properties();
        properties.setProperty("custom.property", "custom-value");
        return new PropertiesPropertySource("custom", properties);
    }
}
```

## 配置加密

### 使用Jasypt加密
```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.github.ulisesbocchio</groupId>
    <artifactId>jasypt-spring-boot-starter</artifactId>
    <version>3.0.5</version>
</dependency>
```

### 加密配置示例
```yaml
# application.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: ENC(encrypted-password)

jasypt:
  encryptor:
    password: my-secret-key
```

### 加密工具类
```java
@Component
public class EncryptionUtil {
    
    @Autowired
    private StringEncryptor encryptor;
    
    public String encrypt(String value) {
        return encryptor.encrypt(value);
    }
    
    public String decrypt(String encryptedValue) {
        return encryptor.decrypt(encryptedValue);
    }
}
```

## 配置验证

### 启用配置验证
```java
@SpringBootApplication
@EnableConfigurationProperties
public class MyApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

### 配置验证示例
```java
@ConfigurationProperties(prefix = "app.config")
@Validated
public class AppConfig {
    
    @NotBlank(message = "应用名称不能为空")
    private String name;
    
    @Min(value = 1, message = "端口号必须大于0")
    @Max(value = 65535, message = "端口号不能超过65535")
    private int port;
    
    @Pattern(regexp = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", 
             message = "邮箱格式不正确")
    private String email;
    
    // getters and setters
}
```

## 配置监控

### 配置变更监听
```java
@Component
public class ConfigurationChangeListener {
    
    @EventListener
    public void handleConfigurationChange(RefreshScopeRefreshedEvent event) {
        System.out.println("配置已刷新");
    }
}
```

### 配置属性监控
```java
@Component
public class ConfigurationMonitor {
    
    @Autowired
    private AppConfig appConfig;
    
    @EventListener
    public void handleApplicationReady(ApplicationReadyEvent event) {
        System.out.println("应用配置: " + appConfig);
    }
}
```

## Spring Boot配置管理关联的其它知识

### 1. Spring Framework核心
- [Spring IoC容器](../0101-Spring%20IoC容器.md)
- [Spring Bean生命周期](../0102-Spring%20Bean生命周期.md)
- [Spring依赖注入](../0103-Spring依赖注入.md)

### 2. Spring Boot核心
- [Spring Boot自动配置](0701-Spring%20Boot自动配置.md)
- [Spring Boot启动原理](0702-Spring%20Boot启动原理.md)
- [Spring Boot监控](0704-Spring%20Boot监控.md)

### 3. 配置相关
- [Spring Profile配置](../0105-Spring%20Profile配置.md)
- [Spring条件注解](../0104-Spring条件注解.md)

### 4. 安全相关
- [Spring Security基础](0801-Spring%20Security基础.md)
- [认证机制](0802-认证机制.md)

### 5. 相关技术
- [Java注解机制](../old/100-Java基础-old/基础/注解.md)
- [Java反射机制](../../100-java/100-Java基础/反射/反射.md)
- [YAML语法](../../200-python/python基础/01-python3%20基础语法.md) 