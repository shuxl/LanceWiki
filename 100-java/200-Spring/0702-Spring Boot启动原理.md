# Spring Boot启动原理

## 重点内容
- Spring Boot应用启动的完整流程
- @SpringBootApplication注解的组成和作用
- SpringApplication类的核心方法分析
- 启动器（Starter）机制和自动配置原理
- 内嵌Web服务器启动过程
- 启动事件和监听器机制

## Spring Boot启动原理概念或介绍

Spring Boot启动原理是理解Spring Boot框架运行机制的核心。Spring Boot通过简化配置和自动装配，让开发者能够快速启动一个完整的Spring应用。启动过程包括应用上下文创建、自动配置加载、Bean实例化、Web服务器启动等关键步骤。

### 启动流程概览
1. **应用启动入口**：main方法调用SpringApplication.run()
2. **环境准备**：创建ApplicationEnvironment
3. **上下文创建**：创建ApplicationContext
4. **自动配置**：加载自动配置类
5. **Bean实例化**：创建和初始化Bean
6. **Web服务器启动**：启动内嵌的Web服务器
7. **应用就绪**：发布ApplicationReadyEvent

## 底层原理

### 关键类和接口

#### @SpringBootApplication注解
```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
    @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
    @Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class)
})
public @interface SpringBootApplication {
    // 排除的自动配置类
    @AliasFor(annotation = EnableAutoConfiguration.class)
    Class<?>[] exclude() default {};
    
    // 排除的自动配置类名
    @AliasFor(annotation = EnableAutoConfiguration.class)
    String[] excludeName() default {};
    
    // 扫描的包
    @AliasFor(annotation = ComponentScan.class, attribute = "basePackages")
    String[] scanBasePackages() default {};
    
    // 扫描的类
    @AliasFor(annotation = ComponentScan.class, attribute = "basePackageClasses")
    Class<?>[] scanBasePackageClasses() default {};
}
```

#### SpringApplication类
```java
public class SpringApplication {
    
    // 启动应用的核心方法
    public static ConfigurableApplicationContext run(Class<?>[] primarySources, String[] args) {
        return new SpringApplication(primarySources).run(args);
    }
    
    // 创建SpringApplication实例
    public SpringApplication(Class<?>... primarySources) {
        this(null, primarySources);
    }
    
    // 运行应用
    public ConfigurableApplicationContext run(String... args) {
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        ConfigurableApplicationContext context = null;
        Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
        configureHeadlessProperty();
        
        // 1. 获取SpringApplicationRunListeners
        SpringApplicationRunListeners listeners = getRunListeners(args);
        listeners.starting();
        
        try {
            // 2. 创建ApplicationArguments
            ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
            
            // 3. 准备环境
            ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);
            configureIgnoreBeanInfo(environment);
            Banner printedBanner = printBanner(environment);
            
            // 4. 创建ApplicationContext
            context = createApplicationContext();
            exceptionReporters = getSpringFactoriesInstances(SpringBootExceptionReporter.class,
                    new Class[] { ConfigurableApplicationContext.class }, context);
            
            // 5. 准备上下文
            prepareContext(context, environment, listeners, applicationArguments, printedBanner);
            
            // 6. 刷新上下文
            refreshContext(context);
            
            // 7. 刷新后处理
            afterRefresh(context, applicationArguments);
            stopWatch.stop();
            
            // 8. 发布启动完成事件
            listeners.started(context);
            callRunners(context, applicationArguments);
        } catch (Throwable ex) {
            handleRunFailure(context, ex, exceptionReporters, listeners);
            throw new IllegalStateException(ex);
        }
        
        try {
            listeners.running(context);
        } catch (Throwable ex) {
            handleRunFailure(context, ex, exceptionReporters, null);
            throw new IllegalStateException(ex);
        }
        return context;
    }
}
```

### 关键类图

```
SpringApplication.run()
    ↓
SpringApplication构造函数
    ↓
推断Web应用类型
    ↓
设置Initializers
    ↓
设置Listeners
    ↓
run()方法执行
    ↓
prepareEnvironment()
    ↓
createApplicationContext()
    ↓
prepareContext()
    ↓
refreshContext()
    ↓
afterRefresh()
    ↓
发布ApplicationReadyEvent
```

### 核心代码讲解

#### 1. 应用类型推断
```java
private WebApplicationType deduceWebApplicationType() {
    if (ClassUtils.isPresent(REACTIVE_WEB_ENVIRONMENT_CLASS, null) 
        && !ClassUtils.isPresent(MVC_SERVLET_ENVIRONMENT_CLASS, null)) {
        return WebApplicationType.REACTIVE;
    }
    for (String className : WEB_ENVIRONMENT_CLASSES) {
        if (!ClassUtils.isPresent(className, null)) {
            return WebApplicationType.NONE;
        }
    }
    return WebApplicationType.SERVLET;
}
```

#### 2. 环境准备
```java
private ConfigurableEnvironment prepareEnvironment(SpringApplicationRunListeners listeners,
        ApplicationArguments applicationArguments) {
    // 创建或获取环境
    ConfigurableEnvironment environment = getOrCreateEnvironment();
    
    // 配置环境
    configureEnvironment(environment, applicationArguments.getSourceArgs());
    
    // 绑定配置属性
    ConfigurationPropertySources.attach(environment);
    
    // 发布环境准备事件
    listeners.environmentPrepared(environment);
    
    return environment;
}
```

