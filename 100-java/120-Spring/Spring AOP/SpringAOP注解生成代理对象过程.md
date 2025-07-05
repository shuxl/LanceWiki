 ![AspectJ关键类-随笔](../uml/spring-uml.mdj)
# 1 结构说明
## 1.1 Advisor与BeanFactory
```
AbstractBeanFactory
	- beanPostProcessors 包含 AnnotationAwareAspectJAutoProxyCreator的bean
		-> AnnotationAwareAspectJAutoProxyCreator
			- BeanFactoryAspectJAdvisorsBuilder
				- Map<String, List<Advisor>> advisorsCache：key为@Aspect标记的beanName，value为InstantiationModelAwarePointcutAdvisorImpl
					-> InstantiationModelAwarePointcutAdvisorImpl
						- Advice
						- Pointcut
		
```


## 1.2 被代理对象的新对象结构

``` java
public class MyService$$EnhancerBySpringCGLIB extends MyService {
    
    private final MethodInterceptor interceptor;

    public MyService$$EnhancerBySpringCGLIB(MethodInterceptor interceptor) {
        this.interceptor = interceptor;
    }

    @Override
    public void doWork() {
        Method method = MyService.class.getMethod("doWork");
        Object[] args = new Object[0];

        try {
            // 注意！这里不是直接执行 super.doWork()
            // 而是通过 interceptor 调用
            interceptor.intercept(this, doSomethingMethod, args, methodProxy);
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }
}
```

# 2 Spring生命周期中生成AOP代理对象的过程
1. 注册AnnotationAwareAspectJAutoProxyCreator的BeanDefinition。
	+ 比如遇到注解@EnableAspectJAutoProxy时，触发AspectJAutoProxyRegistrar的注册逻辑
2. 将AnnotationAwareAspectJAutoProxyCreator注册为BeanPostProcessors
	+ refresh()->registerBeanPostProcessors()方法中 beanFactory.addBeanPostProcessor(...)，正式把它加入处理链
3. 生成Advisor
	+ 在Bean创建过程中，会触发applyBeanPostProcessorsBeforeInstantiation流程。在调用shouldSkip时，会触发Advisor的解析和缓存流程
4. 其它Bean会在postProcessAfterInitialization()时调用AnnotationAwareAspectJAutoProxyCreator 的代理方法，创建Bean的代理对象
5. 代理对象的执行过程中会按照责任链模式执行所有的Advice
## 2.1 生成前的准备

### 2.1.1 注册 **AnnotationAwareAspectJAutoProxyCreator**
+ Spring 在 **解析配置类** 或 **加载 @EnableAspectJAutoProxy 注解** 的过程中，会通过 **@Import 机制** 注册 AnnotationAwareAspectJAutoProxyCreator 这个 Bean 定义（BeanDefinition），最终由 BeanFactory 注册并缓存。
#### 2.1.1.1 `@EnableAspectJAutoProxy` 注解说明

``` java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Import(AspectJAutoProxyRegistrar.class)
public @interface EnableAspectJAutoProxy {
    boolean proxyTargetClass() default false;
    boolean exposeProxy() default false;
}
```
- 看到 `@Import(AspectJAutoProxyRegistrar.class)`，这表示这个类会被 Spring 调用，用来注册 Bean 定义。
#### 2.1.1.2 **AspectJAutoProxyRegistrar**的实现
调用了工具类方法来注册代理创建器。
``` java
public class AspectJAutoProxyRegistrar implements ImportBeanDefinitionRegistrar {
    @Override
    public void registerBeanDefinitions(
            AnnotationMetadata importingClassMetadata,
            BeanDefinitionRegistry registry) {

        AopConfigUtils.registerAspectJAnnotationAutoProxyCreatorIfNecessary(registry);
    }
}
```

#### 2.1.1.3 **AopConfigUtils**注册的到底是什么？
``` java
public static BeanDefinition registerAspectJAnnotationAutoProxyCreatorIfNecessary(BeanDefinitionRegistry registry) {
    return registerOrEscalateApcAsRequired(
        AnnotationAwareAspectJAutoProxyCreator.class, registry);
}
```
最终会通过 registry.registerBeanDefinition(...) 注册一个 BeanDefinition。
### 2.1.2 @Around 等注解的解析为Advisor
+ 在Bean创建过程中，会触发applyBeanPostProcessorsBeforeInstantiation流程。在调用shouldSkip时，会触发Advisor的解析和缓存流程
#### 2.1.2.1 入口类： AnnotationAwareAspectJAutoProxyCreator
这是一个 BeanPostProcessor，在创建每个 bean 时，会决定是否需要为它创建代理对象。它继承自：
```
AbstractAdvisorAutoProxyCreator
    └──→ AbstractAutoProxyCreator
```

其中有关键方法：

```
protected List<Advisor> findCandidateAdvisors()
```

调用：

```
aspectJAdvisorsBuilder.buildAspectJAdvisors()
```


#### 2.1.2.2 进入类： **BeanFactoryAspectJAdvisorsBuilder**

此类会扫描容器中所有 @Aspect bean，然后对每个 bean：

```
ReflectiveAspectJAdvisorFactory.getAdvisors(aspectInstanceFactory)
```

#### 2.1.2.3 切面解析类：ReflectiveAspectJAdvisorFactory

这个类才是真正负责把切面方法（@Around, @Before 等）转成 Advisor 的地方。
**方法：**
```
public List<Advisor> getAdvisors(MetadataAwareAspectInstanceFactory aspectInstanceFactory)
```

