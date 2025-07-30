ThreadPoolExecutor 是 Java 并发包中最核心的线程池实现类，位于 java.util.concurrent 包下。要真正掌握线程池的行为和原理，必须深入理解其构造函数的每一个参数。

---

# 1 ThreadPoolExecutor构造函数原型

```
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler)
```

---

# 2 **二、参数详解**

|**参数**|**说明**|
|---|---|
|corePoolSize|核心线程数：线程池中**始终保持存活的线程数量**（即使它们处于空闲状态）。除非 allowCoreThreadTimeOut 被设置为 true，否则核心线程不会因为空闲而被回收。|
|maximumPoolSize|最大线程数：线程池中**允许创建的最大线程数量**。当队列满了、核心线程也都在忙时，线程池会创建新的线程，但不能超过这个最大值。|
|keepAliveTime|非核心线程的**空闲存活时间**：当线程数超过核心线程数，超过的线程在空闲超过此时间后会被销毁。|
|unit|keepAliveTime 的时间单位，如 TimeUnit.SECONDS|
|workQueue|工作队列：用于缓存等待执行的任务。是一个 BlockingQueue<Runnable>。|
|threadFactory|线程工厂：用于创建新的线程。可以自定义线程名称、优先级、是否为守护线程等。|
|handler|拒绝策略：当线程池和队列都满了之后，任务会被如何处理。常见策略如下：|
||- AbortPolicy（默认）：抛出 RejectedExecutionException 异常|
||- CallerRunsPolicy：由调用者线程直接执行|
||- DiscardPolicy：直接丢弃任务|
||- DiscardOldestPolicy：丢弃最早入队的任务，然后尝试提交当前任务|

---

# 3 **三、线程池运行流程图（简述）**

```
任务提交
   ↓
判断线程数 < corePoolSize ?
   → 是 → 创建线程执行任务
   ↓ 否
将任务加入工作队列
   ↓
队列已满 + 当前线程数 < maximumPoolSize ?
   → 是 → 创建线程执行任务
   ↓ 否
执行拒绝策略
```

---

# 4 **四、任务执行场景分析（配合参数）**

  

假设如下构造：

```
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    2,                      // corePoolSize
    5,                      // maximumPoolSize
    60L,                    // keepAliveTime
    TimeUnit.SECONDS,       // unit
    new LinkedBlockingQueue<>(10), // workQueue
    Executors.defaultThreadFactory(), // threadFactory
    new ThreadPoolExecutor.AbortPolicy() // handler
);
```

**执行逻辑：**

1. 前 2 个任务 → 直接创建线程执行（核心线程数）。
    
2. 第 3~12 个任务 → 放入队列（共 10 个容量）。
    
3. 第 13~15 个任务 → 由于队列已满，且线程数 < 5 → 创建新线程执行。
    
4. 第 16 个任务 → 线程和队列都满 → 执行拒绝策略。
    

---

# 5 **五、核心建议和常见误区**

  

## 5.1 **✅ 建议**

- 使用有界队列（如 LinkedBlockingQueue 带容量），避免 OOM。
    
- 自定义 ThreadFactory 设置线程名，方便排查问题。
    
- 拒绝策略务必明确指定，确保系统稳定性。
    

  

## 5.2 **❌ 误区**

- maximumPoolSize 在使用 LinkedBlockingQueue 时，很多人设置了也没效果，因为任务永远进队列而不扩展线程数（除非队列满了）。
    
- 不合理地设置 corePoolSize == maximumPoolSize 让线程池失去扩展能力。
    

# 6 各种拒绝策略的进一步解释

当然可以，下面我将详细解释 Java 中 ThreadPoolExecutor 提供的 **4 种内置拒绝策略（RejectedExecutionHandler）**，并结合示例、优缺点分析它们的使用场景，帮助你理解什么情况下应该选择哪种策略。

---

## 6.1 **一、拒绝策略触发条件**

  

