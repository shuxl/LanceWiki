在 RabbitMQ 里，要做到**消息不丢失**，其实是一个“端到端”的设计问题，需要**生产端、Broker 端、消费端**三方配合，不能只依赖 RabbitMQ 默认行为。

我给你按链路顺序（生产 → RabbitMQ → 消费）分层拆解，并讲每一步要做的配置和注意事项。

---

### **1. 生产端：消息必须可靠投递到 Broker**
#### **1.1 开启 Publisher Confirm 机制**
- RabbitMQ 的 **Confirm 模式**会在消息写入到队列后返回 ack 给生产者，保证消息已经进入 Broker。
- Spring AMQP 示例：

```
rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
    if (ack) {
        // 成功
    } else {
        // 失败重发
    }
});
```

- 注意：Confirm 只保证到达 **Exchange**，不保证进入队列。
  

#### **1.2 配合 ReturnCallback 确保路由成功**

- 如果 Routing Key 没有匹配到任何队列，消息会丢失，必须开启：
```
rabbitTemplate.setMandatory(true);
rabbitTemplate.setReturnsCallback(returned -> {
    // 处理路由失败
});
```

#### **1.3 发送前持久化到本地（可选）**

- 如果生产端可能宕机，可先把消息写到数据库/本地文件，再异步投递。
- 这样即使 Broker 或网络异常，也能恢复未发送的消息。

---

### **2. Broker 端：持久化与高可用**

#### **2.1 队列持久化**

```
# 声明队列时 durable = true
channel.queueDeclare("myQueue", true, false, false, null);
```

- durable 只保证**队列结构**重启后仍存在，不保证消息本身持久。
  

#### **2.2 消息持久化**

```
channel.basicPublish(exchange, routingKey,
    MessageProperties.PERSISTENT_TEXT_PLAIN, body);
```

- 消息的 deliveryMode=2 表示持久化。
- 注意：持久化消息写到磁盘仍有可能丢失，如果 RabbitMQ 宕机前没刷盘，需要配合 **publisher confirm** 才安全。

#### **2.3 镜像队列 / 队列镜像策略**

- 镜像队列（Classic mirrored queues）或 Quorum queues 会将消息复制到多个节点。
- 这样即使一个节点宕机，其他节点能继续提供数据。
- 配置示例（策略）：

```
rabbitmqctl set_policy ha-all "^ha\." '{"ha-mode":"all"}'
```

#### **2.4 配置持久化刷盘策略**

- 默认刷盘是异步的（confirm 触发刷盘），如果要更强保障，可以调整：
```
rabbitmqctl set_policy lazy "^lazy\." '{"queue-mode":"lazy"}'
```

- Lazy queue 会尽量将消息保存在磁盘，减少内存压力，但延迟稍高。

---

### **3. 消费端：防止消费过程中丢失**

#### **3.1 使用手动 ACK**

```
channel.basicConsume(queue, false, (consumerTag, message) -> {
    try {
        // 业务处理
        channel.basicAck(message.getEnvelope().getDeliveryTag(), false);
    } catch (Exception e) {
        // 处理失败可以重回队列
        channel.basicNack(message.getEnvelope().getDeliveryTag(), false, true);
    }
}, consumerTag -> {});
```

- 自动 ack 模式下，消息一到就算消费成功，即使程序宕机也会丢失。

#### **3.2 消费端幂等性**

- 即使不丢失，也可能**重复投递**（网络抖动、重试）。
- 必须在业务层保证幂等，例如：
    - 数据库唯一索引
    - Redis 去重
    - 基于业务 ID 的去重表

#### **3.3 QoS 限流**

- 避免一次拉取太多消息，处理不过来导致积压甚至丢失：

```
channel.basicQos(1);
```

#### **3.4 死信队列（DLQ）兜底​**
+ 作用​：捕获多次重试失败的消息，避免阻塞主队列。
+ 配置​：声明队列时绑定死信交换机：

---

### **4. 端到端防丢总结**
一个“消息不丢失”的 RabbitMQ 链路，应该这样设计：
1. **生产端**
    - Publisher Confirm + ReturnCallback
    - 本地持久化（可选）
2. **Broker**
    - 队列 durable = true
    - 消息 deliveryMode = 2（持久化）
    - 镜像队列 / Quorum Queue
    - 刷盘策略
3. **消费端**
    - manual ack
    - 幂等性设计
    - QoS 限流
