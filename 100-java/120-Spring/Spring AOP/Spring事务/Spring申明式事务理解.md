# 1 整体理解
总体来说，从声明式事务的整体实现中可以看到，声明式事务处理完全可以看成是一个具体的Spring AOP应用。
在Spring的声明式事务处理中，采用了IoC容器的Bean配置为事务方法调用提供事务属性设置，从而为应用对事务处理的使用提供方便。

从Spring的实现的角度来看，声明式事务处理的大致实现过程如下：
在为事务处理配置好的AOP基础设施（比如，对应的Proxy代理对象和事务处理器Interceptor拦截器对象）之后， 首先需要完成对这些事务属性配置的读取，这些属性的读取处理是在TransactionInterceptor中实现的。
在完成这些事务处理属性的读取之后，Spring为事务处理的具体实现做好了准备。

事务处理过程中的关键点：
+ 如何封装各种不同事务处理环境下的事务处理，具体来说，作为应用平台的Spring，它没法对应用使用什么样的事务环境做出限制，这样，对应用户使用的不同的事务处理器，Spring事务处理平台都需要为用户提供服务。
	+ 这些事务处理实现包括在应用中常见的DataSource的Connection、Hibernate的Transaction等
	+ Spring事务处理通过一种统一的方式把它们封装起来，从而实现一个通用的事务处理过程，实现这部分事务处理对应用透明
+ 如何读取事务处理属性值。在事务处理属性正确读取的基础上，结合事务处理代码，从完成在既定的事务处理配置下，事务处理方法的实现
+ 如何灵活的使用Spring AOP框架，对事务进行封装，提供给应用即开即用的声明式事务处理功能

需要关注的事务处理的核心类
+ TransactionInterceptor，是使用AOP实现声明式事务处理的拦截器，封装了事务处理的基本过程
+ TransactionAttributeSource和TransactionAttribute，封装了对声明式事务处理属性的数据抽象。DefaultTransactionAttribute，提供了默认的事务处理属性设置
+ TransactionInfo和TransactionStatus，存放事务处理信息的主要数据对象，它们通过与线程绑定来实现事务的隔离性。
	+ TransactionInfo是一个栈，对应着每次事务方法的调用，它会保存每一次事务方法调用的事务处理信息。
	+ TransactionInfo持有TransactionStatus。TransactionStatus来掌管事务执行的详细信息，包括具体的事务对象、事务的执行状态、事务设置状态等。在事务的创建、启动、提交和回滚的过程中，都需要与TransactionStatus打交道
+ TransactionManager用来对具体的事务进行处理。而与具体的事务无关的操作都被封装到AbstractPlatformTransactionManager中实现了，为不同的具体事务处理器提供了通用的事务处理模版。在具体的事务处理器的实现中，可以看到最底层的事务创建、挂起、提交、回滚操作
# 2 声明式事务在spring启动到代理类生成的全过程
Spring 5 中，声明式事务的整个流程从 **Spring 容器启动** 到 **代理类生成**，涉及到多个核心组件，包括 @EnableTransactionManagement、AOP 代理生成器、事务增强器（advice）、事务管理器等。下面是整个流程的详细分阶段总结：
## 2.1 关键注解启用事务管理

```
@EnableTransactionManagement
```

这是开启声明式事务的关键入口，它触发了 Spring 对事务相关 Bean 的注册。

### 2.1.1 对应 ImportSelector：

```
@Import(TransactionManagementConfigurationSelector.class)
```

- 根据配置（如 mode = PROXY），导入 ProxyTransactionManagementConfiguration。
- 这个配置类注册了关键 Bean，例如：
    - TransactionAttributeSource
    - TransactionInterceptor（事务增强器）
    - BeanFactoryTransactionAttributeSourceAdvisor（事务切面）
    - PlatformTransactionManager（用户需要配置）
## 2.2 Spring 容器初始化阶段（refresh 流程）
当容器启动时，会调用 AbstractApplicationContext#refresh()，其中关键流程如下：
### 2.2.1 ConfigurationClassPostProcessor处理配置类
- 解析 @EnableTransactionManagement，注册事务相关 Bean。
### 2.2.2 注册 BeanDefinition 后置处理器
- InfrastructureAdvisorAutoProxyCreator 或其子类（如 AnnotationAwareAspectJAutoProxyCreator）被注册，用于生成 AOP 代理。
## 2.3 AOP 自动代理创建器工作机制
### 2.3.1 创建 Bean 时触发postProcessBeforeInstantiation和 postProcessAfterInitialization
- 在 AbstractAutoProxyCreator 的 wrapIfNecessary() 方法中，判断是否需要代理。
### 2.3.2 查找切面（Advisor）