当满足以下**两个条件**时，ThreadPoolExecutor 会拒绝接收新的任务，并触发拒绝策略：

1. **线程池中的线程数达到 maximumPoolSize**
    
2. **工作队列 workQueue 已满**
    

---

## 6.2 **二、4 种内置拒绝策略详解**

  

### 6.2.1 AbortPolicy（默认策略）

```
public static class AbortPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        throw new RejectedExecutionException();
    }
}
```

**行为：**

- 直接抛出 RejectedExecutionException 异常，阻止任务继续执行。
    

  

**适用场景：**

- 对任务可靠性要求很高，不能丢任务，必须知道任务被拒绝了。
    
- 比如订单系统、支付系统。
    

  

**优点：**

- 明确反馈问题，便于排查。
    

  

**缺点：**

- 如果调用方没有做好异常处理，可能导致线程终止或服务崩溃。
    

---

### 6.2.2 CallerRunsPolicy

```
public static class CallerRunsPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            r.run(); // 在提交任务的线程中直接执行
        }
    }
}
```

**行为：**

- 由提交任务的线程（如主线程）**自己执行该任务**。
    

  

**适用场景：**

- 对系统吞吐量要求不高，但不能丢任务，比如日志处理、统计上报。
    
- 可以起到一种**“削峰”**的作用，减缓任务提交速度。
    

  

**优点：**

- 不丢任务。
    
- 减缓线程池压力（调用者线程被占用，不能疯狂提交任务）。
    

  

**缺点：**

- 如果任务很多，调用方线程会不断被阻塞，可能引发响应超时或系统卡顿。
    

---

### 6.2.3 DiscardPolicy

```
public static class DiscardPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        // 什么也不做，任务被默默丢弃
    }
}
```

**行为：**

- **直接丢弃任务**，不会抛出异常，也不会执行任务。
    

  

**适用场景：**

- 任务可有可无，丢弃不会造成严重后果，比如 UI 刷新、日志采样。
    

  

**优点：**

- 简单，轻量，不影响线程池主流程。
    

  

**缺点：**

- 安静地丢弃任务，极易造成问题难以发现。
    
- 无法回溯被丢弃的任务。
    

---

### 6.2.4 DiscardOldestPolicy

```
public static class DiscardOldestPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            e.getQueue().poll(); // 丢弃队列中最旧的任务
            e.execute(r);        // 再尝试提交当前任务
        }
    }
}
```

**行为：**

- 丢弃队列中最旧的任务，然后尝试重新提交当前任务。
    

  

**适用场景：**

- 相对更关注“新”任务的处理，比如消息刷新、状态同步。
    

  

**优点：**

- 保证最新任务有机会被执行，提升响应性。
    

  

**缺点：**

- 丢弃的是谁你可能不知道，可能造成旧任务“悄悄”丢失。
    
- 若任务无幂等性，可能产生副作用。
    

---

## 6.3 **三、策略对比总结**

|**策略**|**是否丢任务**|**是否抛异常**|**使用线程**|**特点**|
|---|---|---|---|---|
|AbortPolicy|❌ 否|✅ 是|-|默认策略，强制失败，适合对失败敏感的场景|
|CallerRunsPolicy|❌ 否|❌ 否|主线程|降压削峰，保任务但影响提交方性能|
|DiscardPolicy|✅ 是|❌ 否|-|静默丢弃任务|
|DiscardOldestPolicy|✅ 是（旧任务）|❌ 否|线程池|丢旧保新，提高实时性|

---

## 6.4 **四、自定义策略（进阶）**

  

你也可以实现自己的 RejectedExecutionHandler 来定制行为：

```
public class LoggingDiscardPolicy implements RejectedExecutionHandler {
    @Override
    public void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
        System.err.println("任务被拒绝：" + r.toString());
        // 可记录日志，入库，告警等
    }
}
```

---

