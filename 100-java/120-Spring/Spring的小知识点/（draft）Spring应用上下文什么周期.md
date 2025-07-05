# 1 前言
## 1.1 文章目的
+ 帮助整理面试时的spring上下文的面试思路
+ 帮助自己快速理解Spring上下文的知识
# 2 知识汇总
## 2.1 第一轮汇总
1. 初始化阶段
2. BeanPostProcessor阶段
3. 就绪阶段
4. 销毁阶段
## 2.2 第二轮知识汇总
### 2.2.1 整体阶段说明
#### 2.2.1.1 Spring 应用上下文**启动**准备阶段
+ 方法：AbstractApplicationContext#`prepareRefresh`()
	1. 设置启动时间、状态标识
	2. 初始化 PropertySources - initPropertySources()。默认空实现，在web类型的子类中，会添加自己的实现
		- [x] SpringBoot的initPropertySources实现逻辑
	3. 检验 Environment 中必须属性
	4. 初始化事件监听器集合
		1. 如果集合为空，会new一下
	5. 初始化早期 Spring 事件集合
		1. 强制new一个空集合
+ **总结**：抽象类里面，没有实现啥特殊的逻辑。部分子类可能会对initPropertySources做自己的实现
#### 2.2.1.2 BeanFactory 创建阶段
+ 方法：AbstractApplicationContext#`obtainFreshBeanFactory`()
+ 内部有两个方法：BeanFactory - **refreshBeanFactory()**，BeanFactory - getBeanFactory()
+ refreshBeanFactory步骤（子类**AbstractRefreshableApplicationContex**t）：
	+ 销毁或关闭 BeanFactory，如果已存在的话
	+ 创建 BeanFactory - createBeanFactory()
		- [x] 这里面有一些ignoreDependencyInterface调用不理解（一般帖子都不会介绍这个逻辑，需要自己判断）
	+ 设置 BeanFactory Id
	+ 设置“是否允许 BeanDefinition 重复定义” - customizeBeanFactory(DefaultListableBeanFactory)
	+ 设置“是否允许循环引用（依赖）” - customizeBeanFactory(DefaultListableBeanFactory)
	+ **加载 BeanDefinition** - loadBeanDefinitions(DefaultListableBeanFactory) 抽象方法
		+ 不同的子类有自己的资源加载方式。比如xml和注解他们的源其实是不一样的
			+ [x] 那么有没有哪种实现能使用多种源进行BeanDefinition的加载呢？
	+ **关联**新建 BeanFactory 到 Spring 应用上下文
+ **总结**：新建一个BeanFactory，用loadBeanDefinitions进行BeanDefinition的新建，然后将BeanFactory关键到Spring应用上下文上
	+ BeanFactory 是 `DefaultListableBeanFactory`类型
#### 2.2.1.3 BeanFactory 准备阶段
+ 方法的细节，`prepareBeanFactory`(beanFactory)
	+ **设置类加载器**，关联 ClassLoader
		+ ClassLoader用来帮助做类的注册，比如：xml方式初始化加载的时候，类的信息只是一个文本类型的类的描述而已
		+ beanFactory.setBeanClassLoader(getClassLoader());
		+ [ ] 需要升入了解一下ClassLoader。比如实现一些特殊需求，见232课
	+ **设置表达式语言解析器**，即设置 Bean 表达式处理器
		+ beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()))
		+ SpringEL，不重要
	+ **设置属性编辑器注册器**，添加 PropertyEditorRegistrar 实现 - ResourceEditorRegistrar
		+ 例子：XML的属性进行类型转换时，用到这里的逻辑
		+ [ ] 总结一下PropertyEditorRegistrar
	+ **添加一些默认的后处理器**，添加 Aware 回调接口 BeanPostProcessor 实现 - ApplicationContextAwareProcessor
		+ [ ] 待确认：我的理解是添加一个回调类，这个类里面添加了一些Aware的白名单
	+ **忽略特定接口的自动装配**，即忽略 Aware 回调接口作为依赖注入接口
	+ **自动装配特定类型的依赖项**，注册 `ResolvableDependency` 对象 - BeanFactory、ResourceLoader、ApplicationEventPublisher 以及ApplicationContext
		+ [ ] ResolvableDependency 是个啥？
	+ 注册 ApplicationListenerDetector 对象
	+ 注册 LoadTimeWeaverAwareProcessor 对象
	+ **注册一些内置的 Bean**，即注册单例对象 - Environment、Java System Properties 以及 OS 环境变量