在这里会找到前面注册的 BeanFactoryTransactionAttributeSourceAdvisor：
- 判断该 Advisor 是否适用于当前类（即类上或方法上是否有 @Transactional）。
- 如果适配，则使用代理模式（JDK 动态代理或 CGLIB）生成代理对象。
## 2.4 代理对象中织入事务增强器
代理对象中的增强器是 TransactionInterceptor，其工作如下：
1. 是一个 MethodInterceptor，实现 AOP 调用链中的一个环节。
2. 内部核心调用为：

```
TransactionAspectSupport.invokeWithinTransaction()
```

此方法负责：
- 获取事务属性（通过 TransactionAttributeSource）。
- 获取 PlatformTransactionManager。
- 执行事务管理逻辑：getTransaction() → invoke() → commit() or rollback()。

## 2.5 事务最终执行流程（调用方法时）

当调用一个 @Transactional 注解的方法时：
1. 代理对象拦截方法调用，进入 AOP 逻辑。
2. TransactionInterceptor 拦截方法，执行事务逻辑：
    - 开启事务（或加入已有事务）
    - 调用目标方法
    - 判断异常类型，决定提交或回滚事务


## 2.6 **总结流程图（文字版）**

```
@EnableTransactionManagement
        ↓
@Import(TransactionManagementConfigurationSelector.class)
        ↓
ProxyTransactionManagementConfiguration 注册事务相关 Bean
        ↓
AnnotationAwareAspectJAutoProxyCreator 注册为 BeanPostProcessor
        ↓
Spring 容器初始化，创建 Bean 时
        ↓
→ 判断是否匹配事务 Advisor
→ 是，则创建代理类，织入 TransactionInterceptor
        ↓
代理方法调用时 → 进入 TransactionInterceptor
        ↓
invokeWithinTransaction 执行事务控制
        ↓
目标方法执行，成功 → commit；异常 → rollback
```

# 3 事务处理在AOP拦截器中实现的全过程
下面是 TransactionAspectSupport.invokeWithinTransaction() 方法的事务处理过程的**时序图（文字版）及其详细描述**。这个方法是 Spring 声明式事务的核心实现之一，它在代理方法执行时被调用，用来进行事务的开启、提交、回滚等操作。

## 3.1 总体参与者（顺序）

```
[Caller] → 代理对象（Proxy） → TransactionInterceptor → TransactionAspectSupport → invokeWithinTransaction() → PlatformTransactionManager
```

## 3.2 invokeWithinTransaction 时序图（ASCII 版）

```
Caller
  |
  v
Proxy (AOP 代理)
  |
  v
TransactionInterceptor.invoke()
  |
  v
TransactionAspectSupport.invokeWithinTransaction()
  |
  |---> 获取事务属性（TransactionAttribute）
  |
  |---> 获取事务管理器（PlatformTransactionManager）
  |
  |---> 开启事务 tx = tm.getTransaction(attr)
  |
  |---> try {
  |        返回目标方法执行结果 = methodInvocation.proceed()
  |        commit(tx)
  |     } catch (Throwable ex) {
  |        rollback(tx)
  |        throw ex
  |     }
  |
  v
返回结果给调用者
```

## 3.3 方法内部关键步骤解释

### 3.3.1 获取事务属性 TransactionAttribute

- 由 TransactionAttributeSource 提供。
- 会解析方法或类上的 @Transactional 注解。
```
TransactionAttribute txAttr = getTransactionAttributeSource().getTransactionAttribute(method, targetClass);
```

### 3.3.2 获取事务管理器PlatformTransactionManager

- 通常从上下文中按名称获取，也可以自定义。
- 支持多数据源事务。
```
PlatformTransactionManager tm = determineTransactionManager(txAttr);
```

### 3.3.3 开启事务（或参与已有事务）

```
TransactionStatus status = tm.getTransaction(txAttr);
```

此过程根据传播行为（如 REQUIRED、REQUIRES_NEW）决定是否新建事务，或加入已有事务。

### 3.3.4 执行目标方法

```
retVal = invocation.proceed();
```
- invocation 是 MethodInvocation 类型，调用实际业务方法。

### 3.3.5 正常提交事务

```
tm.commit(status);
```
- 正常无异常时，提交事务。
### 3.3.6 异常时回滚事务

```
tm.rollback(status);
```
- 若捕获异常，判断是否符合回滚策略（默认是 RuntimeException 或 Error）；
- 然后回滚事务，并将异常重新抛出。

## 3.4 总结流程关键点

| **步骤** | **关键内容**                           |
| ------ | ---------------------------------- |
| ①      | 获取 @Transactional 元数据              |
| ②      | 获取事务管理器 PlatformTransactionManager |
| ③      | 启动或加入事务                            |
| ④      | 执行业务方法                             |
| ⑤      | 成功：提交事务                            |
| ⑥      | 异常：回滚事务                            |


