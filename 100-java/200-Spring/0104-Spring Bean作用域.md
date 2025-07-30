
# 1 Spring Bean作用域概念或介绍

**本文重点：**
- 理解Spring Bean作用域的核心概念和意义
- 掌握singleton、prototype、request、session、application、websocket六种作用域
- 学习不同作用域的生命周期特点和使用场景
- 了解作用域对依赖注入和性能的影响
- 掌握作用域的配置方法和最佳实践

## 1.1 什么是Bean作用域

Bean作用域（Bean Scope）定义了Spring容器中Bean的生命周期和可见性。它决定了Bean实例在Spring容器中的创建方式、存活时间和共享范围。不同的作用域适用于不同的使用场景，选择合适的作用域对于应用的性能和正确性至关重要。

## 1.2 作用域的重要性

1. **内存管理**：合理的作用域可以避免内存泄漏和资源浪费
2. **线程安全**：不同作用域的Bean有不同的线程安全特性
3. **性能优化**：合适的作用域可以提高应用性能
4. **功能实现**：某些功能需要特定的作用域才能正确实现

# 2 Spring Bean作用域类型

## 2.1 Singleton作用域（单例）

Singleton是Spring的默认作用域，整个Spring容器中只有一个Bean实例。

```java
@Service
@Scope("singleton") // 默认，可以省略
public class UserService {
    private int counter = 0;
    
    public void increment() {
        counter++;
    }
    
    public int getCounter() {
        return counter;
    }
}
```

**特点：**
- 整个容器中只有一个实例
- 所有对该Bean的请求都返回同一个实例
- 线程安全需要开发者自己保证
- 适合无状态的Bean

**生命周期：**
- 容器启动时创建
- 容器关闭时销毁
- 支持延迟初始化（@Lazy）

## 2.2 Prototype作用域（原型）

Prototype作用域每次请求都会创建一个新的Bean实例。

```java
@Component
@Scope("prototype")
public class OrderService {
    private String orderId;
    
    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }
    
    public String getOrderId() {
        return orderId;
    }
}
```

**特点：**
- 每次请求都创建新实例
- 不参与Spring的生命周期管理
- 容器不负责销毁prototype Bean
- 适合有状态的Bean

**使用场景：**
- 有状态的业务对象
- 需要隔离数据的场景
- 线程安全的考虑

## 2.3 Request作用域

Request作用域在Web应用中，每个HTTP请求都会创建一个新的Bean实例。

```java
@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class UserSession {
    private String userId;
    private String sessionId;
    
    public void setUserInfo(String userId, String sessionId) {
        this.userId = userId;
        this.sessionId = sessionId;
    }
    
    public String getUserInfo() {
        return userId + ":" + sessionId;
    }
}
```

**特点：**
- 每个HTTP请求一个实例
- 请求结束后自动销毁
- 需要配置代理模式
- 只能在Web环境中使用

**配置方式：**
```java
@Configuration
public class WebConfig {
    
    @Bean
    @Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
    public UserSession userSession() {
        return new UserSession();
    }
}
```

## 2.4 Session作用域

Session作用域在Web应用中，每个HTTP会话都会创建一个新的Bean实例。

```java
@Component
@Scope(value = "session", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class ShoppingCart {
    private List<String> items = new ArrayList<>();
    
    public void addItem(String item) {
        items.add(item);
    }
    
    public List<String> getItems() {
        return items;
    }
    
    public void clear() {
        items.clear();
    }
}
```

**特点：**
- 每个HTTP会话一个实例
- 会话结束后自动销毁
- 适合存储用户会话数据
- 需要配置代理模式

## 2.5 Application作用域

Application作用域在Web应用中，整个Web应用共享一个Bean实例。

```java
@Component
@Scope(value = "application", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class ApplicationConfig {
    private Map<String, String> config = new HashMap<>();
    
    public void setConfig(String key, String value) {
        config.put(key, value);
    }
    
    public String getConfig(String key) {
        return config.get(key);
    }
}
```

**特点：**
- 整个Web应用共享一个实例
- 应用关闭时销毁
- 适合全局配置和缓存
- 需要配置代理模式

## 2.6 WebSocket作用域

WebSocket作用域在WebSocket应用中，每个WebSocket会话都会创建一个新的Bean实例。

```java
@Component
@Scope(value = "websocket", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class WebSocketSession {
    private String sessionId;
    private List<String> messages = new ArrayList<>();
    
    public void addMessage(String message) {
        messages.add(message);
    }
    
    public List<String> getMessages() {
        return messages;
    }
}
```

**特点：**
- 每个WebSocket会话一个实例
- 会话结束后自动销毁
- 适合WebSocket应用
- 需要配置代理模式

# 3 作用域配置方法

## 3.1 注解配置

```java
// 使用@Scope注解
@Component
@Scope("prototype")
public class MyService {
    // 实现
}

// 使用@Scope配置代理模式
@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestScopedBean {
    // 实现
}
```

## 3.2 XML配置

```xml
<bean id="userService" class="com.example.service.UserService" scope="prototype">
    <!-- 配置 -->
</bean>

<bean id="sessionBean" class="com.example.SessionBean" scope="session">
    <aop:scoped-proxy/>
</bean>
```

## 3.3 Java配置

```java
@Configuration
public class AppConfig {
    
    @Bean
    @Scope("prototype")
    public UserService userService() {
        return new UserService();
    }
    
    @Bean
    @Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
    public RequestBean requestBean() {
        return new RequestBean();
    }
}
```

# 4 代理模式详解

## 4.1 为什么需要代理

当在singleton Bean中注入request/session作用域的Bean时，Spring需要创建代理对象，因为singleton Bean在容器启动时就创建了，而request/session Bean在请求时才创建。

## 4.2 代理模式类型

