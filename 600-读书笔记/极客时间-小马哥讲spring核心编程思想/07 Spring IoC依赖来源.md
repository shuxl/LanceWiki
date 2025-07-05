+ 依赖查找的来源
+ 依赖注入的来源
+ Spring容器管理和游离对象
+ Spring BeanDefinition 作为依赖来源
+ 单例对象作为依赖来源
+ 非 Spring 容器管理对象作为依赖来源
+ 外部化配置作为依赖来源
# 1 依赖查找的来源
+ Spring BeanDefinition 
	+ \<bean id="user" class="org.geekbang...User"\>
	+ @Bean public User user(){...}
	+ BeanDefinitionBuilder
+ 单例对象 
	+ API 实现
+ Spring 内建 BeanDefintion

| Bean名称                                                                                  | Bean实例                                      | 使用场景                                       |
| --------------------------------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------ |
| org.springframework.context.<br>annotation.internalConfigur<br>ationAnnotationProcessor | ConfigurationClassPostProcesso<br>r 对象      | 处理 Spring 配置类                              |
| org.springframework.context.<br>annotation.internalAutowire<br>dAnnotationProcessor     | AutowiredAnnotationBeanPostPro<br>cessor 对象 | 处理 @Autowired 以及 @Value<br>注解              |
| org.springframework.context.<br>annotation.internalCommonAn<br>notationProcessor        | CommonAnnotationBeanPostProces<br>sor 对象    | （条件激活）处理 JSR-250 注解，<br>如 @PostConstruct 等 |
| org.springframework.context.<br>event.internalEventListener<br>Processor                | EventListenerMethodProcessor<br>对象          | 处理标注 @EventListener 的<br>Spring 事件监听方法     |
+ Spring 内建单例对象

| Bean 名称                   | Bean 实例                            | 使用场景                |
| --------------------------- | ------------------------------------ | ----------------------- |
| environment                 | Environment 对象                     | 外部化配置以及 Profiles |
| systemProperties            | java.util.Properties 对象            | Java 系统属性           |
| systemEnvironment           | java.util.Map 对象                   | 操作系统环境变量        |
| messageSource               | MessageSource 对象                   | 国际化文案              |
| lifecycleProcessor          | LifecycleProcessor 对象              | Lifecycle Bean 处理器   |
| applicationEventMulticaster | ApplicationEventMulticaster 对<br>象 | Spring 事件广播器       |
   
# 2 依赖注入的来源
+ 注入来源

| 来源                    | 配置元数据                                          |
| --------------------- | ---------------------------------------------- |
| Spring BeanDefinition | \<bean id="user" class="org.geekbang...User"\> |
|                       | @Bean public User user(){...}                  |
|                       | BeanDefinitionBuilder                          |
| 单例对象                  | API 实现                                         |
| 非 Spring 容器管理对象       |                                                |

# 3 Spring容器管理和游离对象
+ 依赖对象
 
| 来源                       | Spring Bean 对象 | 生命周期管理 | 配置元信息 | 使用场景      |
| ------------------------ | -------------- | ------ | ----- | --------- |
| Spring<br>BeanDefinition | Y              | Y      | 有     | 依赖查找、依赖注入 |
| 单体对象                     | Y              | N      | 无     | 依赖查找、依赖注入 |
| Resolvable<br>Dependency | N              | N      | 无     | 依赖注入      |
# 4 Spring BeanDefinition 作为依赖来源
+ 要素
	+ 元数据：BeanDefinition
	+ 注册：BeanDefinitionRegistry#registerBeanDefinition
	+ 类型：延迟和非延迟
	+ 顺序：Bean 生命周期顺序按照注册顺序

# 5 单例对象作为依赖来源
+ 要素
	+ 来源：外部普通 Java 对象（不一定是 POJO）
	+ 注册：SingletonBeanRegistry#registerSingleton
+ 限制
	+ 无生命周期管理
	+ 无法实现延迟初始化 Bean

# 6 非 Spring 容器管理对象作为依赖来源
+ 要素
	+ 注册：ConfigurableListableBeanFactory#registerResolvableDependency
+ 限制
	+ 无生命周期管理
	+ 无法实现延迟初始化 Bean
	+ 无法通过依赖查找

# 7 外部化配置作为依赖来源
+ 要素
	+ 类型：非常规 Spring 对象依赖来源
+ 限制
	+ 无生命周期管理
	+ 无法实现延迟初始化 Bean
	+ 无法通过依赖查找