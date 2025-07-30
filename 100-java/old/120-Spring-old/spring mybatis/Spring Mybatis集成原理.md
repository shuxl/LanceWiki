
# 1 前言

最原始的**MyBatis**的使用，通常有如下几个步骤。
1.  读取配置文件**mybatis-config.xml**构建**SqlSessionFactory**；
2.  通过**SqlSessionFactory**拿到**SqlSession**；
3.  通过**SqlSession**拿到**Mapper**接口的动态代理对象；
4.  通过**Mapper**接口的动态代理对象执行**SQL**语句；
5.  关闭**SqlSession**。

那么当**MyBatis**集成到**Spring**中时，上述的一些对象应该会被**Spring**容器来管理。本篇文章将对**MyBatis**集成到**Spring**中时的关键原理进行学习。

# 2 正文

## 2.1 一. MyBatis关键对象生命周期

在单独使用**MyBatis**时，使用到了几个关键对象，分别是：**SqlSessionFactoryBuilder**，**SqlSessionFactory**，**SqlSession**和**Mapper**接口实例。下面给出这几个关键对象的生命周期。

| 对象                           | 生命周期  | 说明                                                                                                                                                                                 |
| ---------------------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SqlSessionFactoryBuilder** | 方法局部  | 用于创建**SqlSessionFactory**，当**SqlSessionFactory**创建完毕后，就不再需要**SqlSessionFactoryBuilder**了                                                                                           |
| **SqlSessionFactory**        | 应用级别  | 用于创建**SqlSession**，由于每次与数据库进行交互时，需要先获取**SqlSession**，因此**SqlSessionFactory**应该是单例并且与应用生命周期保持一致                                                                                     |
| **SqlSession**               | 请求或操作 | 用于访问数据库，访问前需要通过**SqlSessionFactory**创建本次访问所需的**SqlSession**，访问后需要销毁本次访问使用的**SqlSession**，所以**SqlSession**的生命周期是一次请求的开始到结束                                                          |
| **Mapper**接口实例               | 方法    | **Mapper**接口实例通过**SqlSession**获取，所以**Mapper**接口实例的生命周期最长可以与**SqlSession**相等，同时**Mapper**接口实例的最佳生命周期范围应该是方法范围，即在一个方法中通过**SqlSession**获取到**Mapper**接口实例并执行完逻辑后，该**Mapper**接口实例就应该被丢弃 |

## 2.2 二. 思考几个问题

如果要实现**MyBatis**与**Spring**的集成，那么就需要解决单独使用**MyBatis**时的几个关键对象的生命周期管理，重点考虑**SqlSessionFactory**，**SqlSession**和**Mapper**接口实例。下面罗列出需要思考的问题。

1.  **SqlSessionFactory**在什么时候创建；
2.  **SqlSession**如何获取；
3.  **Mapper**接口实例如何生成。

## 2.3 三. Spring集成MyBatis示例

在**Spring**中集成**MyBatis**，其核心思想就是将单独使用**MyBatis**时的关键对象交给**Spring**容器管理，下面看一下**Spring**集成**MyBatis**时的配置类，如下所示。

```java
@Configuration
@ComponentScan(value = "扫描包路径")
public class MybatisConfig {

    @Bean
    public SqlSessionFactoryBean sqlSessionFactory() throws Exception{
        SqlSessionFactoryBean sqlSessionFactoryBean = new SqlSessionFactoryBean();
        sqlSessionFactoryBean.setDataSource(pooledDataSource());
        sqlSessionFactoryBean.setConfigLocation(new ClassPathResource("Mybatis配置文件名"));
        return sqlSessionFactoryBean;
    }

    @Bean
    public MapperScannerConfigurer mapperScannerConfigurer(){
        MapperScannerConfigurer msc = new MapperScannerConfigurer();
        msc.setBasePackage("映射接口包路径");
        return msc;
    }

    // 创建一个数据源
    private PooledDataSource pooledDataSource() {
        PooledDataSource dataSource = new PooledDataSource();
        dataSource.setUrl("数据库URL地址");
        dataSource.setUsername("数据库用户名");
        dataSource.setPassword("数据库密码");
        dataSource.setDriver("数据库连接驱动");
        return dataSource;
    }

}
```

如上所示，**Spring**集成**MyBatis**时，需要向容器注册**SqlSessionFactoryBean**（实际就是注册**SqlSessionFactory**）和**MapperScannerConfigurer**的**bean**实例，那么下面就从这两个对象开始分析，**Spring**是如何集成**MyBatis**的。

