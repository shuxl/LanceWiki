# 1 重点内容
- IoC（控制反转）的核心概念和设计思想
- Spring IoC容器的实现原理和架构
- Bean的创建、管理和依赖注入机制
- 容器启动流程和生命周期管理
- 与Spring Bean生命周期的关联

# 2 IoC概念与介绍

## 2.1 什么是IoC
IoC（Inversion of Control，控制反转）是一种设计思想，它将原本在程序中手动创建对象的控制权交给Spring框架来管理。IoC容器负责创建对象、装配对象、配置对象，并且管理这些对象的整个生命周期。

## 2.2 IoC的核心思想
1. **控制反转**：将对象的创建和依赖关系的管理从代码中转移到容器中
2. **依赖注入**：通过容器将依赖关系注入到对象中
3. **松耦合**：降低组件之间的耦合度，提高代码的可维护性和可测试性

## 2.3 Spring IoC容器的优势
- **统一管理**：所有Bean的生命周期由容器统一管理
- **配置灵活**：支持XML、注解、Java配置等多种配置方式
- **自动装配**：支持自动依赖注入，减少手动配置
- **AOP支持**：与AOP无缝集成，提供横切关注点的支持

# 3 Spring IoC容器架构

## 3.1 核心接口和类
```java
// 容器的基础接口
public interface BeanFactory {
    Object getBean(String name);
    <T> T getBean(String name, Class<T> requiredType);
    <T> T getBean(Class<T> requiredType);
    boolean containsBean(String name);
    boolean isSingleton(String name);
    boolean isPrototype(String name);
}

// 高级容器接口，继承自BeanFactory
public interface ApplicationContext extends BeanFactory {
    String getApplicationName();
    ApplicationContext getParent();
    AutowireCapableBeanFactory getAutowireCapableBeanFactory();
}
```

## 3.2 容器层次结构
```
ApplicationContext (应用上下文)
├── ConfigurableApplicationContext
│   ├── AbstractApplicationContext
│   │   ├── ClassPathXmlApplicationContext
│   │   ├── FileSystemXmlApplicationContext
│   │   └── AnnotationConfigApplicationContext
│   └── WebApplicationContext
└── BeanFactory (基础容器)
    └── DefaultListableBeanFactory
```

# 4 Bean的创建和管理

## 4.1 Bean定义
Bean定义包含了创建Bean实例所需的所有配置信息：
- **类名**：指定Bean的Java类
- **作用域**：singleton、prototype、request、session等
- **生命周期回调**：初始化方法和销毁方法
- **依赖关系**：与其他Bean的依赖关系

## 4.2 Bean的创建流程
1. **实例化**：使用反射或CGLIB创建Bean实例
2. **属性设置**：通过setter方法或字段注入设置属性
3. **Aware接口回调**：调用各种Aware接口方法
4. **BeanPostProcessor前置处理**：执行BeanPostProcessor的postProcessBeforeInitialization方法
5. **初始化方法**：调用@PostConstruct、InitializingBean.afterPropertiesSet()或自定义init方法
6. **BeanPostProcessor后置处理**：执行BeanPostProcessor的postProcessAfterInitialization方法
7. **使用**：Bean可以被应用程序使用
8. **销毁**：调用@PreDestroy、DisposableBean.destroy()或自定义destroy方法

## 4.3 依赖注入方式
```java
// 1. 构造器注入
@Component
public class UserService {
    private final UserRepository userRepository;
    
    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}

// 2. Setter注入
@Component
public class OrderService {
    private PaymentService paymentService;
    
    @Autowired
    public void setPaymentService(PaymentService paymentService) {
        this.paymentService = paymentService;
    }
}

// 3. 字段注入
@Component
public class ProductService {
    @Autowired
    private ProductRepository productRepository;
}
```

# 5 容器启动流程

## 5.1 容器初始化步骤
1. **资源定位**：定位配置文件（XML、注解等）
2. **资源加载**：将配置文件加载到内存中
3. **Bean定义解析**：解析Bean定义信息
4. **Bean注册**：将Bean定义注册到容器中
5. **Bean实例化**：根据Bean定义创建Bean实例
6. **依赖注入**：注入Bean的依赖关系
7. **初始化**：调用Bean的初始化方法
8. **就绪**：容器启动完成，可以提供服务

## 5.2 关键方法调用链
```java
// ApplicationContext启动流程
refresh() 
├── prepareRefresh() // 准备刷新
├── obtainFreshBeanFactory() // 获取新的BeanFactory
├── prepareBeanFactory() // 准备BeanFactory
├── postProcessBeanFactory() // 后处理BeanFactory
├── invokeBeanFactoryPostProcessors() // 调用BeanFactoryPostProcessor
├── registerBeanPostProcessors() // 注册BeanPostProcessor
├── initMessageSource() // 初始化消息源
├── initApplicationEventMulticaster() // 初始化事件广播器
├── onRefresh() // 刷新时的钩子方法
├── registerListeners() // 注册监听器
├── finishBeanFactoryInitialization() // 完成BeanFactory初始化
└── finishRefresh() // 完成刷新
```

# 6 配置方式

## 6.1 XML配置方式
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd">
    
    <bean id="userService" class="com.example.service.UserService">
        <property name="userRepository" ref="userRepository"/>
    </bean>
    
    <bean id="userRepository" class="com.example.repository.UserRepository"/>
</beans>
```

## 6.2 注解配置方式
```java
@Configuration
@ComponentScan("com.example")
public class AppConfig {
    
    @Bean
    public UserService userService(UserRepository userRepository) {
        return new UserService(userRepository);
    }
    
    @Bean
    public UserRepository userRepository() {
        return new UserRepository();
    }
}
```

## 6.3 Java配置方式
```java
@Configuration
@EnableTransactionManagement
@EnableCaching
public class SpringConfig {
    
