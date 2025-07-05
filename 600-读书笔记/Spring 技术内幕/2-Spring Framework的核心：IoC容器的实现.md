+ Spring IoC容器概述
+ IoC容器系列的设计与实现
+ IoC容器的初始化过程
+ IoC容器的依赖注入
+ 容器其他相关特性的设计与实现

# 1 Spring IoC容器概述

## 1.1 IoC容器和依赖反转模式

+ 依赖反转：如果合作对象的引用或依赖关系的管理由具体对象来完成，会导致代码高度耦合和可测试性降低，如果由非自身对象来实现，则这种模式就叫依赖反转
  + 应用控制反转后，当对象被创建时，由一个调控系统内的所有对象的外界实体将其所依赖的对象的引用传递给它，即依赖被注入到对象中。所以，控制反转是关于一个对象如何获取它所依赖的对象的引用，在这里，反转值得是责任的反转。
  + 通过使用IoC容器，对象依赖关系的管理被反转了，转到IoC容器中来了，对象纸巾啊的相互依赖关系由Ioc容器进行管理，并由IoC容器完成对象的注入。
+ 在Spirng中，IoC容器使实现依赖反转模式的载体。它可以在对象生成或初始化时直接将数据注入到对象中，也可以通过将对象引用注入到对象数据域中的方式来注入对方法调用的依赖。
  + 这种依赖注入时可以递归的，对象被逐层注入
+ 把控制权从具体业务对象手中转交到平台或者框架中，是降低面向对象系统设计复杂性和提高面向对象系统可测试性的一个有效的解决方案。
  + 如果对面向对象系统中的对象进行简单分类，会发现处理一部分时数据对象外，其他很大一部分对象是用来处理数据的。这些对象并补偿发生变化，是系统中基础的部分。这类对象之间的依赖关系也是比较稳定的，一般不会随着应用的运行状态的改变而改变

## 1.2 Spring IoC的应用场景

Spring Ioc提供了一个基本的JavaBean容器，通过Ioc模式管理依赖关系，并通过依赖注入和AOP切面增强了为JavaBean这样的POJO对象赋予事务管理、生命周期管理等基本功能。
在应用开发中，如果使用Ioc容器，把需要引用和调用其他组件的服务对应的资源获取方向反转，让Ioc容器主动管理这些依赖关系，将这些依赖关系注入到组件中，那么会让这些依赖关系的适配和管理更加灵活。主要注入方式为：接口注入，setter注入、构造器注入
在应用管理依赖关系时，通过Ioc容器将控制进行反转，如果耦合关系需要变动，并不需要重新修改和编译Java源代码

# 2 IoC容器系列的设计与实现：BeanFactory和ApplicationContext

在Spring Ioc容器的设计中，我们可以看到两个主要的容器系列，一个是实现BeanFactory接口的简单容器系列，这系列容器只实现了容器的最基本功能；另一个时ApplicationContext应用上下文，它作为容器的高级形态而存在。
应用上下文在简单容器的基础上，增加了许多面向框架的特性，同时对应用环境作了许多适配。

## 2.1 Spring IoC容器系列

BeanFactory定义了Ioc容器的最基本功能规范，同时Spring通过定义BeanDefintion来管理基于Spring的应用中的各种对象以及它们之间的相互依赖关系

## 2.2 Spring IoC 容器的设计

Ioc容器的接口设计图
+ 设计主线一：从接口BeanFactory到HierarchicalBeanFactory，再到ConfigurableBeanFactory。
	+ HierarchicalBeanFactory增加了getParentBeanFactory()接口功能，使BeanFactory具备了双亲IoC容器的管理功能。
	+ ConfigurableBeanFactory定义了一些BeanFactory的配置功能，比如setParentBeanFactory()设置上起IoC容器，通过andBeanPostProcessor()配置Bean后置处理器，等等
+ 设计主线二：以ApplicationContext应用上下文接口为核心的接口设计。从BeanFactory到ListableBeanFactory，再到ApplicationContext，再到WebApplicationContext或者ConfigurableApplicationContext的实现