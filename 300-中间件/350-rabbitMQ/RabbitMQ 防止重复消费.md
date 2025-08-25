RabbitMQ 想做到**消息不重复**，不能光靠 Broker 配置，因为 RabbitMQ 的设计目标是**至少一次投递（At-Least-Once Delivery）**，它天然可能会重复发消息，比如：

- 消费者处理完但还没 ack 就宕机 → Broker 会重发
- 网络抖动导致 ack 丢失 → Broker 会认为没处理成功再投递
- 生产端重试发送 → 消息重复进入队列

所以，“不重复”本质上要靠**业务端去重**，而不是让 RabbitMQ 完全避免重发。
我分三部分说，先讲 RabbitMQ 机制，再给出常见防重方案。

---

### **1. RabbitMQ 重复消息的原因**
1. **消费者 ACK 丢失**
    - 手动 ack 时，如果 ack 消息还没发到 Broker 就宕机，会导致 Broker 重发同一条。
2. **消费超时**
    - 消息长期未 ack，Broker 会认定失败重新投递。
3. **生产端重试**
    - Confirm 模式下，如果网络抖动导致 confirm ack 没收到，生产端可能重发。
4. **镜像队列切换**
    - 主从切换后，未确认的消息会再次投递。

---

### **2. 常见防重复策略**

#### **方案 A：业务端幂等性（最通用）**
- 给每条消息一个唯一 ID（messageId）。
- 消费端处理前先检查这个 ID 是否已处理过，已处理则直接 ack 丢弃。
- 存储方式：
    - **Redis** SETNX messageId（加过期时间）
    - 数据库唯一索引（插入失败说明重复）
- 示例（Spring AMQP + Redis）：

```
String msgId = message.getMessageProperties().getMessageId();
if (redisTemplate.opsForValue().setIfAbsent("msg:"+msgId, "1", 1, TimeUnit.DAYS)) {
    // 处理业务
    channel.basicAck(deliveryTag, false);
} else {
    // 已处理过
    channel.basicAck(deliveryTag, false);
}
```

#### **方案 B：消息唯一键 + 数据库去重**
- 业务表设计唯一约束（如订单号、事务号），重复插入时直接丢弃。
- 优点：持久可靠，不依赖缓存；缺点：增加 DB 压力。

#### **方案 C：生产端去重**
- 在生产端就确保每条消息 ID 唯一，并在重复发送前检查。
- 可以配合**本地消息表**（事务表）：
    1. 业务数据 + 消息数据同事务写入 DB
    2. 发送成功后更新状态
    3. 定时任务扫描未发送/发送失败的记录重发

#### **方案 D：消费端事务 + ACK**
- 先执行业务逻辑（事务提交）
- 再手动 ack
- 这样即使 RabbitMQ 重发，也会被幂等逻辑拦下。

---

### **3. RabbitMQ 配置辅助减少重复**
虽然不能彻底消灭重复，但可以降低概率：
1. **手动 ACK + prefetch=1**
    避免一次拉取过多消息。
2. **合理超时设置**
    防止业务执行慢导致 Broker 误判为失败。
3. **镜像队列 + 持久化**
    避免因节点故障导致重发。

---

### **4. 总结方案选择**

|**场景**|**建议方案**|
|---|---|
|高并发、低延迟|Redis SETNX 去重（方案 A）|
|核心交易、强一致|DB 唯一索引 + 本地消息表（方案 B + C）|
|普通业务|幂等性接口（方案 A/D）|