#### 3. 应用上下文创建
```java
protected ConfigurableApplicationContext createApplicationContext() {
    Class<?> contextClass = this.applicationContextClass;
    if (contextClass == null) {
        try {
            switch (this.webApplicationType) {
                case SERVLET:
                    contextClass = Class.forName(DEFAULT_SERVLET_WEB_CONTEXT_CLASS);
                    break;
                case REACTIVE:
                    contextClass = Class.forName(DEFAULT_REACTIVE_WEB_CONTEXT_CLASS);
                    break;
                default:
                    contextClass = Class.forName(DEFAULT_CONTEXT_CLASS);
            }
        } catch (ClassNotFoundException ex) {
            throw new IllegalStateException("Unable create a default ApplicationContext, "
                    + "please specify an ApplicationContextClass", ex);
        }
    }
    return (ConfigurableApplicationContext) BeanUtils.instantiateClass(contextClass);
}
```

#### 4. 上下文刷新
```java
private void refreshContext(ConfigurableApplicationContext context) {
    refresh(context);
    if (this.registerShutdownHook) {
        try {
            context.registerShutdownHook();
        } catch (AccessControlException ex) {
            // Not allowed in some environments.
        }
    }
}
```

### 设计思想

#### 1. 约定优于配置
Spring Boot通过合理的默认配置，减少开发者的配置工作。

#### 2. 自动装配
通过条件注解和自动配置类，根据classpath中的依赖自动配置应用。

#### 3. 内嵌服务器
将Web服务器内嵌到应用中，简化部署和运维。

#### 4. 启动器机制
通过Starter模块，提供开箱即用的功能集成。

## 启动器（Starter）机制

### Starter模块结构
```
spring-boot-starter-web/
├── META-INF/
│   └── spring.factories
├── pom.xml
└── src/main/java/
    └── org/springframework/boot/autoconfigure/
        └── web/
```

### spring.factories文件
```properties
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.web.servlet.ServletWebServerFactoryAutoConfiguration

# Application Context Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.autoconfigure.SharedMetadataReaderFactoryContextInitializer,\
org.springframework.boot.autoconfigure.logging.ConditionEvaluationReportLoggingListener

# Application Listeners
org.springframework.context.ApplicationListener=\
org.springframework.boot.autoconfigure.BackgroundPreinitializer
```

## 内嵌Web服务器启动

### Servlet Web服务器
```java
@Configuration
@ConditionalOnClass({ Servlet.class, Tomcat.class, UpgradeProtocol.class })
@ConditionalOnMissingBean(value = ServletWebServerFactory.class, search = SearchStrategy.CURRENT)
public class ServletWebServerFactoryAutoConfiguration {
    
    @Bean
    @ConditionalOnClass(name = "org.apache.catalina.startup.Tomcat")
    public TomcatServletWebServerFactory tomcatServletWebServerFactory() {
        return new TomcatServletWebServerFactory();
    }
}
```

### Web服务器启动流程
1. **创建WebServer**：通过WebServerFactory创建
2. **配置端口**：从配置文件中读取server.port
3. **启动服务器**：调用WebServer.start()
4. **注册Servlet**：注册DispatcherServlet
5. **发布事件**：发布ServletWebServerInitializedEvent

## 启动事件和监听器

### 启动事件类型
```java
// 应用启动事件
ApplicationStartingEvent
ApplicationEnvironmentPreparedEvent
ApplicationContextInitializedEvent
ApplicationPreparedEvent
ApplicationStartedEvent
ApplicationReadyEvent
ApplicationFailedEvent
```

### 自定义启动监听器
```java
@Component
public class MyApplicationListener implements ApplicationListener<ApplicationReadyEvent> {
    
    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        System.out.println("应用启动完成！");
    }
}
```

## 启动配置

### 主配置类
```java
@SpringBootApplication
public class MyApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

### 自定义启动配置
```java
@SpringBootApplication
public class MyApplication {
    
    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(MyApplication.class);
        
        // 设置默认配置文件
        app.setDefaultProperties(Collections.singletonMap("spring.profiles.default", "dev"));
        
        // 添加监听器
        app.addListeners(new MyApplicationListener());
        
        // 运行应用
        app.run(args);
    }
}
```

## 启动性能优化

### 延迟初始化
```properties
# application.properties
spring.main.lazy-initialization=true
```

### 组件扫描优化
```java
@SpringBootApplication(scanBasePackages = "com.example")
public class MyApplication {
    // 只扫描指定包
}
```

### 条件化Bean创建
```java
@Bean
@ConditionalOnProperty(name = "app.feature.enabled", havingValue = "true")
public MyService myService() {
    return new MyService();
}
```

## Spring Boot启动原理关联的其它知识

### 1. Spring Framework核心
- [Spring IoC容器](../0101-Spring%20IoC容器.md)
- [Spring Bean生命周期](../0102-Spring%20Bean生命周期.md)
- [Spring依赖注入](../0103-Spring依赖注入.md)

### 2. 自动配置
- [Spring Boot自动配置](0701-Spring%20Boot自动配置.md)
- [Spring Boot配置管理](0703-Spring%20Boot配置管理.md)

### 3. Web开发
- [Spring MVC基础](../0201-Spring%20MVC基础.md)
- [Spring WebFlux基础](../0202-Spring%20WebFlux基础.md)

### 4. 监控和管理
- [Spring Boot监控](0704-Spring%20Boot监控.md)
- [Spring Boot Actuator](../0107-Spring%20Boot%20Actuator.md)

### 5. 相关技术
- [Java类加载机制](../old/100-Java基础-old/JVM/1%20JVM基础%20-%20类字节码详解.md)
- [Java反射机制](../../100-java/100-Java基础/反射/反射.md)
- [Maven依赖管理](../../400-开发工具/420-maven/maven%20命令.md) 