+ **总结**（还需深入理解）：方法的主要目的是为应用上下文中的 Bean 工厂设置基础配置，见上文的加粗地方
	+ [ ] prepareBeanFactory(beanFactory)各个加载类的细节没有融汇起来
#### 2.2.1.4 BeanFactory 后置处理阶段
+ 存在两个方法，下面是简介：
	+ AbstractApplicationContext#`postProcessBeanFactory`(ConfigurableListableBeanFactory) 方法
		+ 由**子类覆盖**该方法
	+ AbstractApplicationContext#`invokeBeanFactoryPostProcessors`(ConfigurableListableBeanFactory 方法
		+ 调用 BeanFactoryPostProcessor 或 BeanDefinitionRegistry 后置处理方法
		+ 注册 LoadTimeWeaverAwareProcessor 对象
+ **方法说明**：
	+ `postProcessBeanFactory`的调用，其实是**子类继承AbstractApplicationContext**后，调用的。这个**在应用开发中不常用，更多的是在框架开发或高级应用场景中使用**
		+  **添加或修改 Bean 定义**：
		    - 子类可以通过这个方法来添加新的 Bean 定义或修改现有的 Bean 定义。例如，可以根据某些条件动态地注册额外的 Bean。
		- **注册额外的 BeanPostProcessor**：
		    - 在实例化 Bean 之前，子类可以通过这个方法注册额外的 `BeanPostProcessor` 实现，以影响 Bean 的创建和初始化过程。
		- **设置特定的 Bean 属性**：
		    - 可以通过直接访问 `ConfigurableListableBeanFactory` 的方法来设置特定的 Bean 属性或依赖项。这在需要全局地影响某些类型的 Bean 时特别有用。
	+ `invokeBeanFactoryPostProcessors`的调用，其实是**通过组合的方式**进行执行的所有被注册的类的相关方法。
		+ 时机：在所有 Bean 定义已经加载完毕，但还没有实例化任何 Bean 之前
		+ 调用什么：调用所有已注册的 `BeanFactoryPostProcessor` 实现类的 `postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory)` 方法。
		+ `BeanFactoryPostProcessor` 是 Spring 的一个接口，它定义了一个 `postProcessBeanFactory` 方法。实现这个接口的类可以通过修改 Bean 的定义来影响 Bean 的创建过程。通常，**这个接口用于以下几种情况**：
			1. **修改 Bean 定义**：可以修改已经注册的 Bean 定义的属性，例如属性值、作用域、初始化方法等。
			2. **添加或删除 Bean 定义**：可以动态地添加新的 Bean 定义或删除现有的 Bean 定义。
			3. **为 Bean 定义设置额外的属性或依赖**：可以为 Bean 设置特定的属性或注入依赖关系
+ **总结**：这个后置处理阶段一般用来做什么？
	+ 添加或修改 Bean 定义。只有postProcessBeanFactory方法可添加Bean的定义
	+ 注册额外的 BeanPostProcessor。只有postProcessBeanFactory方法可实现
	+ 设置特定的 Bean 属性。
#### 2.2.1.5 BeanFactory 注册 BeanPostProcessor 阶段
+ AbstractApplicationContext#`registerBeanPostProcessors`(ConfigurableListableBeanFactory) 方法：
	+ 注册 PriorityOrdered 类型的 BeanPostProcessor Beans
	+ 注册 Ordered 类型的 BeanPostProcessor Beans
	+ 注册普通 BeanPostProcessor Beans
	+ 注册 MergedBeanDefinitionPostProcessor Beans
	+ 注册 ApplicationListenerDetector 对象
+ 用于注册所有实现了 `BeanPostProcessor` 接口的 Bean，这些 `BeanPostProcessor` 可以在 Spring 容器实例化 Bean 之前和之后对 Bean 进行额外的处理和操作。这个机制为开发者提供了极大的灵活性，可以在 Bean 的生命周期中插入自定义逻辑。
+ **总结**：注册所有实现了 `BeanPostProcessor` 接口的 Bean，并将这些Bean添加到 AbstractBeanFactory的List\<BeanPostProcessor\> beanPostProcessors中。
	+ [ ] beanPostProcessors属性在后续的哪个流程中会被用到？
