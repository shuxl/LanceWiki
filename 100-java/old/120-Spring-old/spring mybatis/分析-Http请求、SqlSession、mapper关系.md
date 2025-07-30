非常好，这是一个非常实用的问题。下面我们以你使用的 `mybatis-spring-boot-starter` 为基础，从源码角度详细分析
	多个 MyBatis 的数据库操作（Mapper 方法）共享同一个 SqlSession，绑定在同一个 HTTP 请求上下文中。

我们将从这几个核心点来分析：

---

# 1 🔧 1. **Spring Boot 启动时如何配置 SqlSessionFactory 和 SqlSessionTemplate**

在使用 `mybatis-spring-boot-starter` 时，Spring Boot 会自动配置：

- `SqlSessionFactory`
    
- `SqlSessionTemplate`
    

相关代码位于：

```
org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration
```

该类自动注入：

```java
@Bean
@ConditionalOnMissingBean
public SqlSessionTemplate sqlSessionTemplate(SqlSessionFactory sqlSessionFactory) {
    return new SqlSessionTemplate(sqlSessionFactory);
}
```

> `SqlSessionTemplate` 是对 `SqlSession` 的线程安全包装，核心作用是：**通过 Spring 的事务同步机制（TransactionSynchronizationManager）将 SqlSession 与当前线程绑定**。

---

# 2 🔁 2. **SqlSessionTemplate 是怎么做到“每个请求绑定一个 SqlSession”的？**

这是最关键的点。

在 `SqlSessionTemplate` 中，它并不直接创建 `SqlSession`，而是委托 `SqlSessionUtils.getSqlSession()`：

```java
public class SqlSessionTemplate implements SqlSession {
    ...
    @Override
    public <T> T selectOne(String statement, Object parameter) {
        SqlSession sqlSession = getSqlSession(SqlSession.class);
        try {
            return sqlSession.selectOne(statement, parameter);
        } finally {
            closeSqlSession(sqlSession, SqlSessionFactory);
        }
    }
}
```

## 2.1 关键类：

```java
org.mybatis.spring.SqlSessionUtils
```

里面有这样一段代码：

```java
public static SqlSession getSqlSession(SqlSessionFactory sessionFactory) {
    SqlSessionHolder holder = (SqlSessionHolder) TransactionSynchronizationManager.getResource(sessionFactory);
    if (holder != null && holder.isSynchronizedWithTransaction()) {
        return holder.getSqlSession();
    }
    ...
}
```

## 2.2 ✅ 解读：

- `TransactionSynchronizationManager` 是 Spring 的事务同步上下文管理器。
    
- 会将 `SqlSession` 和当前线程绑定，保存在 `ThreadLocal` 中。
    
- 同一个线程（通常对应一个 HTTP 请求）在同一个事务中，获取的是同一个 `SqlSession`。
    

> 这就保证了：**一次 HTTP 请求期间，通过 Mapper 多次访问数据库，使用的是同一个 SqlSession（n:1）**

---

# 3 🧩 3. Mapper 是如何获取 SqlSession 的？

当你使用如下代码：

```java
@Autowired
private UserMapper userMapper;

userMapper.selectById(1L);
```

这个 `UserMapper` 是 Spring 容器中的一个 bean，是由 `MapperFactoryBean` 创建的代理对象。

```java
public class MapperFactoryBean<T> implements FactoryBean<T> {
    @Override
    public T getObject() throws Exception {
        return getSqlSession().getMapper(this.mapperInterface);
    }
}
```

也就是说：

- `MapperFactoryBean` 从 `SqlSessionTemplate` 获取 Mapper 代理
    
- 所有对 Mapper 方法的调用，都会委托到底层的 `SqlSessionTemplate` 来执行
    

---

# 4 🧵 4. 每个请求为何绑定一个线程？

Spring MVC（或任何基于 Servlet 的框架）默认使用线程池（如 Tomcat 的线程池）来处理请求：

- 每个 HTTP 请求会由一个线程来处理
    
- 这个线程就是我们绑定 SqlSession 的 ThreadLocal 所在的线程
    
- 处理完成后，事务提交或回滚，ThreadLocal 清理
    

---

# 5 ✅ 总结关系图示：

```
HTTP 请求 (1)
    ↓（由 Spring MVC 分配一个线程）
线程 (1)
    ↓（Spring 事务同步机制）
TransactionSynchronizationManager
    ↓
SqlSessionHolder（1）
    ↓
SqlSessionTemplate
    ↓
Mapper 方法调用（n）
```

> ✅ 最终体现为：**一次 HTTP 请求（或一次事务）中，多个 Mapper 方法调用（n）共享一个 SqlSession（1）**