# 4 声明式事务 事务的创建、挂起、提交和回滚 invokeWithinTransaction
TransactionAspectSupport#invokeWithinTransaction 是 Spring AOP 事务处理的核心方法，负责协调事务的创建、挂起、提交和回滚行为。它是声明式事务（如 @Transactional）生效的关键执行路径。

## 4.1 整体流程概览（invokeWithinTransaction）

这个方法的执行流程如下：
1. **获取事务管理器 PlatformTransactionManager**
2. **构建 TransactionAttribute（事务属性）**
3. **获取 TransactionInfo 并开始事务**（可能是新事务，也可能加入现有事务）
4. **执行目标方法**
5. **根据目标方法执行结果提交或回滚事务**
6. **恢复挂起的事务上下文**

## 4.2 关键事务生命周期实现分析

### 4.2.1 事务创建

在 invokeWithinTransaction 中：
```
TransactionInfo txInfo = createTransactionIfNecessary(tm, txAttr, joinpointIdentification);
```

- 实际调用的是 AbstractPlatformTransactionManager#getTransaction
    - 判断当前线程是否已有事务（通过 TransactionSynchronizationManager）
    - 如果已有事务，根据传播行为决定是否挂起或参与
    - 如果没有事务，根据传播行为决定是否创建新事务
    - 创建新事务调用 doBegin() 方法 —— **这是模版方法，需要子类实现**

```
protected abstract void doBegin(Object transaction, TransactionDefinition definition);
```

常见子类实现：
- DataSourceTransactionManager#doBegin
- JpaTransactionManager#doBegin

### 4.2.2 事务挂起
如果传播行为要求挂起现有事务（如 REQUIRES_NEW），Spring 会调用：

```
Object suspendedResources = suspend(transaction);
```
- 实际调用 AbstractPlatformTransactionManager#suspend
- 调用模版方法：doSuspend(transaction) —— 子类实现
- 同时挂起 TransactionSynchronizationManager 上的资源绑定（如 DataSource、Connection）

### 4.2.3 事务提交

正常执行完成后：
```
commitTransactionAfterReturning(txInfo);
```
内部调用：
```
tm.commit(txInfo.getTransactionStatus());
```
- 由 AbstractPlatformTransactionManager#commit 控制事务提交流程
- 如果是新事务，调用：
```
doCommit(status);
```
- **该方法也是模版方法，由子类实现**
### 4.2.4 事务回滚

当抛出异常时：
```
completeTransactionAfterThrowing(txInfo, ex);
```
最终调用：
```
tm.rollback(txInfo.getTransactionStatus());
```
- 实际走 AbstractPlatformTransactionManager#rollback
- 判断当前事务状态，然后调用：
```
doRollback(status);
```
- **该方法也是模版方法，由子类实现**

## 4.3 模版方法（Template Methods）一览

以下为 AbstractPlatformTransactionManager 中定义的模版方法，子类需要实现：

| **方法**                                                        | **说明**                  |
| ------------------------------------------------------------- | ----------------------- |
| doBegin(Object transaction, TransactionDefinition definition) | 启动事务（如获取连接，设置隔离级别等）     |
| doSuspend(Object transaction)                                 | 挂起当前事务资源                |
| doResume(Object transaction, Object suspendedResources)       | 恢复挂起的资源                 |
| doCommit(DefaultTransactionStatus status)                     | 执行事务提交                  |
| doRollback(DefaultTransactionStatus status)                   | 执行事务回滚                  |
| doSetRollbackOnly(DefaultTransactionStatus status)            | 标记事务为 rollback-only（可选） |
| doCleanupAfterCompletion(Object transaction)                  | 清理事务资源（如释放连接）           |

## 4.4 调用链总结（以@Transactional为例）

1. @Transactional → 代理类 → TransactionInterceptor#invoke
2. → TransactionAspectSupport#invokeWithinTransaction
3. → 创建事务（getTransaction() → doBegin()）
4. → 执行目标方法
5. → 提交（commit() → doCommit()）或回滚（rollback() → doRollback()）
## 4.5 子类扩展点举例

**以 DataSourceTransactionManager 为例**：
- doBegin：从 DataSource 获取 Connection，设置自动提交为 false，设置隔离级别等。
- doCommit：直接调用 JDBC 的 Connection.commit()
- doRollback：调用 JDBC 的 Connection.rollback()
- doSuspend：解除当前线程的 ConnectionHolder，保存到 SuspendedResourcesHolder

## 4.6 总结

- TransactionAspectSupport#invokeWithinTransaction 是声明式事务的核心，控制事务生命周期。
- 事务生命周期主要由 AbstractPlatformTransactionManager 控制，关键点通过模版方法开放给子类。
- 不同类型的事务管理器（如 JDBC、JPA、Hibernate）通过实现这些模版方法来适配不同的数据访问技术。

# 5 事务处理器的具体实现理解