#### 2.2.1.6 初始化內建 Bean：MessageSource
+ 12章
+ AbstractApplicationContext#`initMessageSource`() 方法
+ spring默认只能拿到一个空的bean，里面没有内容
+ 如果要想设置值，需要在前面的“BeanFactory 注册 BeanPostProcessor 阶段”进行处理
	+ [ ] 可以看一下SpringBoot是怎么实现的，有啥特殊性
#### 2.2.1.7 初始化內建 Bean：Spring 事件广播器
+ AbstractApplicationContext#`initApplicationEventMulticaster`() 方法
+ 17章
+ [ ] 事件广播器，完全不知道啊。。。。
#### 2.2.1.8 Spring 应用上下文刷新阶段
+ `onRefresh`方法
+ 默认是空实现，需要子类继承区实现
+ 基本都是web实现类在实现
	![](img/Pasted%20image%2020240728142124.png)
+ **这个方法的实现难度较大**。需要特别了解Spring上下文的生命周期，知道哪些资源可以被使用，哪些资源不能被使用
+ [ ] 有时间看一下ReactiveWebServerApplicationContext的实现，以及**反应式编程模型**的东西
#### 2.2.1.9 Spring 事件监听器注册阶段
+ AbstractApplicationContext#`registerListeners`() 方法
	+ 添加当前应用上下文所关联的 ApplicationListener 对象（集合）
	+ 添加 BeanFactory 所注册 ApplicationListener Beans
		+ 这里只通过`getBeanNamesForType`找到beanName，并不初始化
	+ 广播早期 Spring 事件（如果前面的阶段产生了事件，其实事件是先放在早起Spring事件中的，然后在这个阶段进行广播）
#### 2.2.1.10 BeanFactory 初始化完成阶段Spring 应用上下文生命周期
+ AbstractApplicationContext# `finishBeanFactoryInitialization` (ConfigurableListableBeanFactory) 方法
	+ BeanFactory 关联 ConversionService Bean，如果存在
	+ 添加 StringValueResolver 对象
	+ 依赖查找 LoadTimeWeaverAware Bean
	+ BeanFactory 临时 ClassLoader 置为 null
	+ BeanFactory 冻结配置
	+ BeanFactory 初始化非延迟单例 Beans
+ [ ] 完成阶段的最后一步的内容需要再仔细看看，可以看一下我的UML图
#### 2.2.1.11 Spring 应用上下启动完成阶段
+ `finishRefresh`方法
	+ 清除 ResourceLoader 缓存 - clearResourceCaches() @since 5.0
	+ 初始化 LifecycleProcessor 对象 - initLifecycleProcessor()
	+ 调用 LifecycleProcessor#onRefresh() 方法
	+ 发布 Spring 应用上下文已刷新事件 - ContextRefreshedEvent
	+ 向 MBeanServer 托管 Live Beans
#### 2.2.1.12 Spring 应用上下文启动阶段（非主流程）
+ AbstractApplicationContext#start() 方法
	+ 启动 LifecycleProcessor
		+ 依赖查找 Lifecycle Beans
		+ 启动 Lifecycle Beans
	+ 发布 Spring 应用上下文已启动事件 - ContextStartedEvent
+ 通常应用开发过程中，不接触此方法
+ [ ] Lifecycle 知识点是我的盲区，需要结合视频看，241课
#### 2.2.1.13 Spring 应用上下文停止阶段
+ AbstractApplicationContext#stop() 方法
	+ 停止 LifecycleProcessor
		+ 依赖查找 Lifecycle Beans
		+ 停止 Lifecycle Beans
	+ 发布 Spring 应用上下文已停止事件 - ContextStoppedEvent
+ 总结：和start()方法相反
+ Lifecycle再start和stop中调用的方式都是同步的方式，可以用事件来进行异步方案的替代
+ [ ] spring的事件不了解，需要学习
#### 2.2.1.14 Spring 应用上下文关闭阶段
+ AbstractApplicationContext#close() 方法
	+ 状态标识：active(false)、closed(true)
	+ Live Beans JMX 撤销托管
		+ [ ] JMX 是什么？
	+ LiveBeansView.unregisterApplicationContext(ConfigurableApplicationContext)
	+ 发布 Spring 应用上下文已关闭事件 - ContextClosedEvent
	+ 关闭 LifecycleProcessor
	+ 依赖查找 Lifecycle Beans
	+ 停止 Lifecycle Beans
	+ 销毁 Spring Beans
		+ [ ] 非单例的Bean的创建有何特殊？又是如何被销毁的？
	+ 关闭 BeanFactory
	+ 回调 onClose()
	+ 注册 Shutdown Hook 线程（如果曾注册）
		+ 优雅的关闭的一种实现，其实是一个Thread？
		+ [ ] Shutdown Hook 内部的线程细节需要学习
