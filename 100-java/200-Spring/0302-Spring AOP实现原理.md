# 1 重点
- Spring AOP的底层实现机制和核心组件
- JDK动态代理和CGLIB代理的实现原理
- Spring AOP的代理创建过程和织入机制
- AOP代理的性能优化和最佳实践

# 2 Spring AOP实现原理概念或介绍

## 2.1 Spring AOP架构概览
Spring AOP是基于代理模式实现的，其核心架构包括：
- **代理创建器（ProxyCreator）**：负责创建代理对象
- **切点匹配器（PointcutMatcher）**：负责匹配切点表达式
- **通知链（AdviceChain）**：管理通知的执行顺序
- **织入器（Weaver）**：将通知织入到目标方法中

## 2.2 Spring AOP的设计思想
Spring AOP采用"运行时织入"的方式，通过动态代理在运行时创建代理对象，而不是在编译时修改字节码。这种设计具有以下优势：
- **灵活性**：可以在运行时动态地添加或移除切面
- **透明性**：对业务代码无侵入
- **可维护性**：切面代码与业务代码分离

# 3 核心实现机制

## 3.1 代理创建机制

### 3.1.1 JDK动态代理实现
JDK动态代理基于`java.lang.reflect.Proxy`类实现，只能代理实现了接口的类。

```java
// JDK动态代理的核心实现原理
public class JdkDynamicProxy implements InvocationHandler {
    private Object target; // 目标对象
    private List<AspectJAdvice> advices; // 通知列表
    
    public JdkDynamicProxy(Object target, List<AspectJAdvice> advices) {
        this.target = target;
        this.advices = advices;
    }
    
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        // 1. 执行前置通知
        for (AspectJAdvice advice : advices) {
            if (advice.getAdviceType() == AdviceType.BEFORE) {
                advice.invoke(proxy, method, args);
            }
        }
        
        try {
            // 2. 执行目标方法
            Object result = method.invoke(target, args);
            
            // 3. 执行后置通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER_RETURNING) {
                    advice.invoke(proxy, method, args, result);
                }
            }
            
            return result;
        } catch (Exception e) {
            // 4. 执行异常通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER_THROWING) {
                    advice.invoke(proxy, method, args, e);
                }
            }
            throw e;
        } finally {
            // 5. 执行最终通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER) {
                    advice.invoke(proxy, method, args);
                }
            }
        }
    }
}
```

### 3.1.2 CGLIB代理实现
CGLIB通过继承目标类创建子类代理，可以代理没有实现接口的类。

```java
// CGLIB代理的核心实现原理
public class CglibProxy extends Enhancer {
    private Object target;
    private List<AspectJAdvice> advices;
    
    public CglibProxy(Object target, List<AspectJAdvice> advices) {
        this.target = target;
        this.advices = advices;
        setSuperclass(target.getClass());
        setCallback(this);
    }
    
    @Override
    public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
        // 1. 执行前置通知
        for (AspectJAdvice advice : advices) {
            if (advice.getAdviceType() == AdviceType.BEFORE) {
                advice.invoke(obj, method, args);
            }
        }
        
        try {
            // 2. 执行目标方法
            Object result = proxy.invokeSuper(obj, args);
            
            // 3. 执行后置通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER_RETURNING) {
                    advice.invoke(obj, method, args, result);
                }
            }
            
            return result;
        } catch (Exception e) {
            // 4. 执行异常通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER_THROWING) {
                    advice.invoke(obj, method, args, e);
                }
            }
            throw e;
        } finally {
            // 5. 执行最终通知
            for (AspectJAdvice advice : advices) {
                if (advice.getAdviceType() == AdviceType.AFTER) {
                    advice.invoke(obj, method, args);
                }
            }
        }
    }
}
```

## 3.2 切点匹配机制

### 3.2.1 切点表达式解析
Spring AOP使用AspectJ的切点表达式语言，支持多种匹配方式：

