# 1 生命周期

# 2 生命周期中的核心类关系以及调用时序
需要解决的问题：
1、spring启动的源头是如何开始初始加载的
2、spring的单个bean是使用了哪些资源进行进行准备的
3、spring的bean是如何加载到应用上下文的
4、spring的bean在使用时是怎么查找到的
5、在最新的小马哥课程中，他所介绍的spring类型转换服务是如何加载核心组件以及如何调度到转换核心类的

问题：application加载后，它是如何自启动的
回答：application的构造器里面会主动调用refresh的接口，来进行bean的资源加载和使用
问题来了：refresh的接口做了哪些事情呢？
研究1：查阅网络资料，看一下refresh的的说明：
问题：BeanFactory的代理思想是啥，Spring是如何实现代理逻辑的
回答：spring初始化时会装载所有的相关实现类
问题：spring是如何通过继承实现类，然后实现功能装配的。
回到：spring是通过类型查找的方式找到了需要代理类型的bean
问题：只写了一个类，类继承通用接口，那么它是如何得到值的。spring是如何注册bean的？
回答：继承了BeanFactoryPostProcessor，从而实现了bean的注册
问题：spring的bean注册数据源的各种加载方式是啥
回答：只能了解xml的方式，的确是通过xml的reader来获取资源，然后注册它们的
问题：spring refresh的流程
回答：[（draft）Spring refresh接口的时序说明](（draft）Spring%20refresh接口的时序说明.md)

问题：各种beanfactory的功能说明

问题：课程99课的注解@PostConstruct的注册机制是啥
	即注解的资源是如何注册成为bean信息的
回答：会在稍后的课程中有学习