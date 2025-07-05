# 1 自己扩展PropertyEditorSupport的类型转换器要如何注册到Spring容器中的？
# 2 注册和调用的实现逻辑是啥呢？

# 3 converServiceFactory是用在哪里
GenericConversionService 在 convert 的时候，进行数据转换
# 4 值转换的时候，调用的内部细节。怎么找到实现类进行转换的
也是factory做的conver
可以试着从另一个方向解答，就是类型转换有哪些关键类，这些类是如何组装和调用的？
那么先画时序图吧？》〉》〉》〉
## 4.1 时序图描述
转换自定义类型：
1. AbstractAutowireCapableBeanFactory#applyPropertyValues
	1. convertForProperty
		1. beanWrapper.convertForProperty(value, propertyName)
			1. convertIfNecessary(propertyName, oldValue, newValue, td.getType(), td)
			2. typeConverterDelegate.convertIfNecessary(propertyName, oldValue, newValue, requiredType, td)
				1. conversionService.canConvert(sourceTypeDesc, typeDescriptor)
				2. conversionService.convert(newValue, sourceTypeDesc, typeDescriptor)
# 5 TypeDescriptor 是个啥东西
在org.springframework.beans.BeanWrapperImpl#convertForProperty方法中，有使用。可以作为参考
# 6 设计模式的各种高端设计，我不大懂了