## 2.4 四. SqlSessionFactory的创建源码分析

**SqlSessionFactoryBean**类图如下所示。
![](img/Pasted%20image%2020250603132021.png)

重点关心**SqlSessionFactoryBean**实现的**InitializingBean**和**FactoryBean**接口。首先是**InitializingBean**接口，在**SqlSessionFactoryBean**的初始化阶段会调用到**SqlSessionFactoryBean**实现的**afterPropertiesSet()** 方法，实现如下。

```csharp
public void afterPropertiesSet() throws Exception {
    
    // ......

    // 创建SqlSessionFactory
    this.sqlSessionFactory = buildSqlSessionFactory();
}
```

在**SqlSessionFactoryBean**的**afterPropertiesSet()** 方法中会调用到**buildSqlSessionFactory()** 方法来创建**SqlSessionFactory**，**buildSqlSessionFactory()** 方法顾名思义，就是创建**SqlSessionFactory**，由于该方法很长，就不贴出其实现，总的步骤概括如下。

1.  创建**XMLConfigBuilder**；
2.  使用**XMLConfigBuilder**解析**MyBatis**配置文件，得到**MyBatis**全局配置类**Configuration**；
3.  使用**SqlSessionFactoryBuilder**基于**Configuration**创建**SqlSessionFactory**。

在得到**SqlSessionFactory**后就会将其赋值给**SqlSessionFactoryBean**的**sqlSessionFactory**字段。现在又已知**SqlSessionFactoryBean**实现了**FactoryBean**接口，那么**SqlSessionFactoryBean**实际作用是构建复杂的**bean**，这个复杂的**bean**通过**SqlSessionFactoryBean**的**getObject()** 方法获取，实现如下。

```kotlin
public SqlSessionFactory getObject() throws Exception {
    if (this.sqlSessionFactory == null) {
        afterPropertiesSet();
    }

    return this.sqlSessionFactory;
}
```

那么**SqlSessionFactoryBean**的作用实际就是解析配置文件并构建得到**SqlSessionFactory**，并最终将**SqlSessionFactory**放入**Spring**容器中。

## 2.5 五. SqlSession和Mapper实例创建源码分析

通过分析**SqlSessionFactoryBean**知道了**SqlSessionFactoryBean**会构建**SqlSessionFactory**并放到**Spring**容器中，那么有了**SqlSessionFactory**，现在要和数据库交互还需要**SqlSession**以及**Mapper**接口实例，但是如果只是单纯的将**SqlSession**和**Mapper**接口实例创建出来并放入**Spring**容器，那么肯定会引入线程不安全的问题，所以在**Spring**集成**MyBatis**中，肯定对**SqlSession**和**Mapper**接口实例有特殊处理，所以下面继续分析**MapperScannerConfigurer**， 来探究**Spring**如何管理**SqlSession**和**Mapper**接口实例。

**MapperScannerConfigurer**的类图如下所示。
![](img/Pasted%20image%2020250603133417.png)

由类图可知，**MapperScannerConfigurer**其实是一个**bean**工厂后置处理器，其会扫描配置的包路径下的所有**Mapper**接口并为这些**Mapper**接口生成**BeanDefinition**并缓存起来，为接口生成**BeanDefinition**，那么**MyBatis**肯定做了特殊处理，才能够让**Mapper**接口对应的**BeanDefinition**也能够创建**bean**，所以下面看一下**MapperScannerConfigurer**的**postProcessBeanDefinitionRegistry()** 方法的实现，如下所示。

```kotlin
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
    if (this.processPropertyPlaceHolders) {
        processPropertyPlaceHolders();
    }

    ClassPathMapperScanner scanner = new ClassPathMapperScanner(registry);
    scanner.setAddToConfig(this.addToConfig);
    scanner.setAnnotationClass(this.annotationClass);
    scanner.setMarkerInterface(this.markerInterface);
    scanner.setSqlSessionFactory(this.sqlSessionFactory);
    scanner.setSqlSessionTemplate(this.sqlSessionTemplate);
    scanner.setSqlSessionFactoryBeanName(this.sqlSessionFactoryBeanName);
    scanner.setSqlSessionTemplateBeanName(this.sqlSessionTemplateBeanName);
    scanner.setResourceLoader(this.applicationContext);
    scanner.setBeanNameGenerator(this.nameGenerator);
    scanner.setMapperFactoryBeanClass(this.mapperFactoryBeanClass);
    if (StringUtils.hasText(lazyInitialization)) {
        scanner.setLazyInitialization(Boolean.valueOf(lazyInitialization));
    }
    if (StringUtils.hasText(defaultScope)) {
        scanner.setDefaultScope(defaultScope);
    }
    scanner.registerFilters();
    // 委托给ClassPathBeanDefinitionScanner进行扫描得到BeanDefinition
    // 然后ClassPathMapperScanner对得到的BeanDefinition进行特殊处理
    scanner.scan(
        StringUtils.tokenizeToStringArray(this.basePackage, 
            ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS));
}
```