```java
// 切点表达式示例
@Pointcut("execution(* com.example.service.*.*(..))")  // 方法执行
@Pointcut("within(com.example.service.*)")             // 类型匹配
@Pointcut("this(com.example.service.UserService)")     // 代理对象匹配
@Pointcut("target(com.example.service.UserServiceImpl)") // 目标对象匹配
@Pointcut("args(String, int)")                         // 参数匹配
@Pointcut("@annotation(com.example.annotation.Log)")   // 注解匹配
```

### 3.2.2 切点匹配器实现
```java
public class AspectJExpressionPointcut implements Pointcut {
    private String expression;
    private PointcutExpression pointcutExpression;
    
    public AspectJExpressionPointcut(String expression) {
        this.expression = expression;
        this.pointcutExpression = PointcutParser.getPointcutParserSupportingAllPrimitivesAndUsingContextClassloaderForResolution()
                .parsePointcutExpression(expression);
    }
    
    @Override
    public boolean matches(Method method, Class<?> targetClass) {
        return pointcutExpression.matchesMethodExecution(method).alwaysMatches();
    }
}
```

## 3.3 通知链管理

### 3.3.1 通知链构建
Spring AOP将多个切面的通知组织成链式结构，按优先级执行：

```java
public class AdvisedSupport {
    private List<Advisor> advisors = new ArrayList<>();
    private Object target;
    private Class<?>[] interfaces;
    
    public List<MethodInterceptor> getInterceptors(Method method, Class<?> targetClass) {
        List<MethodInterceptor> interceptors = new ArrayList<>();
        
        for (Advisor advisor : advisors) {
            if (advisor.getPointcut().matches(method, targetClass)) {
                interceptors.add(advisor.getAdvice());
            }
        }
        
        // 按优先级排序
        interceptors.sort((a, b) -> Integer.compare(a.getOrder(), b.getOrder()));
        
        return interceptors;
    }
}
```

### 3.3.2 通知执行链
```java
public class ReflectiveMethodInvocation implements MethodInvocation {
    private Object target;
    private Method method;
    private Object[] arguments;
    private List<MethodInterceptor> interceptors;
    private int currentInterceptorIndex = -1;
    
    @Override
    public Object proceed() throws Throwable {
        if (currentInterceptorIndex == interceptors.size() - 1) {
            // 执行目标方法
            return method.invoke(target, arguments);
        }
        
        // 执行下一个拦截器
        MethodInterceptor interceptor = interceptors.get(++currentInterceptorIndex);
        return interceptor.invoke(this);
    }
}
```

# 4 底层原理详解

## 4.1 代理创建流程

### 4.1.1 Spring AOP代理创建步骤
1. **Bean实例化**：Spring容器创建目标Bean实例
2. **切面扫描**：扫描所有标记为切面的Bean
3. **切点匹配**：检查目标Bean的方法是否匹配切点表达式
4. **代理创建**：如果匹配，则创建代理对象
5. **通知织入**：将通知代码织入到代理对象中
6. **Bean替换**：用代理对象替换原始Bean

```java
// Spring AOP代理创建的核心代码
public class AopProxyFactory {
    public AopProxy createAopProxy(AdvisedSupport config) {
        if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {
            Class<?> targetClass = config.getTargetClass();
            if (targetClass == null) {
                throw new AopConfigException("TargetSource cannot determine target class");
            }
            if (targetClass.isInterface() || Proxy.isProxyClass(targetClass)) {
                return new JdkDynamicAopProxy(config);
            }
            return new CglibAopProxy(config);
        } else {
            return new JdkDynamicAopProxy(config);
        }
    }
}
```

## 4.2 织入机制

### 4.2.1 编译时织入 vs 运行时织入
- **编译时织入（AspectJ）**：在编译时修改字节码，性能更好但灵活性较差
- **运行时织入（Spring AOP）**：在运行时通过动态代理实现，灵活性好但性能稍差

