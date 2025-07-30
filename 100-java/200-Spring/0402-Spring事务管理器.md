# 1 重点
- PlatformTransactionManager接口体系
- 各种事务管理器的实现原理
- 事务管理器的配置和使用
- 事务管理器的选择策略

# 2 事务管理器概念或介绍

## 2.1 什么是事务管理器
事务管理器（Transaction Manager）是Spring事务管理的核心组件，负责管理事务的生命周期，包括事务的开始、提交、回滚等操作。Spring提供了多种事务管理器实现，以适应不同的数据访问技术。

## 2.2 PlatformTransactionManager接口
所有Spring事务管理器都实现了`PlatformTransactionManager`接口：

```java
public interface PlatformTransactionManager {
    // 获取事务状态
    TransactionStatus getTransaction(TransactionDefinition definition);
    
    // 提交事务
    void commit(TransactionStatus status);
    
    // 回滚事务
    void rollback(TransactionStatus status);
}
```

# 3 常用事务管理器

## 3.1 DataSourceTransactionManager
数据源事务管理器，用于管理JDBC事务。

### 3.1.1 特点
- 适用于单个数据源的事务管理
- 基于JDBC Connection的事务
- 轻量级，性能好

### 3.1.2 实现原理
```java
public class DataSourceTransactionManager extends AbstractPlatformTransactionManager {
    
    @Override
    protected Object doGetTransaction() {
        DataSourceTransactionObject txObject = new DataSourceTransactionObject();
        txObject.setDataSource(this.dataSource);
        return txObject;
    }
    
    @Override
    protected void doBegin(Object transaction) {
        DataSourceTransactionObject txObject = (DataSourceTransactionObject) transaction;
        Connection con = null;
        
        try {
            // 获取数据库连接
            con = this.dataSource.getConnection();
            
            // 设置自动提交为false
            if (con.getAutoCommit()) {
                con.setAutoCommit(false);
            }
            
            // 绑定连接到当前线程
            txObject.setConnectionHolder(new ConnectionHolder(con));
            txObject.setDataSource(this.dataSource);
            
            // 注册到事务同步管理器
            TransactionSynchronizationManager.bindResource(
                this.dataSource, txObject.getConnectionHolder());
        } catch (SQLException ex) {
            throw new CannotCreateTransactionException(
                "Could not begin JDBC transaction", ex);
        }
    }
    
    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        DataSourceTransactionObject txObject = (DataSourceTransactionObject) status.getTransaction();
        Connection con = txObject.getConnectionHolder().getConnection();
        
        try {
            con.commit();
        } catch (SQLException ex) {
            throw new TransactionSystemException("Could not commit JDBC transaction", ex);
        }
    }
    
    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        DataSourceTransactionObject txObject = (DataSourceTransactionObject) status.getTransaction();
        Connection con = txObject.getConnectionHolder().getConnection();
        
        try {
            con.rollback();
        } catch (SQLException ex) {
            throw new TransactionSystemException("Could not roll back JDBC transaction", ex);
        }
    }
}
```

### 3.1.3 配置示例
```xml
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <property name="dataSource" ref="dataSource"/>
</bean>
```

```java
@Configuration
@EnableTransactionManagement
public class TransactionConfig {
    
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

## 3.2 JpaTransactionManager
JPA事务管理器，用于管理JPA/Hibernate事务。

### 3.2.1 特点
- 适用于JPA/Hibernate应用
- 支持实体管理器的事务管理
- 自动处理实体管理器的生命周期

### 3.2.2 实现原理
```java
public class JpaTransactionManager extends AbstractPlatformTransactionManager {
    
    @Override
    protected Object doGetTransaction() {
        JpaTransactionObject txObject = new JpaTransactionObject();
        txObject.setEntityManagerHolder(new EntityManagerHolder());
        return txObject;
    }
    
    @Override
    protected void doBegin(Object transaction) {
        JpaTransactionObject txObject = (JpaTransactionObject) transaction;
        EntityManager em = null;
        
        try {
            // 获取实体管理器
            em = this.entityManagerFactory.createEntityManager();
            
            // 开始事务
            em.getTransaction().begin();
            
            // 绑定实体管理器到当前线程
            txObject.getEntityManagerHolder().setEntityManager(em);
            txObject.getEntityManagerHolder().setTransactionActive(true);
            
            // 注册到事务同步管理器
            TransactionSynchronizationManager.bindResource(
                this.entityManagerFactory, txObject.getEntityManagerHolder());
        } catch (Exception ex) {
            throw new CannotCreateTransactionException(
                "Could not begin JPA transaction", ex);
        }
    }
    
    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        JpaTransactionObject txObject = (JpaTransactionObject) status.getTransaction();
        EntityManager em = txObject.getEntityManagerHolder().getEntityManager();
        