**MapperScannerConfigurer**将扫描指定包并得到**BeanDefinition**的逻辑委托给了**ClassPathBeanDefinitionScanner**，然后又在**ClassPathMapperScanner**中完成了对**Mapper**接口对应的**BeanDefinition**的特殊处理，特殊处理的方法在**ClassPathMapperScanner**的**processBeanDefinitions()** 方法中，由于该方法也特别长，下面仅将关键部分罗列出来。

```kotlin
AbstractBeanDefinition definition;

// ......

// 将bean的Class对象设置为MapperFactoryBean的Class对象
definition.setBeanClass(this.mapperFactoryBeanClass);
```

**其实processBeanDefinitions()中的特殊处理最关键的就是`将BeanDefinition的Class对象设置为了MapperFactoryBean.class`**，那么后续基于所有**Mapper**接口的**BeanDefinition**来创建**bean**时，创建出来的**bean**的类型为**MapperFactoryBean**，下面先看一下**MapperFactoryBean**的类图。

![](img/Pasted%20image%2020250603133655.png)

通过类图可以发现，**MapperFactoryBean**中有一个**sqlSessionFactory**属性字段，其类型就是**SqlSessionFactory**，那么在**MapperFactoryBean**的生命周期的**属性注入**阶段，会调用到**MapperFactoryBean**的**setSqlSessionFactory()** 方法来设置**sqlSessionFactory**属性字段的值，但其实**MapperFactoryBean**和其父类中是没有**sqlSessionFactory**属性字段的，但是却提供了**sqlSessionFactory**属性字段的**get()** 和**set()** 方法，那么这样做的用意是什么呢，继续看**setSqlSessionFactory()** 方法以寻求答案，**setSqlSessionFactory()** 方法在**MapperFactoryBean**的父类**SqlSessionDaoSupport**中，如下所示。

```kotlin
// 入参的SqlSessionFactory就是容器中的SqlSessionFactory
public void setSqlSessionFactory(SqlSessionFactory sqlSessionFactory) {
    if (this.sqlSessionTemplate == null || sqlSessionFactory != this.sqlSessionTemplate.getSqlSessionFactory()) {
        this.sqlSessionTemplate = createSqlSessionTemplate(sqlSessionFactory);
    }
}
```

现在知道，**setSqlSessionFactory()** 方法设置**sqlSessionFactory**属性字段是假，设置**sqlSessionTemplate**属性字段才是真。**sqlSessionTemplate**属性字段类型是**SqlSessionTemplate**，在上面的**setSqlSessionFactory()** 方法中，会先创建一个**SqlSessionTemplate**对象，然后赋值给**sqlSessionTemplate**属性字段，创建**SqlSessionTemplate**对象的逻辑会一路调用到**SqlSessionTemplate**的如下构造方法，实现如下。

```kotlin
public SqlSessionTemplate(SqlSessionFactory sqlSessionFactory, ExecutorType executorType,
    PersistenceExceptionTranslator exceptionTranslator) {

    // ......

    // 将SqlSessionFactory赋值给SqlSessionTemplate的sqlSessionFactory字段
    this.sqlSessionFactory = sqlSessionFactory;
    this.executorType = executorType;
    this.exceptionTranslator = exceptionTranslator;
    // sqlSessionProxy字段类型是SqlSession，并且是一个动态代理对象
    this.sqlSessionProxy = (SqlSession) newProxyInstance(SqlSessionFactory.class.getClassLoader(),
        new Class[] { SqlSession.class }, new SqlSessionInterceptor());
}
```

到这里就知道了，每个**Mapper**接口在容器中的**bean**实际是一个**MapperFactoryBean**对象（暂且这么认为，因为**MapperFactoryBean**实际上还是一个**FactoryBean**，它实际会将其**getObject()** 方法的返回值作为**Mapper**接口在容器中的**bean**，这个**bean**就是**MyBatis**为**Mapper**接口生成的动态代理对象，这一点后面再分析），每创建一个**MapperFactoryBean**对象都会**new**一个**SqlSessionTemplate**对象，每**new**一个**SqlSessionTemplate**对象，就会通过**JDK**动态代理生成一个**SqlSession**的动态代理对象，那么现在再看一下**SqlSession**的动态代理对象中的**InvocationHandler**（实际为**SqlSessionInterceptor**）的**invoke()** 方法的逻辑，如下所示。

