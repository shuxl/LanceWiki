# 1 Spring依赖注入概念或介绍

**本文重点：**
- 理解依赖注入的核心概念和优势
- 掌握构造器注入、setter注入、字段注入三种方式
- 学习@Autowired、@Resource、@Qualifier等注解的使用
- 了解循环依赖的处理机制
- 掌握依赖注入的最佳实践

## 1.1 什么是依赖注入

依赖注入（Dependency Injection，DI）是Spring框架的核心特性之一，它是一种设计模式，用于实现控制反转（IoC）。依赖注入允许对象在创建时自动获得它们所依赖的对象，而不需要手动创建这些依赖对象。

## 1.2 依赖注入的优势

1. **松耦合**：组件之间的依赖关系由容器管理，降低了组件间的耦合度
2. **可测试性**：便于进行单元测试，可以轻松替换依赖对象
3. **可维护性**：代码结构更清晰，易于维护和扩展
4. **可重用性**：组件可以在不同场景下重用

# 2 依赖注入的方式

## 2.1 构造器注入

构造器注入是最推荐的依赖注入方式，它确保了依赖的不可变性，并且支持不可变对象。

```java
@Service
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
    
    // 构造器注入
    public UserService(UserRepository userRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

**优点：**
- 确保依赖不可变
- 支持不可变对象
- 便于单元测试
- 明确表达依赖关系

## 2.2 Setter注入

Setter注入通过setter方法注入依赖，适用于可选依赖。

```java
@Service
public class UserService {
    private UserRepository userRepository;
    private EmailService emailService;
    
    // Setter注入
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    public void setEmailService(EmailService emailService) {
        this.emailService = emailService;
    }
}
```

**适用场景：**
- 可选依赖
- 需要动态改变依赖的场景

## 2.3 字段注入

字段注入通过@Autowired注解直接注入到字段上，使用简单但不够推荐。

```java
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private EmailService emailService;
}
```

**缺点：**
- 无法设置final字段
- 难以进行单元测试
- 隐藏了依赖关系

# 3 依赖注入注解详解

## 3.1 @Autowired注解

@Autowired是Spring提供的自动装配注解，可以用于构造器、setter方法、字段和普通方法。

```java
@Service
public class UserService {
    
    // 字段注入
    @Autowired
    private UserRepository userRepository;
    