```java
// 接口代理（默认）
@Scope(value = "request", proxyMode = ScopedProxyMode.INTERFACES)
public class RequestBean implements RequestInterface {
    // 实现
}

// 类代理
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestBean {
    // 实现
}
```

**区别：**
- INTERFACES：基于JDK动态代理，只能代理接口
- TARGET_CLASS：基于CGLIB代理，可以代理类

# 5 作用域对依赖注入的影响

## 5.1 Singleton注入Prototype

```java
@Service
public class SingletonService {
    @Autowired
    private PrototypeService prototypeService; // 总是同一个实例
    
    public PrototypeService getPrototypeService() {
        return prototypeService;
    }
}
```

**问题：** SingletonService中的prototypeService总是同一个实例，失去了prototype的意义。

**解决方案：**
```java
@Service
public class SingletonService {
    
    @Autowired
    private ApplicationContext applicationContext;
    
    public PrototypeService getPrototypeService() {
        return applicationContext.getBean(PrototypeService.class);
    }
}
```

## 5.2 使用@Lookup注解

```java
@Service
public class SingletonService {
    
    @Lookup
    public PrototypeService getPrototypeService() {
        return null; // Spring会重写这个方法
    }
}
```

## 5.3 使用ObjectProvider

```java
@Service
public class SingletonService {
    
    @Autowired
    private ObjectProvider<PrototypeService> prototypeServiceProvider;
    
    public PrototypeService getPrototypeService() {
        return prototypeServiceProvider.getObject();
    }
}
```

# 6 作用域最佳实践

## 6.1 选择合适的作用域

```java
// 无状态服务 - 使用singleton
@Service
public class UserService {
    public User findUser(Long id) {
        // 无状态操作
    }
}

// 有状态对象 - 使用prototype
@Component
@Scope("prototype")
public class OrderProcessor {
    private Order currentOrder;
    
    public void processOrder(Order order) {
        this.currentOrder = order;
        // 处理订单
    }
}

// 用户会话数据 - 使用session
@Component
@Scope(value = "session", proxyMode = ScopedProxyMode.TARGET_CLASS)
public class UserSession {
    private String userId;
    private List<String> permissions;
}
```

## 6.2 避免常见错误

```java
// 错误：在singleton中直接注入prototype。只注入一次，生命周期由 singleton 控制，失去 prototype 的特性
@Service
public class WrongService {
    @Autowired
    private PrototypeBean prototypeBean; // 总是同一个实例
}

// 正确：使用ApplicationContext获取
@Service
public class CorrectService {
    @Autowired
    private ApplicationContext context;
    
    public PrototypeBean getPrototypeBean() {
        return context.getBean(PrototypeBean.class);
    }
}
```

## 6.3 线程安全考虑

```java
// 线程安全的singleton
@Service
public class ThreadSafeService {
    private final AtomicInteger counter = new AtomicInteger(0);
    
    public int increment() {
        return counter.incrementAndGet();
    }
}

// 线程不安全的singleton（避免）
@Service
public class UnsafeService {
    private int counter = 0; // 非线程安全
    
    public int increment() {
        return ++counter; // 可能有问题
    }
}
```

# 7 自定义作用域

## 7.1 实现Scope接口

```java
public class CustomScope implements Scope {
    
    private final Map<String, Object> cache = new ConcurrentHashMap<>();
    
    @Override
    public Object get(String name, ObjectFactory<?> objectFactory) {
        return cache.computeIfAbsent(name, k -> objectFactory.getObject());
    }
    
    @Override
    public Object remove(String name) {
        return cache.remove(name);
    }
    
    @Override
    public void registerDestructionCallback(String name, Runnable callback) {
        // 注册销毁回调
    }
    
    @Override
    public Object resolveContextualObject(String key) {
        return null;
    }
    
    @Override
    public String getConversationId() {
        return "custom";
    }
}
```

## 7.2 注册自定义作用域

```java
@Configuration
public class CustomScopeConfig {
    
    @PostConstruct
    public void registerCustomScope() {
        ConfigurableBeanFactory beanFactory = applicationContext.getBeanFactory();
        beanFactory.registerScope("custom", new CustomScope());
    }
}
```

## 7.3 使用自定义作用域

```java
@Component
@Scope("custom")
public class CustomScopedBean {
    // 实现
}
```

# 8 作用域测试

## 8.1 单元测试示例

```java
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = TestConfig.class)
class ScopeTest {
    
    @Autowired
    private SingletonService singletonService1;
    
    @Autowired
    private SingletonService singletonService2;
    
    @Autowired
    private ApplicationContext context;
    
    @Test
    void testSingletonScope() {
        // 验证singleton作用域
        assertSame(singletonService1, singletonService2);
    }
    
    @Test
    void testPrototypeScope() {
        PrototypeService prototype1 = context.getBean(PrototypeService.class);
        PrototypeService prototype2 = context.getBean(PrototypeService.class);
        
        // 验证prototype作用域
        assertNotSame(prototype1, prototype2);
    }
}
```

# 9 Spring Bean作用域关联的其它知识

## 9.1 相关概念

- **[Spring IoC容器](0101-Spring%20IoC容器.md)**：作用域管理的容器基础
- **[Spring Bean生命周期](0102-Spring%20Bean生命周期.md)**：不同作用域的生命周期管理
- **[Spring依赖注入](0103-Spring依赖注入.md)**：作用域对依赖注入的影响

## 9.2 扩展知识

- **设计模式**：单例模式、原型模式与Spring作用域的关系
- **内存管理**：不同作用域对内存使用的影响
- **线程安全**：多线程环境下作用域的选择
- **Web开发**：Web应用中作用域的特殊考虑
- **性能优化**：合理选择作用域提升应用性能