        try {
            em.getTransaction().commit();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not commit JPA transaction", ex);
        }
    }
    
    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        JpaTransactionObject txObject = (JpaTransactionObject) status.getTransaction();
        EntityManager em = txObject.getEntityManagerHolder().getEntityManager();
        
        try {
            em.getTransaction().rollback();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not roll back JPA transaction", ex);
        }
    }
}
```

### 3.2.3 配置示例
```xml
<bean id="transactionManager" class="org.springframework.orm.jpa.JpaTransactionManager">
    <property name="entityManagerFactory" ref="entityManagerFactory"/>
</bean>
```

```java
@Configuration
@EnableTransactionManagement
public class JpaTransactionConfig {
    
    @Bean
    public PlatformTransactionManager transactionManager(EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }
}
```

## 3.3 HibernateTransactionManager
Hibernate事务管理器，专门用于Hibernate ORM框架。

### 3.3.1 特点
- 专门为Hibernate设计
- 支持Hibernate的Session管理
- 自动处理Session的生命周期

### 3.3.2 实现原理
```java
public class HibernateTransactionManager extends AbstractPlatformTransactionManager {
    
    @Override
    protected Object doGetTransaction() {
        HibernateTransactionObject txObject = new HibernateTransactionObject();
        txObject.setSessionHolder(new SessionHolder());
        return txObject;
    }
    
    @Override
    protected void doBegin(Object transaction) {
        HibernateTransactionObject txObject = (HibernateTransactionObject) transaction;
        Session session = null;
        
        try {
            // 获取Hibernate Session
            session = this.sessionFactory.openSession();
            
            // 开始事务
            session.beginTransaction();
            
            // 绑定Session到当前线程
            txObject.getSessionHolder().setSession(session);
            txObject.getSessionHolder().setTransactionActive(true);
            
            // 注册到事务同步管理器
            TransactionSynchronizationManager.bindResource(
                this.sessionFactory, txObject.getSessionHolder());
        } catch (Exception ex) {
            throw new CannotCreateTransactionException(
                "Could not begin Hibernate transaction", ex);
        }
    }
    
    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        HibernateTransactionObject txObject = (HibernateTransactionObject) status.getTransaction();
        Session session = txObject.getSessionHolder().getSession();
        
        try {
            session.getTransaction().commit();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not commit Hibernate transaction", ex);
        }
    }
    
    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        HibernateTransactionObject txObject = (HibernateTransactionObject) status.getTransaction();
        Session session = txObject.getSessionHolder().getSession();
        
        try {
            session.getTransaction().rollback();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not roll back Hibernate transaction", ex);
        }
    }
}
```

## 3.4 JtaTransactionManager
JTA事务管理器，用于管理分布式事务。

### 3.4.1 特点
- 支持分布式事务
- 可以跨越多个数据源
- 支持XA([2PC两阶段提交协议](../../500-基础理论/分布式模式/2PC两阶段提交协议.md))协议
- 性能相对较低

### 3.4.2 实现原理
```java
public class JtaTransactionManager extends AbstractPlatformTransactionManager {
    
    @Override
    protected Object doGetTransaction() {
        JtaTransactionObject txObject = new JtaTransactionObject();
        txObject.setUserTransaction(this.userTransaction);
        return txObject;
    }
    
    @Override
    protected void doBegin(Object transaction) {
        JtaTransactionObject txObject = (JtaTransactionObject) transaction;
        
        try {
            // 开始JTA事务
            this.userTransaction.begin();
            txObject.setTransactionActive(true);
        } catch (Exception ex) {
            throw new CannotCreateTransactionException(
                "Could not begin JTA transaction", ex);
        }
    }
    
    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        JtaTransactionObject txObject = (JtaTransactionObject) status.getTransaction();
        
        try {
            this.userTransaction.commit();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not commit JTA transaction", ex);
        }
    }
    
    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        JtaTransactionObject txObject = (JtaTransactionObject) status.getTransaction();
        
        try {
            this.userTransaction.rollback();
        } catch (Exception ex) {
            throw new TransactionSystemException("Could not roll back JTA transaction", ex);
        }
    }
}
```

### 3.4.3 配置示例
```xml
<bean id="transactionManager" class="org.springframework.transaction.jta.JtaTransactionManager">
    <property name="userTransaction" ref="userTransaction"/>
    <property name="transactionManager" ref="transactionManager"/>
