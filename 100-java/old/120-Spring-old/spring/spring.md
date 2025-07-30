生命周期执行的过程如下:
    1) spring对bean进行实例化,默认bean是单例
    2) spring对bean进行依赖注入,设置对象属性
    检查Aware相关接口，并设置相关依赖
        3) 如果bean实现了BeanNameAware接口,spring将bean的id传给setBeanName()方法
        4) 如果bean实现了BeanFactoryAware接口,spring将调用setBeanFactory方法,将BeanFactory实例传进来
        5) 如果bean实现了ApplicationContextAware()接口,spring将调用setApplicationContext()方法将应用上下文的引用传入
    前置处理检查
        6) 如果bean实现了BeanPostProcessor接口,spring将调用它们的postProcessBeforeInitialization接口方法
        7) 如果bean实现了InitializingBean接口,spring将调用它们的afterPropertiesSet接口方法,类似的如果bean使用了init-method属性声明了初始化方法,改方法也会被调用
        8) 如果bean实现了BeanPostProcessor接口,spring将调用它们的postProcessAfterInitialization接口方法
    bean使用
    9) 此时bean已经准备就绪,可以被应用程序使用了,他们将一直驻留在应用上下文中,直到该应用上下文被销毁
    销毁（单例会随着上下文销毁而distroy）
    10) 若bean实现了DisposableBean接口,spring将调用它的distroy()接口方法。同样的,如果bean使用了destroy-method属性声明了销毁方法,则该方法被调用
    》总结如下
        Bean自身的方法 : 配置文件中的init-method和destroy-method配置的方法、Bean对象自己调用的方法;
        Bean级生命周期接口方法 : BeanNameAware、BeanFactoryAware、InitializingBean、DiposableBean等接口中的方法;
        容器级生命周期接口方法 : InstantiationAwareBeanPostProcessor、BeanPostProcessor等后置处理器实现类中重写的方法

Spring MVC 概述
    1.客户端（浏览器）发送请求，直接请求到DispatcherServlet（前端控制器）。
    2.DispatcherServlet根据请求信息调用HandlerMapping，解析请求对应的Handler。
    3.解析到对应的Handler（也就是我们平常说的Controller控制器）。
    4.HandlerAdapter会根据Handler来调用真正的处理器来处理请求和执行相对应的业务逻辑。
    5.处理器处理完业务后，会返回一个ModelAndView对象，Model是返回的数据对象，View是逻辑上的View。
    6.ViewResolver会根据逻辑View去查找实际的View。
    7.DispatcherServlet把返回的Model传给View（视图渲染）。
    8.把View返回给请求者（浏览器）。

Spring 设计模式
    1.工厂设计模式：Spring使用工厂模式通过BeanFactory和ApplicationContext创建bean对象。
    2.代理设计模式：Spring AOP功能的实现。
    3.单例设计模式：Spring中的bean默认都是单例的。
    4.模板方法模式：Spring中的jdbcTemplate、hibernateTemplate等以Template结尾的对数据库操作的类，它们就使用到了模板模式。
    5.包装器设计模式：我们的项目需要连接多个数据库，而且不同的客户在每次访问中根据需要会去访问不同的数据库。这种模式让我们可以根据客户的需求能够动态切换不同的数据源。
    6.观察者模式：Spring事件驱动模型就是观察者模式很经典的一个应用。
    7.适配器模式：Spring AOP的增强或通知（Advice）使用到了适配器模式、Spring MVC中也是用到了适配器模式适配Controller。

Srping 事务隔离级别
    ISOLATION_DEFAULT：使用后端数据库默认的隔离级别，Mysql默认采用的REPEATABLE_READ隔离级别；Oracle默认采用的READ_COMMITTED隔离级别。
    ISOLATION_READ_UNCOMMITTED：最低的隔离级别，允许读取尚未提交的数据变更，可能会导致脏读、幻读或不可重复读。
    ISOLATION_READ_COMMITTED：允许读取并发事务已经提交的数据，可以阻止脏读，但是幻读或不可重复读仍有可能发生
    ISOLATION_REPEATABLE_READ：对同一字段的多次读取结果都是一致的，除非数据是被本身事务自己所修改，可以阻止脏读和不可重复读，但幻读仍有可能发生。
    ISOLATION_SERIALIZABLE：最高的隔离级别，完全服从ACID的隔离级别。所有的事务依次逐个执行，这样事务之间就完全不可能产生干扰，也就是说，该级别可以防止脏读、不可重复读以及幻读。但是这将严重影响程序的性能。通常情况下也不会用到该级别。

Spring 事务传播行为
    支持当前事务的情况：
        PROPAGATION_REQUIRED：如果当前存在事务，则加入该事务；如果当前没有事务，则创建一个新的事务。
        PROPAGATION_SUPPORTS：如果当前存在事务，则加入该事务；如果当前没有事务，则以非事务的方式继续运行。
        PROPAGATION_MANDATORY：如果当前存在事务，则加入该事务；如果当前没有事务，则抛出异常。（mandatory：强制性）。
    不支持当前事务的情况：
        PROPAGATION_REQUIRES_NEW： 创建一个新的事务，如果当前存在事务，则把当前事务挂起。
        PROPAGATION_NOT_SUPPORTED： 以非事务方式运行，如果当前存在事务，则把当前事务挂起。
        PROPAGATION_NEVER： 以非事务方式运行，如果当前存在事务，则抛出异常。
    其他情况：
        PROPAGATION_NESTED： 如果当前存在事务，则创建一个事务作为当前事务的嵌套事务来运行；如果当前没有事务，则该取值等价于PROPAGATION_REQUIRED。