### 4.2.2 Spring AOP的织入时机
```java
// Spring AOP的织入时机
public class DefaultAopProxyFactory implements AopProxyFactory {
    @Override
    public AopProxy createAopProxy(AdvisedSupport config) {
        // 在Bean初始化后，返回代理对象
        if (config.isProxyTargetClass()) {
            return new CglibAopProxy(config);
        } else {
            return new JdkDynamicAopProxy(config);
        }
    }
}
```

## 4.3 性能优化机制

### 4.3.1 代理缓存
Spring AOP会缓存代理对象，避免重复创建：

```java
public class ProxyFactory {
    private static final Map<Class<?>, Object> proxyCache = new ConcurrentHashMap<>();
    
    public static Object getProxy(Object target) {
        Class<?> targetClass = target.getClass();
        
        return proxyCache.computeIfAbsent(targetClass, k -> {
            // 创建代理对象
            return createProxy(target);
        });
    }
}
```

### 4.3.2 切点表达式优化
```java
public class OptimizedAspectJExpressionPointcut extends AspectJExpressionPointcut {
    private final Map<Method, Boolean> methodCache = new ConcurrentHashMap<>();
    
    @Override
    public boolean matches(Method method, Class<?> targetClass) {
        return methodCache.computeIfAbsent(method, k -> {
            return super.matches(method, targetClass);
        });
    }
}
```

# 5 关键类分析

## 5.1 ProxyFactory
代理工厂类，负责创建AOP代理：

```java
public class ProxyFactory extends ProxyCreatorSupport {
    public ProxyFactory() {}
    
    public ProxyFactory(Object target) {
        setTarget(target);
        setInterfaces(ClassUtils.getAllInterfaces(target));
    }
    
    public Object getProxy() {
        return createAopProxy().getProxy();
    }
}
```

## 5.2 AdvisedSupport
代理配置支持类，包含代理的配置信息：

```java
public class AdvisedSupport extends ProxyConfig implements Advised {
    private List<Advisor> advisors = new ArrayList<>();
    private Object target;
    private Class<?>[] interfaces;
    private boolean proxyTargetClass = false;
    
    public void addAdvisor(Advisor advisor) {
        advisors.add(advisor);
    }
    
    public List<Advisor> getAdvisors() {
        return advisors;
    }
}
```

## 5.3 AopProxy
AOP代理接口，定义了代理对象的基本行为：

```java
public interface AopProxy {
    Object getProxy();
    Object getProxy(ClassLoader classLoader);
}
```

# 6 设计思想

## 6.1 代理模式的应用
Spring AOP基于代理模式，通过代理对象拦截方法调用，在调用前后执行通知代码。

## 6.2 责任链模式
多个切面的通知通过责任链模式组织，按优先级顺序执行。

## 6.3 模板方法模式
在代理创建过程中使用模板方法模式，定义了代理创建的通用流程。

## 6.4 策略模式
根据目标类的特征选择不同的代理策略（JDK动态代理或CGLIB代理）。

# 7 Spring AOP关联的其它知识

## 7.1 Spring框架核心
- **[Spring IoC容器](0101-Spring%20IoC容器.md)**：AOP代理的创建和管理
- **[Spring Bean生命周期](0102-Spring%20Bean生命周期.md)**：代理对象的创建时机
- **[Spring依赖注入](0103-Spring依赖注入.md)**：切面Bean的注入方式

## 7.2 设计模式
- **代理模式**：AOP的核心实现原理
- **责任链模式**：通知链的执行机制
- **策略模式**：代理方式的选择策略
- **模板方法模式**：代理创建的通用流程

## 7.3 性能优化
- **代理性能对比**：JDK动态代理 vs CGLIB代理的性能差异
- **切点表达式优化**：高效的切点表达式设计
- **通知执行优化**：通知链的执行效率优化

## 7.4 字节码技术
- **ASM**：CGLIB的底层字节码操作库
- **Javassist**：另一种字节码操作库
- **字节码增强**：编译时织入的实现原理

## 7.5 反射机制
- **Method.invoke()**：JDK动态代理的核心
- **MethodProxy**：CGLIB代理的核心
- **反射性能**：代理调用的性能考虑 