+ ObjectFactory的类图，以及如何使用的
+ 延迟查找的问题拆解：
	+ 延迟查找的逻辑
	+ ObjectFactory在延迟查找中的使用方式
# 1 小马哥视频的内容记录
为何说ObjectFactory提供延迟加载:
**原因**
- ObjectFactory（或ObjectProvider）可关联某一类型Bean
- ObjectFactory和ObjectProvider对象在被依赖注入和依赖查询时并未实时查找关联类型的Bean
- 当ObjectFactory（或ObjectProvider）调用getObject()方法时，目标Bean才被依赖查找
**总结**
- ObjectFactory（或ObjectProvider）相当于某一类型Bean依赖查找代理对象

# 2 依赖查找（注入）的Bean会被注入缓存吗
## 2.1 问题解析
1. ​**单例Bean（Singleton）​**：
    - 会被缓存。
    - 缓存位置：`org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#singletonObjects`属性。
2. ​**原型Bean（Prototype）​**：
    - 不会被缓存。
    - 每次依赖查询或依赖注入时，根据BeanDefinition每次创建新的实例。
3. ​**其他作用域的Bean**：
    - ​**request**：每个ServletRequest内部缓存，生命周期维持在每次HTTP请求。
    - ​**session**：每个HttpSession内部缓存，生命周期维持在每个用户HTTP会话。
    - ​**application**：当前Servlet应用内部缓存，生命周期与应用程序相同。