如果你需要，我可以补充一个完整的线程池示例，演示不同策略的效果对比，是否需要？

# 7 各种拒绝策略分别适用于什么场景

非常好，总结各种 **拒绝策略的适用场景** 是理解和设计线程池的关键能力，下面我将按策略分类，结合具体业务类型、场景特性、以及优缺点，为你梳理出清晰的应用指南。

---

## 7.1 **🚫 1.**  AbortPolicy（默认策略）——强硬型

### 7.1.1 **✅ 适用场景：**
- **对数据强一致性要求极高**
- **必须确保任务被执行，不接受任何丢失**
- **能容忍抛出异常，并有完善的容错机制（例如重试、报警、熔断）**
### 7.1.2 **📌 示例：**
- 电商下单系统、支付、银行系统、任务调度平台
- 核心交易服务线程池满了，宁可让调用方异常，也绝不“默默失败”

### 7.1.3 **👍 优点：**
- 问题暴露及时，容易排查
### 7.1.4 **👎 缺点：**
- 如果调用方没有捕获异常，容易导致系统级故障或线程崩溃
    

---

## 7.2 2.CallerRunsPolicy——背压型

### 7.2.1 **✅ 适用场景：**
- **不能丢任务，但可牺牲吞吐率/响应时间**
- **可以接受调用线程被“拖慢”**
- **用于自然限流/削峰场景**
### 7.2.2 **📌 示例：**
- Kafka 消费线程池（处理 DB binlog）
- 日志聚合系统，保证不丢重要事件
- 缓存异步刷新线程池
### 7.2.3 **👍 优点：**
- 保证任务不丢
- 会拖慢调用方，起到“自然限流”作用，保护线程池
### 7.2.4 **👎 缺点：**
- 若任务很多，调用方线程可能频繁被阻塞，影响主流程性能
    

---

## 7.3 🧹 3. DiscardPolicy——轻量型

### 7.3.1 **✅ 适用场景：**
- **任务可丢失，不影响业务正确性**
- **系统更关注响应速度而非全量处理**
- **业务有采样、降级、容忍机制**
### 7.3.2 **📌 示例：**
- 页面访问日志收集（高频、低价值）
- BI 系统点击流统计（支持丢包、容错）
- UI 刷新任务（重复提交可覆盖）
### 7.3.3 **👍 优点：**
- 实现简单，不增加额外压力
### 7.3.4 **👎 缺点：**
- 安静地丢弃任务，容易忽略问题，不适用于重要数据

---

## 7.4 **♻️ 4.DiscardOldestPolicy——“保新弃旧”型

### 7.4.1 **✅ 适用场景：**
- **新任务比旧任务更重要**
- **任务有时效性，过期任务没必要执行**
- **不能无限增长等待队列**
### 7.4.2 **📌 示例：**
- 实时状态推送服务（保最新数据即可）
- 股票行情、IoT 设备心跳同步等场景
- 移动端消息通知刷新
### 7.4.3 **👍 优点：**
- 优先保留新任务，提升时效性
### 7.4.4 **👎 缺点：**
- 丢弃任务不可控，可能导致重要历史任务丢失
    

---

## 7.5 🛠️ 5. 自定义策略 ——精准型

### 7.5.1 **✅ 适用场景：**
- **业务规则特殊，需要自定义处理**
- **希望丢弃任务前记录日志、告警、重试或落地**
### 7.5.2 **📌 示例：**
- 实时报警系统丢弃任务前入库日志
- 给异常任务加个“重试标志”投回 MQ
- 写入死信队列 / fallback 回退系统
```
public class LoggingRejectPolicy implements RejectedExecutionHandler {
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        log.warn("任务被拒绝: {}", r);
        // fallback 或重试逻辑
    }
}
```

---

## 7.6 **✅ 最终推荐汇总表**