```kotlin
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    // 从Spring事务管理器获取SqlSession
    // 如果当前存在事务，则从当前事务中获取SqlSession
    // 如果获取到的SqlSession为空，则通过SqlSessionFactory新建一个SqlSeesion，并将这个SqlSeesion与事务同步
    SqlSession sqlSession = getSqlSession(SqlSessionTemplate.this.sqlSessionFactory,
        SqlSessionTemplate.this.executorType, SqlSessionTemplate.this.exceptionTranslator);
    try {
        // 这里没有执行被代理的SqlSession的方法
        // 而是执行从Spring事务管理器获取到的SqlSession的方法
        Object result = method.invoke(sqlSession, args);
        if (!isSqlSessionTransactional(sqlSession, SqlSessionTemplate.this.sqlSessionFactory)) {
            // 如果SqlSession不由Spring事务管理器管理，则这里在关闭SqlSession前主动提交一次事务
            sqlSession.commit(true);
        }
        return result;
    } catch (Throwable t) {
        Throwable unwrapped = unwrapThrowable(t);
        if (SqlSessionTemplate.this.exceptionTranslator != null && unwrapped instanceof PersistenceException) {
            closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
            sqlSession = null;
            Throwable translated = SqlSessionTemplate.this.exceptionTranslator
                .translateExceptionIfPossible((PersistenceException) unwrapped);
            if (translated != null) {
                unwrapped = translated;
            }
        }
        throw unwrapped;
    } finally {
        if (sqlSession != null) {
            // 如果SqlSession不由Spring事务管理器管理，则在这里关闭SqlSession
            closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
        }
    }
}
```

上述**invoke()** 方法中的逻辑是，每次调用到**invoke()** 方法，都会从**Spring**事务管理器获取**SqlSession**，然后执行获取到的**SqlSession**的方法，并且**invoke()** 方法的最后还会对获取到的**SqlSession**执行关闭逻辑，那么这里就知道了两件事情。

1.  被代理的**SqlSession**并没有被调用，每次**invoke()** 方法中调用的都是从**Spring**事务管理器中获取的**SqlSession**；
2.  **SqlSession**的关闭不需要用户操心，每次使用完都会在**invoke()** 方法的最后被关闭。

那么现在只差最后一步，就可以看清楚**Spring**集成**MyBatis**的整体逻辑了，那就是上面提到**MapperFactoryBean**对象，现在已经知道**Mapper**接口在容器中的**bean**是一个**MapperFactoryBean**对象，但是其实**MapperFactoryBean**还实现了**FactoryBean**接口，那么**Mapper**接口在容器中的**bean**实际是**MapperFactoryBean**的**getObject()** 方法的返回值，下面看一下**MapperFactoryBean**的**getObject()** 方法的实现。

```csharp
public T getObject() throws Exception {
    return getSqlSession().getMapper(this.mapperInterface);
}

public SqlSession getSqlSession() {
    return this.sqlSessionTemplate;
}
```

继续看**SqlSessionTemplate**的**getMapper()** 方法，如下所示。

```typescript
public <T> T getMapper(Class<T> type) {
    return getConfiguration().getMapper(type, this);
}
```

**SqlSessionTemplate**的**getMapper()** 方法其实和**DefaultSqlSession**的**getMapper()** 方法一样，就是通过**Configuration**的**getMapper()** 方法为**Mapper**接口生成动态代理对象，那么现在知道了，**Spring**集成**MyBatis**后，**MyBatis**还是会为每个**Mapper**接口生成一个动态代理对象并注册到**Spring**容器中让**Spring**管理，那么这里**Mapper**接口的动态代理对象与单独使用**MyBatis**时的动态代理对象有什么不同，可以概括如下。

1.  **`原始使用MyBatis时`**，**Mapper**接口的动态代理对象中的**SqlSession**是通过**SqlSessionFactory**创建出来的**DefaultSqlSession**；
2.  **`Spring集成MyBatis后`**，**Mapper**接口的动态代理对象中的**SqlSession**是**SqlSessionTemplate**，而**SqlSessionTemplate**会将请求转发给其持有的**sqlSessionProxy**，**sqlSessionProxy**是**SqlSession**的动态代理对象，每次调用到**sqlSessionProxy**的方法时，都会在**sqlSessionProxy**的**InvocationHandler**的**invoke()** 方法中从**Spring**事务管理器中获取**SqlSession**，并最终调用从**Spring**事务管理器中获取到的**SqlSession**的方法。