    // 构造器注入（推荐）
    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    // Setter注入
    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

**@Autowired的特性：**
- required属性默认为true，如果找不到匹配的bean会抛出异常
- 可以通过@Autowired(required=false)设置为可选依赖

## 3.2 @Resource注解

@Resource是Java标准注解，功能类似于@Autowired，但有一些区别：

```java
@Service
public class UserService {
    
    @Resource(name = "userRepository")
    private UserRepository userRepository;
    
    @Resource
    private EmailService emailService;
}
```

**@Resource vs @Autowired：**
- @Resource按名称装配，@Autowired按类型装配
- @Resource是Java标准，@Autowired是Spring特有
- @Resource不支持构造器注入

## 3.3 @Qualifier注解

当存在多个相同类型的bean时，使用@Qualifier指定具体的bean：

```java
@Service
public class UserService {
    
    @Autowired
    @Qualifier("mysqlUserRepository")
    private UserRepository userRepository;
    
    @Autowired
    @Qualifier("redisUserRepository")
    private UserRepository cacheRepository;
}
```

# 4 依赖注入配置

## 4.1 XML配置方式

```xml
<bean id="userService" class="com.example.service.UserService">
    <!-- 构造器注入 -->
    <constructor-arg ref="userRepository"/>
    <constructor-arg ref="emailService"/>
    
    <!-- Setter注入 -->
    <property name="userRepository" ref="userRepository"/>
    <property name="emailService" ref="emailService"/>
</bean>
```

## 4.2 Java配置方式

```java
@Configuration
public class AppConfig {
    
    @Bean
    public UserService userService(UserRepository userRepository, EmailService emailService) {
        return new UserService(userRepository, emailService);
    }
}
```

## 4.3 注解配置方式

```java
@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private EmailService emailService;
}
```

# 5 循环依赖处理

## 5.1 什么是循环依赖

循环依赖是指两个或多个bean相互依赖，形成循环引用。

```java
@Service
public class UserService {
    @Autowired
    private OrderService orderService;
}

@Service
public class OrderService {
    @Autowired
    private UserService userService;
}
```

## 5.2 Spring的解决方案

Spring通过三级缓存机制解决循环依赖：

1. **一级缓存（singletonObjects）**：存储完全初始化好的bean
2. **二级缓存（earlySingletonObjects）**：存储早期暴露的bean
3. **三级缓存（singletonFactories）**：存储bean的工厂对象

**解决流程：**
1. 创建UserService实例（未完全初始化）
2. 将UserService的工厂对象放入三级缓存
3. 注入UserService的依赖OrderService
4. 创建OrderService实例
5. 注入OrderService的依赖UserService（从三级缓存获取）
6. 完成OrderService的初始化
7. 完成UserService的初始化

## 5.3 详细解决流程与源码解读

### 5.3.1 三级缓存的数据结构

```java
// DefaultSingletonBeanRegistry.java
public class DefaultSingletonBeanRegistry extends SimpleAliasRegistry implements SingletonBeanRegistry {
    
    // 一级缓存：存储完全初始化好的bean
    private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);
    
    // 二级缓存：存储早期暴露的bean（未完全初始化）
    private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);
    
    // 三级缓存：存储bean的工厂对象
    private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
}
```

### 5.3.2 详细解决流程

#### 第一步：开始创建UserService

```java
// AbstractBeanFactory.java - doGetBean方法
protected <T> T doGetBean(String name, Class<T> requiredType, Object... args) {
    // 1. 首先尝试从一级缓存获取
    Object sharedInstance = getSingleton(beanName);
    if (sharedInstance != null && args == null) {
        return (T) sharedInstance;
    }
    
    // 2. 如果一级缓存没有，开始创建bean
    if (mbd.isSingleton()) {
        sharedInstance = getSingleton(beanName, () -> {
            return createBean(beanName, mbd, args);
        });
    }
}
```

#### 第二步：创建UserService实例并放入三级缓存

```java
// AbstractAutowireCapableBeanFactory.java - doCreateBean方法
protected Object doCreateBean(String beanName, RootBeanDefinition mbd, Object[] args) {
    // 1. 创建bean实例（此时还未设置属性）
    Object beanInstance = doInstantiate(beanName, mbd);
    
    // 2. 判断是否需要提前暴露（解决循环依赖的关键）
    boolean earlySingletonExposure = (mbd.isSingleton() && 
        this.allowCircularReferences && 
        isSingletonCurrentlyInCreation(beanName));
    
    if (earlySingletonExposure) {
        // 3. 将bean的工厂对象放入三级缓存
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, beanInstance));
    }
    
    // 4. 继续初始化bean（设置属性、执行初始化方法等）
    Object exposedObject = beanInstance;
    try {
        populateBean(beanName, mbd, instanceWrapper);
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
    catch (Throwable ex) {
        // 异常处理
    }
    
    return exposedObject;
}
```

**关键点：**
- 在`populateBean`方法执行前，bean的工厂对象已经放入三级缓存
- 这确保了在注入依赖时，能够从三级缓存获取到早期暴露的bean

#### 第三步：注入UserService的依赖OrderService

```java
// AbstractAutowireCapableBeanFactory.java - populateBean方法
protected void populateBean(String beanName, RootBeanDefinition mbd, BeanWrapper bw) {
    // 1. 获取所有需要注入的属性
    PropertyValues pvs = mbd.getPropertyValues();
    
    // 2. 执行自动装配
    if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME ||
        mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
        MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
        
        // 3. 按名称自动装配
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME) {
            autowireByName(beanName, mbd, bw, newPvs);
        }
        
        // 4. 按类型自动装配
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
            autowireByType(beanName, mbd, bw, newPvs);
        }
        
        pvs = newPvs;
    }
    
    // 5. 应用属性值
    applyPropertyValues(beanName, mbd, bw, pvs);
}
```

#### 第四步：创建OrderService实例

当UserService需要注入OrderService时，Spring会调用`getBean("orderService")`，开始创建OrderService。

#### 第五步：OrderService注入UserService时从缓存获取

```java
// DefaultSingletonBeanRegistry.java - getSingleton方法
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    // 1. 首先从一级缓存获取
    Object singletonObject = this.singletonObjects.get(beanName);
    if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
        synchronized (this.singletonObjects) {
            // 2. 从二级缓存获取
            singletonObject = this.earlySingletonObjects.get(beanName);
            if (singletonObject == null && allowEarlyReference) {
                // 3. 从三级缓存获取工厂对象
                ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
                if (singletonFactory != null) {
                    // 4. 调用工厂方法获取早期bean
                    singletonObject = singletonFactory.getObject();
                    // 5. 将bean从三级缓存移动到二级缓存
                    this.earlySingletonObjects.put(beanName, singletonObject);
                    // 6. 从三级缓存中移除
                    this.singletonFactories.remove(beanName);
                }
            }
        }
    }
    return singletonObject;
}
```

**关键点：**
- 当从三级缓存获取到bean后，会将其移动到二级缓存
- 同时从三级缓存中移除该bean的工厂对象
- 这确保了同一个bean不会重复创建

#### 第六步：完成OrderService的初始化

OrderService获得UserService的早期引用后，完成自己的初始化，然后被放入一级缓存。

#### 第七步：完成UserService的初始化

```java
// DefaultSingletonBeanRegistry.java - addSingleton方法
protected void addSingleton(String beanName, Object singletonObject) {
    synchronized (this.singletonObjects) {
        // 1. 将完全初始化的bean放入一级缓存
        this.singletonObjects.put(beanName, singletonObject);
        // 2. 从二级缓存中移除
        this.singletonFactories.remove(beanName);
        this.earlySingletonObjects.remove(beanName);
        // 3. 记录已注册的单例
        this.registeredSingletons.add(beanName);
    }
}
```

### 5.3.3 缓存失效机制

#### 从三级缓存移动到二级缓存

```java
// 当从三级缓存获取bean时
singletonObject = singletonFactory.getObject();
// 移动到二级缓存
this.earlySingletonObjects.put(beanName, singletonObject);
// 从三级缓存移除
this.singletonFactories.remove(beanName);
```

#### 从二级缓存移动到一级缓存

```java
// 当bean完全初始化后
this.singletonObjects.put(beanName, singletonObject);
// 从二级缓存移除
this.earlySingletonObjects.remove(beanName);
```

### 5.3.4 关键源码方法解读

#### getEarlyBeanReference方法

```java
// AbstractAutowireCapableBeanFactory.java
protected Object getEarlyBeanReference(String beanName, RootBeanDefinition mbd, Object bean) {
    Object exposedObject = bean;
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof SmartInstantiationAwareBeanPostProcessor) {
                SmartInstantiationAwareBeanPostProcessor ibp = 
                    (SmartInstantiationAwareBeanPostProcessor) bp;
                // 执行后置处理器，可能返回代理对象
                exposedObject = ibp.getEarlyBeanReference(exposedObject, beanName);
            }
        }
    }
    return exposedObject;
}
```

**作用：**
- 在早期暴露bean时，执行后置处理器
- 可能返回代理对象（如AOP代理）
- 确保循环依赖中的bean是代理对象

#### allowCircularReferences配置

```java
// AbstractAutowireCapableBeanFactory.java
private boolean allowCircularReferences = true;

public void setAllowCircularReferences(boolean allowCircularReferences) {
    this.allowCircularReferences = allowCircularReferences;
}
```

**作用：**
- 控制是否允许循环依赖
- 默认为true，可以通过配置关闭

### 5.3.5 循环依赖的时序图

```
UserService创建流程：
1. doGetBean("userService")
2. getSingleton("userService") -> null
3. doCreateBean("userService")
   ├── 创建实例
   ├── addSingletonFactory() -> 放入三级缓存
   └── populateBean() -> 注入OrderService
       └── getBean("orderService")
           └── doCreateBean("orderService")
               ├── 创建实例
               ├── addSingletonFactory() -> 放入三级缓存
               └── populateBean() -> 注入UserService
                   └── getBean("userService")
                       └── getSingleton("userService", true)
                           ├── 一级缓存 -> null
                           ├── 二级缓存 -> null
                           └── 三级缓存 -> 获取早期bean
                               ├── getEarlyBeanReference()
                               ├── 移动到二级缓存
                               └── 从三级缓存移除
```

### 5.3.6 为什么需要三级缓存

**如果只有两级缓存：**
- 无法处理AOP代理的情况
- 早期暴露的bean可能是原始对象，而不是代理对象

**三级缓存的作用：**
- 存储工厂对象，可以在需要时创建代理对象
- 确保循环依赖中的bean是最终形态（可能是代理对象）
- 避免重复创建代理对象

## 5.4 循环依赖的限制

- 只支持单例bean的循环依赖
- 不支持prototype作用域的循环依赖
- 构造器注入的循环依赖无法解决

# 6 依赖注入最佳实践

## 6.1 推荐使用构造器注入

```java
@Service
public class UserService {
    private final UserRepository userRepository;
    private final EmailService emailService;
    
    public UserService(UserRepository userRepository, EmailService emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

## 6.2 避免字段注入

```java
// 不推荐
@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;
}

