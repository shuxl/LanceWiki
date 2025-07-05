# 1 查找方式
+ 单一类型的查找
```
private static void lookupByObjectProvider(AnnotationConfigApplicationContext applicationContext) {  
    ObjectProvider<String> objectProvider =    applicationContext.getBeanProvider(String.class);  
    System.out.println(objectProvider.getObject());  
}
```
+ 集合类型依赖查找接口 - ListableBeanFactory
+ 层次性依赖查找接口 - HierarchicalBeanFactory
		核心接口 getParentBeanFactory()，获取parent。与ConfigurableBeanFactory#setParentBeanFactory结合使用，可以做到获取parent的bean，类似于双亲委派
+ 延迟依赖查找接口
	 org.springframework.beans.factory.ObjectFactory
	 org.springframework.beans.factory.ObjectProvider
# 2 查找的安全性
| 依赖查找类型 | 代表实现                               | 是否安全 |
| ------ | ---------------------------------- | ---- |
| 单一类型查找 | BeanFactory#getBean                | 否    |
|        | ObjectFactory#getObject            | 否    |
|        | ObjectProvider#getIfAvailable      | 是    |
| 集合类型查找 | ListableBeanFactory#getBeansOfType | 是    |
|        | ObjectProvider#stream              | 是    |