    @Bean
    @Primary
    public DataSource dataSource() {
        // 配置数据源
        return new HikariDataSource();
    }
    
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

# 7 作用域管理

## 7.1 支持的作用域
- **singleton**：单例，容器中只有一个实例（默认）
- **prototype**：原型，每次获取都创建新实例
- **request**：请求作用域，每个HTTP请求一个实例
- **session**：会话作用域，每个HTTP会话一个实例
- **application**：应用作用域，整个Web应用一个实例

## 7.2 作用域配置
```java
@Component
@Scope("prototype")
public class PrototypeBean {
    // 每次获取都会创建新实例
}

@Component
@Scope(value = WebApplicationContext.SCOPE_SESSION, proxyMode = ScopedProxyMode.TARGET_CLASS)
public class SessionScopedBean {
    // 每个会话一个实例
}
```

# 8 条件化配置

## 8.1 @Conditional注解
```java
@Configuration
public class DataSourceConfig {
    
    @Bean
    @Conditional(DataSourceCondition.class)
    public DataSource dataSource() {
        return new HikariDataSource();
    }
}

public class DataSourceCondition implements Condition {
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        return context.getEnvironment().getProperty("db.enabled", Boolean.class, false);
    }
}
```

## 8.2 Profile配置
```java
@Configuration
@Profile("dev")
public class DevConfig {
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource("jdbc:h2:mem:testdb");
    }
}

@Configuration
@Profile("prod")
public class ProdConfig {
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource("jdbc:mysql://localhost:3306/proddb");
    }
}
```

# 9 事件机制

## 9.1 内置事件
- **ContextRefreshedEvent**：容器刷新完成时发布
- **ContextStartedEvent**：容器启动时发布
- **ContextStoppedEvent**：容器停止时发布
- **ContextClosedEvent**：容器关闭时发布

## 9.2 自定义事件
```java
// 自定义事件
public class UserRegisteredEvent extends ApplicationEvent {
    private final String username;
    
    public UserRegisteredEvent(Object source, String username) {
        super(source);
        this.username = username;
    }
    
    public String getUsername() {
        return username;
    }
}

// 事件监听器
@Component
public class UserEventListener {
    
    @EventListener
    public void handleUserRegistered(UserRegisteredEvent event) {
        System.out.println("用户注册事件: " + event.getUsername());
    }
}

// 发布事件
@Component
public class UserService {
    @Autowired
    private ApplicationEventPublisher eventPublisher;
    
    public void registerUser(String username) {
        // 注册用户逻辑
        eventPublisher.publishEvent(new UserRegisteredEvent(this, username));
    }
}
```

# 10 国际化支持

## 10.1 MessageSource配置
```java
@Configuration
public class MessageConfig {
    
    @Bean
    public MessageSource messageSource() {
        ReloadableResourceBundleMessageSource messageSource = 
            new ReloadableResourceBundleMessageSource();
        messageSource.setBasename("classpath:messages");
        messageSource.setDefaultEncoding("UTF-8");
        return messageSource;
    }
}
```

## 10.2 使用国际化
```java
@Component
public class GreetingService {
    
    @Autowired
    private MessageSource messageSource;
    
    public String getGreeting(String name, Locale locale) {
        return messageSource.getMessage("greeting", new Object[]{name}, locale);
    }
}
```

# 11 性能优化

## 11.1 懒加载
```java
@Component
@Lazy
public class ExpensiveService {
    // 只有在真正使用时才会被初始化
}
```

## 11.2 Bean预加载
```java
@Configuration
public class Config {
    
    @Bean
    @DependsOn("databaseInitializer")
    public UserService userService() {
        return new UserService();
    }
    
    @Bean
    public DatabaseInitializer databaseInitializer() {
        return new DatabaseInitializer();
    }
}
```

# 12 与Spring Bean生命周期的关联

Spring IoC容器与[0102-Spring Bean生命周期](0102-Spring%20Bean生命周期.md)密切相关：

1. **容器启动**：触发Bean的创建和初始化流程
2. **依赖注入**：在Bean生命周期中完成依赖关系的注入
3. **生命周期回调**：容器负责调用Bean的生命周期回调方法
4. **作用域管理**：容器根据Bean的作用域管理Bean实例
5. **销毁管理**：容器负责在关闭时销毁Bean实例

# 13 Spring IoC容器关联的其它知识

## 13.1 相关技术
- **[Spring Bean生命周期](0102-Spring%20Bean生命周期.md)**：了解Bean在容器中的完整生命周期
- **[Spring依赖注入](0103-Spring依赖注入.md)**：深入理解依赖注入的各种方式和原理
- **[Spring AOP编程思想](0302-Spring%20AOP实现原理.md)**：了解AOP如何与IoC容器集成
- **[Spring事务管理](../120-Spring/Spring%20AOP/Spring事务/)**：理解事务管理在容器中的实现

## 13.2 设计模式
- **工厂模式**：IoC容器本质上是一个Bean工厂
- **单例模式**：管理单例Bean的创建和缓存
- **策略模式**：支持多种依赖注入策略
- **观察者模式**：实现事件发布和监听机制

## 13.3 性能调优
- **Bean缓存**：合理使用Bean的作用域和缓存策略
- **懒加载**：对重量级Bean使用懒加载
- **循环依赖**：避免循环依赖，合理设计Bean关系
- **内存管理**：及时释放不需要的Bean实例

## 13.4 最佳实践
- **配置分离**：将不同环境的配置分离
- **组件扫描**：合理使用@ComponentScan
- **条件化配置**：使用@Conditional和@Profile
- **事件驱动**：利用事件机制解耦组件