// 推荐
@Service
public class UserService {
    private final UserRepository userRepository;
    
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
```

## 6.3 使用@Qualifier避免歧义

```java
@Service
public class UserService {
    @Autowired
    @Qualifier("mysqlUserRepository")
    private UserRepository userRepository;
}
```

## 6.4 合理使用@Primary

```java
@Primary
@Service
public class MySQLUserRepository implements UserRepository {
    // 实现
}
```

# 7 依赖注入的测试

## 7.1 单元测试示例

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    
    @Mock
    private UserRepository userRepository;
    
    @Mock
    private EmailService emailService;
    
    @InjectMocks
    private UserService userService;
    
    @Test
    void testCreateUser() {
        // 测试逻辑
    }
}
```

# 8 Spring依赖注入关联的其它知识

## 8.1 相关概念

- **[Spring IoC容器](0101-Spring%20IoC容器.md)**：依赖注入的基础容器
- **[Spring Bean生命周期](0102-Spring%20Bean生命周期.md)**：了解bean的创建和销毁过程
- **[Spring Bean作用域](0104-Spring%20Bean作用域.md)**：不同作用域对依赖注入的影响

## 8.2 扩展知识

- **设计模式**：依赖注入是控制反转（IoC）的一种实现方式
- **反射机制**：Spring通过反射实现依赖注入
- **代理模式**：AOP代理对依赖注入的影响
- **配置管理**：不同环境下的依赖配置管理