</bean>
```

# 4 事务管理器的选择策略

## 4.1 选择依据
1. **数据访问技术**：根据使用的ORM框架选择
2. **事务范围**：本地事务还是分布式事务
3. **性能要求**：对性能的敏感程度
4. **复杂度**：系统的复杂度和维护成本

## 4.2 选择指南

### 4.2.1 单数据源场景
- **JDBC**：`DataSourceTransactionManager`
- **JPA/Hibernate**：`JpaTransactionManager`
- **MyBatis**：`DataSourceTransactionManager`

### 4.2.2 多数据源场景
- **本地事务**：为每个数据源配置独立的事务管理器
- **分布式事务**：`JtaTransactionManager`

### 4.2.3 微服务场景
- **服务内**：使用本地事务管理器
- **服务间**：使用分布式事务或最终一致性

# 5 底层实现原理

## 5.1 抽象基类AbstractPlatformTransactionManager
所有事务管理器都继承自`AbstractPlatformTransactionManager`：

```java
public abstract class AbstractPlatformTransactionManager implements PlatformTransactionManager {
    
    @Override
    public final TransactionStatus getTransaction(TransactionDefinition definition) {
        Object transaction = doGetTransaction();
        
        // 检查是否存在事务
        if (isExistingTransaction(transaction)) {
            return handleExistingTransaction(definition, transaction);
        }
        
        // 创建新事务
        return startTransaction(definition, transaction);
    }
    
    @Override
    public final void commit(TransactionStatus status) {
        DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
        
        if (defStatus.isNewTransaction()) {
            doCommit(defStatus);
        }
    }
    
    @Override
    public final void rollback(TransactionStatus status) {
        DefaultTransactionStatus defStatus = (DefaultTransactionStatus) status;
        
        if (defStatus.isNewTransaction()) {
            doRollback(defStatus);
        }
    }
    
    // 模板方法，由子类实现
    protected abstract Object doGetTransaction();
    protected abstract void doBegin(Object transaction);
    protected abstract void doCommit(DefaultTransactionStatus status);
    protected abstract void doRollback(DefaultTransactionStatus status);
}
```

## 5.2 事务同步机制
Spring使用`TransactionSynchronizationManager`管理事务资源：

```java
public abstract class TransactionSynchronizationManager {
    
    // 事务资源绑定
    public static void bindResource(Object key, Object value) {
        Map<Object, Object> resources = getResourceMap();
        resources.put(key, value);
    }
    
    // 获取事务资源
    public static Object getResource(Object key) {
        Map<Object, Object> resources = getResourceMap();
        return resources.get(key);
    }
    
    // 解绑事务资源
    public static Object unbindResource(Object key) {
        Map<Object, Object> resources = getResourceMap();
        return resources.remove(key);
    }
    
    // 注册事务同步器
    public static void registerSynchronization(TransactionSynchronization synchronization) {
        Set<TransactionSynchronization> synchronizations = getSynchronizations();
        synchronizations.add(synchronization);
    }
}
```

## 5.3 关键类图
```
PlatformTransactionManager (接口)
    └── AbstractPlatformTransactionManager (抽象基类)
        ├── DataSourceTransactionManager (JDBC事务管理器)
        ├── JpaTransactionManager (JPA事务管理器)
        ├── HibernateTransactionManager (Hibernate事务管理器)
        └── JtaTransactionManager (JTA事务管理器)

TransactionSynchronizationManager (事务同步管理器)
    ├── 管理ThreadLocal资源
    ├── 管理事务同步器
    └── 提供事务上下文

TransactionStatus (事务状态)
    └── DefaultTransactionStatus (默认实现)
        ├── 跟踪事务状态
        ├── 管理回滚标记
        └── 记录事务信息
```

# 6 事务管理器关联的其它知识

## 6.1 相关技术
- [Spring事务基础概念](0401-事务基础概念.md)
- [Spring AOP原理](0302-Spring%20AOP实现原理.md)
- [数据库连接池](0504-连接池管理.md)
- [JPA/Hibernate配置](0502-ORM框架集成.md)

## 6.2 性能优化
- 事务管理器性能对比
- 连接池配置优化
- 事务超时设置
- 死锁预防策略

## 6.3 最佳实践
- 根据业务场景选择合适的事务管理器
- 合理配置事务属性
- 监控事务性能
- 处理事务异常 