→ 遍历所有方法，调用：

```
@Nullable
public Advisor getAdvisor(Method candidateAdviceMethod, AspectJExpressionPointcut expressionPointcut, ...)
```


#### 2.1.2.4 核心方法： getAdvice(...)

这一步就是关键 —— 把 @Around 方法转换成 Advice（MethodInterceptor）：

```
public Advice getAdvice(Method candidateAdviceMethod, AspectJExpressionPointcut pointcut, ...)
```


该方法会判断注解类型：

```
if (candidateAdviceMethod.isAnnotationPresent(Around.class)) {
    return new AspectJAroundAdvice(
        candidateAdviceMethod,
        pointcut,
        aspectInstanceFactory
    );
}
```

- AspectJAroundAdvice 实现了 org.aopalliance.intercept.MethodInterceptor
- 它是后续拦截器链中的一环。
#### 2.1.2.5 Advisor 包装InstantiationModelAwarePointcutAdvisorImpl
最终构造 Advisor：

```
return new InstantiationModelAwarePointcutAdvisorImpl(
    adviceMethod,  // 带有 @Around 注解的方法
    pointcut,
    aspectInstanceFactory,
    ...
);
```

这个 Advisor 包含：
- AspectJExpressionPointcut
- Advice（如 AspectJAroundAdvice）

#### 2.1.2.6 **最终总结流程**

```
AnnotationAwareAspectJAutoProxyCreator
    → BeanFactoryAspectJAdvisorsBuilder
        → ReflectiveAspectJAdvisorFactory.getAdvisors()
            → getAdvisor(method, pointcut, ...)
                → getAdvice(method, pointcut, ...)
                    → new AspectJAroundAdvice(...)
                → new InstantiationModelAwarePointcutAdvisorImpl(...)
```

#### 2.1.2.7 **对应类结构简图**

```
@Around annotated method
    ↓
ReflectiveAspectJAdvisorFactory
    ↓
→ AspectJAroundAdvice (implements MethodInterceptor)
    ↓
→ Advisor: InstantiationModelAwarePointcutAdvisorImpl
        - Pointcut: AspectJExpressionPointcut
        - Advice: AspectJAroundAdvice
```

## 2.2 代理对象的创建过程
### 2.2.1 判断是否需要被代理
在doCreateBean -> initializeBean -> applyBeanPostProcessorsAfterInitialization 中，AbstractAutoProxyCreator.postProcessAfterInitialization(Object bean, String beanName)的wrapIfNecessary(bean, beanName, cacheKey)判断是否需要代理该 bean。
+ 这里会去查找是否有适配的Advisor，即：getAdvicesAndAdvisorsForBean
```
Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
```
+ 如果存在适配的Advisor，则创建Proxy
### 2.2.2 构造代理对象（ProxyFactory），注入容器
创建对象（ProxyFactory）
``` java
ProxyFactory proxyFactory = new ProxyFactory();
```
并设置属性：
- 目标对象
- 代理接口（如果是接口）
- 所有 `Advisor`
最后调用getProxy()创建代理对象
```
proxyFactory.getProxy()
```
这一步会根据情况选择：
- **JDK 动态代理**（目标类有接口）
- **CGLIB 代理**（类没有接口，或配置强制使用）
代理对象一旦创建，就会替代原始 bean 被注入到容器中。

以Cglib为示例
+ 拦截器生成
``` java
Enhancer enhancer = new Enhancer();
enhancer.setSuperclass(targetClass);
enhancer.setCallback(new DynamicAdvisedInterceptor(...));
```
+ CGLIB 内部就会生成如下结构的字节码（_伪代码，仅为理解_）：
``` java
public class MyService$$EnhancerBySpringCGLIB extends MyService {
    private MethodInterceptor callback;

    public void doSomething() {
        // 实际逻辑：
        callback.intercept(this, doSomethingMethod, args, methodProxy);
    }
}

```
特别说明callBack是
``` java
CglibAopProxy.DynamicAdvisedInterceptor implements MethodInterceptor
```
## 2.3 代理对象的执行
当你调用代理方法（如 `myService.doSomething()`）时，CGLIB 调用：

``` java
DynamicAdvisedInterceptor#intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy)
```

它会干以下事：
1. 获取该方法对应的拦截器链（Advisors → Interceptors）
2. 构造 `ReflectiveMethodInvocation`，封装了目标类、参数、方法、interceptors
3. 执行 `ReflectiveMethodInvocation.proceed()`，责任链依次执行每个 Advice

代理对象和调用链的顺序
``` text
MyService$$EnhancerBySpringCGLIB (代理类)
  └─ doSomething() 方法被重写
       ↓
  DynamicAdvisedInterceptor#intercept()
       ↓
  获取所有 Advisor → 转为 MethodInterceptor 列表
       ↓
  ReflectiveMethodInvocation
       ↓
  拦截器链按顺序执行：
      → AroundAdvice
          → BeforeAdvice
              → 目标方法
          ←
      ←
```

代码查看逻辑，在断点调试或日志中观察：
1. 代理类类名：`MyService$$EnhancerBySpringCGLIB$$xxx`
2. 设置断点在 `DynamicAdvisedInterceptor#intercept` 看拦截器链
3. 看 `ReflectiveMethodInvocation` 中 `interceptorsAndDynamicMethodMatchers` 列表