|**拒绝策略**|**是否丢任务**|**是否报错**|**适合场景**|**关键特征**|
|---|---|---|---|---|
|AbortPolicy|❌ 否|✅ 是|强一致、关键流程|显性失败，触发容错机制|
|CallerRunsPolicy|❌ 否|❌ 否|高可靠性、允许降速|背压、自限流|
|DiscardPolicy|✅ 是|❌ 否|可丢失、不重要任务|静默丢弃，低成本|
|DiscardOldestPolicy|✅ 是（旧）|❌ 否|时效性高、刷新场景|保新丢旧，实时性好|
|自定义策略|看你逻辑|看你逻辑|精细控制、业务敏感|可日志、告警、补偿|

---


# 8 场景分析——线程池用于消费 Kafka 中的消息，消息内容是 MySQL 的 binlog 日志（即数据库变更日志）

这个场景非常典型 —— **高吞吐 + 数据一致性敏感**。我们来具体分析，然后推荐合适的拒绝策略。

---

## 8.1 **🔍 场景特性分析**

1. **Kafka 是消息队列，具备“背压”机制**
    
    → 如果你处理不过来，Kafka 会**暂停拉取消息**（取决于你使用的 Kafka 客户端处理方式）。
    
2. **Binlog 是关键数据变更，不能丢！**
    
    → 数据丢失将导致消费端和数据库状态不一致，可能影响业务准确性（比如数据同步系统、缓存更新、ES索引构建等）。
    
3. **消费线程池是有限资源，如果被撑满必须谨慎处理新消息**
    

---

## 8.2 **🚫 不能使用的拒绝策略**

|**策略**|**为什么不推荐**|
|---|---|
|DiscardPolicy|悄悄丢掉任务，**极大风险丢数据**，严重违背业务要求|
|DiscardOldestPolicy|会丢掉**最早的一条 binlog**，影响同步准确性，也不可接受|
|AbortPolicy|会抛异常，若未捕获，可能导致 Kafka 消费线程挂掉或死循环，**稳定性堪忧**|

---

## 8.3 **✅ 推荐的策略：**

## 8.4 **CallerRunsPolicy**

```
new ThreadPoolExecutor.CallerRunsPolicy()
```

### 8.4.1 **✅ 优点**

- **不丢数据**，你每条 Kafka 消息都能最终被消费。
    
- 当线程池压力过大时，**阻塞提交线程（Kafka Consumer）**，间接实现背压控制。
    
- Kafka 消费主线程不会再疯拉消息，而是自己去执行任务，变相减速。
    

  

### 8.4.2 **⚠️ 注意**

- 如果任务执行耗时长，Kafka 拉取速度会变慢，**可能引发消费滞后**（lag）。
    
- 所以还要结合**合理线程池配置**和**Kafka 预取量（max.poll.records）**，平衡吞吐和稳定。
    

---

## 8.5 **✅ 推荐线程池配置示例**

```
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    8,                          // corePoolSize，根据CPU核数和业务压测调整
    16,                         // maximumPoolSize
    60L, TimeUnit.SECONDS,      // keepAliveTime
    new ArrayBlockingQueue<>(1000), // 有界队列，防止OOM
    Executors.defaultThreadFactory(),
    new ThreadPoolExecutor.CallerRunsPolicy()
);
```

---

## 8.6 **✅ Kafka 消费处理建议（简要）**

```
consumer.subscribe(List.of("mysql-binlog"));
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    for (ConsumerRecord<String, String> record : records) {
        executor.submit(() -> processBinlog(record));
    }
}
```

---

## 8.7 **🔚 总结**

|**需求**|**策略推荐**|
|---|---|
|Kafka 消费 binlog，不能丢数据|✅ CallerRunsPolicy|
|Kafka 消费 UI 日志或无害事件|DiscardOldestPolicy / DiscardPolicy|
|非常敏感/要告警|可自定义策略记录拒绝日志或告警|

是否需要我帮你写一个带完整线程池 + Kafka 消费伪代码的例子？可以模拟真实负载。