那么到这里，**Spring**集成**MyBatis**的整体逻辑就分析完毕。

## 2.6 六. 问题回答

### 2.6.1 1\. SqlSessionFactory在什么时候创建

通过**SqlSessionFactoryBean**在**Spring**容器初始化阶段生成**SqlSessionFactory**的**bean**并注册到**Spring**容器中。

### 2.6.2 2\. SqlSession如何获取

见问题3。

### 2.6.3 3\. Mapper接口实例如何生成

**Mapper**接口的实例由**MapperFactoryBean**的**getObject()** 方法生成，本质还是**MyBatis**通过**Configuration**的**getMapper()** 方法为**Mapper**接口生成动态代理对象，每个**Mapper**接口的动态代理对象由**Spring**容器管理，并且**Mapper**接口的动态代理对象持有的**SqlSession**实际为**SqlSessionTemplate**。

当调用**Mapper**接口的动态代理对象的方法时，会调用到**SqlSessionTemplate**的方法，然后**SqlSessionTemplate**将调用转发到**SqlSessionTemplate**持有的**SqlSession**的动态代理对象，然后调用到**SqlSession**的动态代理对象**InvocationHandler**的**invoke()** 方法，在**invoke()** 方法中会生成**SqlSession**，所以**SqlSession**的生成是在**Mapper**接口的实例的方法被调用时，且每次调用都会生成一个**SqlSession**。

# 3 总结

**Spring**集成**Mybatis**时，有几个关键对象，弄清楚这几个关键对象，也就清楚是如何集成的了。

1.  **SqlSessionFactoryBean**

该对象用于向**Spring**容器注册**SqlSessionFactory**的**bean**，所以**Spring**集成**MyBatis**时，**`SqlSessionFactory存在于Spring容器中，生命周期与Spring应用一致`**。

2.  **MapperFactoryBean**

该对象用于为**Mapper**接口生成动态代理对象，首先是调用到**MapperFactoryBean**的**getObject()** 方法，然后调用到**SqlSessionTemplate**的**getMapper()** 方法，然后调用到**Configuration**的**getMapper()** 方法，后续就是**MyBatis**为**Mapper**接口生成动态代理对象的逻辑了。

3.  **SqlSessionTemplate**

该对象由**MapperFactoryBean**持有，每个**Mapper**接口对应一个**MapperFactoryBean**对象，每个**MapperFactoryBean**对象对应一个**SqlSessionTemplate**对象，每个**SqlSessionTemplate**对象持有**全局唯一**的**SqlSessionFactory**对象和一个**SqlSession**的动态代理对象**sqlSessionProxy**，**SqlSessionTemplate**的所有**CURD**操作都是转发给**sqlSessionProxy**。

4.  **SqlSessionInterceptor**

**SqlSessionTemplate**持有的**SqlSession**的动态代理对象的**InvocationHandler**就是一个**SqlSessionInterceptor**对象，该对象的**invoke()** 方法会在每次被调用时创建一个**SqlSession**，然后执行创建出来的**SqlSession**的方法，并且在**invoke()** 方法的最后会关闭创建出来的**SqlSession**。

所以**Spring**集成**MyBatis**后，应用程序可以通过注解注入**Mapper**接口的实例，注入的**Mapper**接口的实例实际为**MyBatis**为**Mapper**接口生成的动态代理对象，调用**Mapper**接口的实例的方法时，调用请求会发送到**SqlSessionTemplate**，然后**SqlSessionTemplate**会将调用请求转发到**sqlSessionProxy**，然后在**sqlSessionProxy**的**InvocationHandler**的**invoke()** 方法中创建**SqlSession**，然后调用创建出来的**SqlSession**的方法，调用完毕后，会在**InvocationHandler**的**invoke()** 方法最后关闭创建出来的**SqlSession**，**`所以SqlSession的生命周期也是一次请求从开始到结束`**。

**Spring**集成**MyBatis**后，调用**Mapper**接口的动态代理对象的一次请求时序图如下。

![请求时序图](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6a16b64b742b4e04b5f8faacd325c796~tplv-k3u1fbpfcp-jj-mark:3024:0:0:0:q75.jpg#?w=2453&h=1189&s=223680&e=jpg&b=fefbfb)
