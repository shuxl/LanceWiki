# 1 依赖注入的模式和类型
## 1.1 手动模式 - 配置或者编程的方式，提前安排注入规则
+ XML 资源配置元信息
+ Java 注解配置元信息
+ API 配置元信息

## 1.2 自动模式 - 实现方提供依赖自动关联的方式，按照内建的注入规则
+ Autowiring （自动绑定）

## 1.3 依赖注入类型

| 依赖注入类型    | 配置元数据举例                                          |
| --------- | ------------------------------------------------ |
| Setter 方法 | \<proeprty name=”user” ref=”userBean” />         |
| 构造器       | \<constructor-arg name="user" ref="userBean" />  |
| 字段        | @Autowired User user;                            |
| 方法        | @Autowired public void user(User user) { ... }   |
| 接口回调      | class MyBean implements BeanFactoryAware { ... } |
# 2 自动绑定的模式

| 模式        | 说明                                                                     |
| ----------- | ------------------------------------------------------------------------ |
| no          | 默认值，未激活 Autowiring，需要手动指定依赖注入对象                      |
| byName      | 根据被注入属性的名称作为 Bean 名称进行依赖查找，并将对象设置到<br>该属性 |
| byType      | 根据被注入属性的类型作为依赖类型进行查找，并将对象设置到该属性           |
| constructor | 特殊 byType 类型，用于构造器参数                                         |

# 3 Setter 方法注入
+ 实现方式
	+ 手动模式
		+ XML 资源配置元信息
		+ Java 注解配置元信息
		+ API 配置元信息
	+ 自动模式
		+ byName
		+ byType
# 4 构造器注入
+ 实现方法
	+ 手动模式
		+ XML 资源配置元信息
		+ Java 注解配置元信息
		+ API 配置元信息
	+ 自动模式
		+ constructor
# 5 字段注入
+ 实现方法
	+ 手动模式
		+ Java 注解配置元信息
			+ @Autowired
			+ @Resource
			+ @Inject（可选）
# 6 方法注入
+ 实现方法
	+ 手动模式
		+ Java 注解配置元信息
			+ @Autowired
			+ @Resource
			+ @Inject（可选）
			+ @Bean
# 7 接口回调注入
+ Aware 系列接口回调
	+ 自动模式
		BeanFactoryAware、ApplicationContextAware、EnvironmentAware、ResourceLoaderAware、BeanClassLoaderAware、BeanNameAware

# 8 限定注入
+ 使用注解 @Qualifier 限定
	+ 通过 Bean 名称限定
	+ 过分组限定
+ 基于注解 @Qualifier 扩展限定
	+ 自定义注解 - 如 Spring Cloud @LoadBalanced


# 9 延迟依赖注入

+ 使用 API ObjectFactory 延迟注入
	+ 单一类型
	+ 集合类型
+ 使用 API ObjectProvider 延迟注入（推荐）
	+ 单一类型
	+ 集合类型

# 10 依赖处理过程
+ 基础知识
	+ 入口 - DefaultListableBeanFactory#resolveDependency
	+ 依赖描述符 - DependencyDescriptor
	+ 自定绑定候选对象处理器 - AutowireCandidateResolver

# 11 @Autowired 注入
- [x] 课程65、66、68需要重新阅读（整理这块代码的流程）
+ @Autowired 注入规则
	+ 非静态字段
	+ 非静态方法
	+ 构造器
+ @Autowired 注入过程
	+ 元信息解析
	+ 依赖查找
	+ 依赖注入（字段、方法）

# 12 @Inject 注入
+ @Inject 注入过程
+ 如果 [JSR-330](../../100-java/100-Java基础/JSR/JSR-330.md) 存在于 ClassPath 中，复用 AutowiredAnnotationBeanPostProcessor 实现

# 13 Java通用注解注入原理
+ CommonAnnotationBeanPostProcessor
	+  注入注解
		+ javax.xml.ws.WebServiceRef
		+ javax.ejb.EJB
		+ javax.annotation.Resource
	+ 生命周期注解
		+ javax.annotation.PostConstruct
		+ javax.annotation.PreDestroy

# 14 自定义依赖注入注解
+ 基于 AutowiredAnnotationBeanPostProcessor 实现
+ 自定义实现
	+ 生命周期处理
		+ InstantiationAwareBeanPostProcessor
		+ MergedBeanDefinitionPostProcessor
	+ 元数据
		+ InjectedElement
		+ InjectionMetadata