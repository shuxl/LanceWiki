RabbitMQ 的**死信队列（Dead Letter Queue, DLQ）是一个处理“投递失败”或“不再被消费的消息”的机制，本质上是普通队列 + 特殊绑定规则**，并不是 RabbitMQ 的单独类型。
我按机制、触发条件、数据流动过程和实际应用来拆解给你讲。

---

### **1. 死信队列的定义**
- 死信队列是一个**普通队列**，用来接收其他队列中变成“死信”的消息。
- **死信（Dead Letter）**：指消息在原队列中因为某些原因不能被消费，需要转发到另一个队列做特殊处理（日志记录、人工介入、重试等）。

---

### **2. 死信产生的三种触发条件**
1. **消息被拒绝（reject/nack）且 requeue=false**
```
channel.basicNack(deliveryTag, false, false);
```
+ 如果 requeue=true 表示重新放回原队列，不会进入 DLQ。

2. **消息过期（TTL 到期）**
    - 可以对**队列**设置 TTL：
```
x-message-ttl=60000 # 队列内所有消息 60 秒过期
```

- 也可以对**单条消息**设置 TTL：

```
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
    .expiration("60000") // 毫秒
    .build();
```

- 到期未被消费 → 死信

3. **队列达到最大长度（x-max-length / x-max-length-bytes）**
    - 超出限制的最早的消息会变成死信并转发。
---
### **3. 工作原理（数据流）**
死信队列不是 RabbitMQ 自动创建的，需要你手动绑定：
1. 创建一个**死信交换机（DLX, Dead Letter Exchange）**
2. 创建一个**死信队列（DLQ）**
3. 将 DLQ 绑定到 DLX
4. 在原队列上指定参数：
```
x-dead-letter-exchange=<DLX名称>
x-dead-letter-routing-key=<路由键>
```

4. 当原队列中消息触发死信条件时，RabbitMQ 会把该消息发送到绑定的 DLX，由 DLX 路由到 DLQ。
---
### **4. 示例配置**
```
# 1. 创建死信交换机
rabbitmqadmin declare exchange name=dlx_exchange type=direct durable=true
# 2. 创建死信队列
rabbitmqadmin declare queue name=dlx_queue durable=true
# 3. 绑定死信队列到死信交换机
rabbitmqadmin declare binding source=dlx_exchange destination=dlx_queue routing_key=dlx_routing_key
# 4. 创建业务队列并绑定死信交换机
rabbitmqadmin declare queue name=business_queue durable=true \
  arguments='{"x-dead-letter-exchange":"dlx_exchange","x-dead-letter-routing-key":"dlx_routing_key","x-message-ttl":60000}'
```
---
### **5. 死信队列的用途**
1. **消息重试**
    - DLQ 消息经过延迟处理后重新投回原队列（实现延迟重试）。
2. **异常监控**
    - 把无法消费的消息转移到 DLQ，监控报警。
3. **数据分析**
    - 分析失败消息原因，改进业务逻辑。
4. **防止消息丢失**
    - 即使业务队列消费失败，消息仍在 DLQ 中保留。
---
### **6. 注意事项**
- DLQ 只负责转发，不会自动重新投递到原队列，重试逻辑要你自己写。
- 如果 DLQ 本身也有死信参数，可能形成**死信循环**（要避免）。
- TTL 是从**进入队列开始计时**，不是发送时间。
- **优先级队列**的过期处理也会触发 DLQ，但要测试性能影响。