+ ChatGpt的**总结**：
	1. **更新应用上下文的状态**：
	    - `close()` 方法首先更新应用上下文的状态，设置为“关闭中”（closing）状态，并随后设置为“已关闭”（closed）状态。这些状态标志使得应用上下文能够正确地处理关闭操作，并且阻止进一步的操作。
	2. **停止所有生命周期 Bean**：
	    - 如果应用上下文包含实现了 `Lifecycle` 接口的 Bean，这些 Bean 会在上下文关闭时被停止。`close()` 方法会调用这些 Bean 的 `stop()` 方法，确保所有的生命周期管理的组件（如消息监听器、定时任务等）都能平稳地停止。
	3. **发布 ContextClosedEvent 事件**：
	    - `close()` 方法会发布一个 `ContextClosedEvent` 事件，通知所有监听器应用上下文已经关闭。这对于需要在应用上下文关闭时执行特定逻辑的组件非常有用。
	4. **销毁所有单例 Bean**：
	    - 在上下文关闭过程中，所有的单例 Bean 都会被销毁。这意味着会调用这些 Bean 的 `destroy()` 方法，或使用配置中指定的销毁方法。这个步骤对于释放资源、关闭连接、保存状态等操作至关重要。
	5. **释放资源**：
	    - `close()` 方法会释放与应用上下文相关联的所有资源。这包括关闭资源加载器、移除属性源和解析器等操作。
	6. **清理内部缓存**：
	    - 在关闭过程中，内部的缓存数据（如 Bean 名称、类型等缓存）会被清理，确保应用上下文完全释放资源。
# 3 引用
## 3.1 问ChatGpt

> 问题：介绍 Spring 应用上下文的生命周期

Spring 应用上下文（ApplicationContext）是 Spring 框架的核心部分之一，它管理着 Spring 应用中的所有 Bean 的生命周期和配置。了解应用上下文的生命周期对于开发和调试 Spring 应用非常重要。以下是 Spring 应用上下文生命周期的几个主要阶段:

1. **初始化阶段**：
    - **配置解析**：在应用启动时，Spring 会读取和解析配置文件或注解（如 `applicationContext.xml` 或使用 `@Configuration` 注解的类），以确定应用中需要实例化的 Bean 及其依赖关系。
    - **Bean 实例化**：根据配置，Spring 使用反射机制实例化 Bean。
    - **依赖注入**：Spring 通过构造函数注入、setter 方法注入或者字段注入等方式将 Bean 的依赖注入到相应的 Bean 中。
    - **初始化方法调用**：如果 Bean 实现了 `InitializingBean` 接口，Spring 会调用其 `afterPropertiesSet()` 方法。或者，如果在配置中指定了 `init-method`，Spring 会调用该方法。
2. **BeanPostProcessor 阶段**：
    - BeanPostProcessor 是 Spring 提供的一种机制，可以在 Bean 初始化前后对 Bean 进行处理。实现了 `BeanPostProcessor` 接口的类可以在 Bean 初始化之前和之后执行自定义逻辑。通常用于 Bean 的代理创建或其他自定义初始化逻辑。
3. **就绪阶段**：
    - 在所有 Bean 初始化完成后，Spring 应用上下文进入就绪状态。在这个阶段，Bean 可以处理应用程序的请求或执行相应的业务逻辑。
4. **销毁阶段**：
    - 当应用程序上下文关闭时（例如通过调用 `close()` 方法），Spring 会开始销毁阶段。
    - **销毁方法调用**：如果 Bean 实现了 `DisposableBean` 接口，Spring 会调用其 `destroy()` 方法。或者，如果在配置中指定了 `destroy-method`，Spring 会调用该方法。这个阶段用于释放资源，比如关闭数据库连接、清理缓存等。
5. **应用上下文关闭**：
    - 在销毁所有 Bean 后，Spring 应用上下文完全关闭，此时所有的资源都会被清理。

这些生命周期阶段确保了 Spring 应用能够有条不紊地启动、运行和关闭。开发人员可以通过实现特定接口或配置来定制这些生命周期的各个阶段。