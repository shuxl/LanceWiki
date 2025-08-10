# Redis发布订阅模式详解

## 重点
- Redis发布订阅(Pub/Sub)机制的核心概念和工作原理
- 频道订阅和模式订阅的实现方式
- 发布订阅的消息传递机制和特点
- 实际应用场景和最佳实践
- 发布订阅的注意事项和局限性

## Redis发布订阅概念或介绍

### 什么是发布订阅模式

Redis的发布订阅(Pub/Sub)是一种消息通信模式，允许消息的发送者（发布者）和接收者（订阅者）之间进行松耦合的通信。发布者不需要知道订阅者的存在，订阅者也不需要知道发布者的存在。

**核心特点：**
- **松耦合**：发布者和订阅者之间没有直接依赖关系
- **一对多**：一个发布者可以向多个订阅者发送消息
- **实时性**：消息实时传递，无持久化存储
- **简单易用**：基于简单的命令实现

### 发布订阅的基本概念

**1. 频道(Channel)**
- 消息传递的媒介，类似于广播频道
- 发布者向特定频道发送消息
- 订阅者订阅特定频道接收消息

**2. 发布者(Publisher)**
- 向频道发送消息的客户端
- 使用`PUBLISH`命令发送消息

**3. 订阅者(Subscriber)**
- 接收频道消息的客户端
- 使用`SUBSCRIBE`命令订阅频道

**4. 模式订阅(Pattern Subscription)**
- 支持通配符的订阅方式
- 可以同时订阅多个匹配的频道

## Redis发布订阅命令详解

### 1. 订阅命令

#### SUBSCRIBE - 订阅频道
```bash
SUBSCRIBE channel [channel ...]
```

**功能：** 订阅一个或多个频道，接收这些频道的消息

**示例：**
```bash
# 订阅单个频道
SUBSCRIBE news

# 订阅多个频道
SUBSCRIBE news sports weather
```

**响应格式：**
```
*3
$9
subscribe
$4
news
:1
```

#### PSUBSCRIBE - 模式订阅
```bash
PSUBSCRIBE pattern [pattern ...]
```

**功能：** 订阅匹配指定模式的所有频道

**支持的通配符：**
- `*`：匹配任意字符串
- `?`：匹配单个字符
- `[characters]`：匹配字符集中的任意字符

**示例：**
```bash
# 订阅所有以user开头的频道
PSUBSCRIBE user.*

# 订阅所有以log结尾的频道
PSUBSCRIBE *.log

# 订阅特定模式的频道
PSUBSCRIBE user:?:*
```

### 2. 发布命令

#### PUBLISH - 发布消息
```bash
PUBLISH channel message
```

**功能：** 向指定频道发送消息

**返回值：** 接收到消息的订阅者数量

**示例：**
```bash
# 向news频道发布消息
PUBLISH news "Breaking news: Redis 7.0 released!"

# 向多个频道发布消息（需要多次调用）
PUBLISH sports "Game started"
PUBLISH weather "Sunny day"
```

### 3. 取消订阅命令

#### UNSUBSCRIBE - 取消频道订阅
```bash
UNSUBSCRIBE [channel [channel ...]]
```

**功能：** 取消对指定频道的订阅

**示例：**
```bash
# 取消订阅news频道
UNSUBSCRIBE news

# 取消订阅所有频道
UNSUBSCRIBE
```

#### PUNSUBSCRIBE - 取消模式订阅
```bash
PUNSUBSCRIBE [pattern [pattern ...]]
```

**功能：** 取消对指定模式的订阅

**示例：**
```bash
# 取消订阅user.*模式
PUNSUBSCRIBE user.*

# 取消所有模式订阅
PUNSUBSCRIBE
```

### 4. 查询命令

#### PUBSUB - 发布订阅信息查询
```bash
# 查看活跃频道
PUBSUB CHANNELS [pattern]

# 查看频道订阅者数量
PUBSUB NUMSUB [channel-1 ... channel-N]

# 查看模式订阅数量
PUBSUB NUMPAT
```

**示例：**
```bash
# 查看所有活跃频道
PUBSUB CHANNELS

# 查看以user开头的活跃频道
PUBSUB CHANNELS user.*

# 查看news频道的订阅者数量
PUBSUB NUMSUB news

# 查看模式订阅总数
PUBSUB NUMPAT
```

## 发布订阅消息传递机制

### 1. 消息传递流程

```
发布者 → Redis服务器 → 订阅者1
                ↓
            订阅者2
                ↓
            订阅者3
```

**详细步骤：**
1. **订阅阶段**：客户端通过`SUBSCRIBE`或`PSUBSCRIBE`订阅频道
2. **发布阶段**：发布者通过`PUBLISH`向频道发送消息
3. **分发阶段**：Redis服务器将消息分发给所有订阅者
4. **接收阶段**：订阅者接收并处理消息

### 2. 消息格式

**频道订阅消息格式：**
```
*3
$7
message
$4
news
$25
Breaking news: Redis 7.0!
```

**模式订阅消息格式：**
```
*4
$8
pmessage
$6
user.*
$9
user:123
$15
Hello, user 123!
```

### 3. 消息传递特点

**1. 实时性**
- 消息立即传递，无延迟
- 订阅者必须在线才能接收消息

**2. 无持久化**
- 消息不存储在Redis中
- 离线订阅者无法接收历史消息

**3. 可靠性**
- 消息传递不保证100%可靠
- 网络断开可能导致消息丢失

**4. 顺序性**
- 同一频道的消息按发布顺序传递
- 不同频道间无顺序保证

## 发布订阅应用场景

### 1. 实时通知系统

**场景描述：** 用户注册、登录、订单状态变更等实时通知

**实现示例：**
```python
import redis
import json
import threading

class NotificationSystem:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
    
    def subscribe_notifications(self, user_id):
        """订阅用户通知"""
        channel = f"user:{user_id}:notifications"
        self.pubsub.subscribe(channel)
        
        for message in self.pubsub.listen():
            if message['type'] == 'message':
                notification = json.loads(message['data'])
                self.handle_notification(notification)
    
    def publish_notification(self, user_id, notification):
        """发布用户通知"""
        channel = f"user:{user_id}:notifications"
        self.redis_client.publish(channel, json.dumps(notification))
    
    def handle_notification(self, notification):
        """处理通知"""
        print(f"收到通知: {notification}")

# 使用示例
notification_system = NotificationSystem()

# 启动订阅线程
def subscribe_user_notifications(user_id):
    notification_system.subscribe_notifications(user_id)

threading.Thread(target=subscribe_user_notifications, args=(123,)).start()

# 发布通知
notification_system.publish_notification(123, {
    "type": "order_status",
    "message": "您的订单已发货",
    "timestamp": "2024-01-01 10:00:00"
})
```

### 2. 聊天室系统

**场景描述：** 多用户实时聊天，支持房间和私聊

**实现示例：**
```python
class ChatRoom:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
    
    def join_room(self, room_id, user_id):
        """加入聊天室"""
        channel = f"room:{room_id}"
        self.pubsub.subscribe(channel)
        
        # 发送加入消息
        self.send_message(room_id, {
            "type": "join",
            "user_id": user_id,
            "message": f"用户 {user_id} 加入了聊天室"
        })
    
    def send_message(self, room_id, message_data):
        """发送消息到聊天室"""
        channel = f"room:{room_id}"
        self.redis_client.publish(channel, json.dumps(message_data))
    
    def listen_messages(self, room_id):
        """监听聊天室消息"""
        channel = f"room:{room_id}"
        self.pubsub.subscribe(channel)
        
        for message in self.pubsub.listen():
            if message['type'] == 'message':
                msg_data = json.loads(message['data'])
                self.display_message(msg_data)
    
    def display_message(self, message_data):
        """显示消息"""
        if message_data['type'] == 'chat':
            print(f"[{message_data['user_id']}]: {message_data['message']}")
        elif message_data['type'] == 'join':
            print(f"系统: {message_data['message']}")

# 使用示例
chat_room = ChatRoom()

# 用户加入聊天室
chat_room.join_room("general", "user1")

# 发送消息
chat_room.send_message("general", {
    "type": "chat",
    "user_id": "user1",
    "message": "大家好！"
})
```

### 3. 系统监控和日志

**场景描述：** 分布式系统的日志收集和监控告警

**实现示例：**
```python
class LogMonitor:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
    
    def subscribe_logs(self, log_level="*"):
        """订阅日志消息"""
        pattern = f"logs:{log_level}"
        self.pubsub.psubscribe(pattern)
        
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                log_data = json.loads(message['data'])
                self.process_log(log_data)
    
    def publish_log(self, level, service, message):
        """发布日志消息"""
        channel = f"logs:{level}"
        log_data = {
            "level": level,
            "service": service,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        self.redis_client.publish(channel, json.dumps(log_data))
    
    def process_log(self, log_data):
        """处理日志"""
        if log_data['level'] == 'ERROR':
            print(f"错误告警: {log_data['service']} - {log_data['message']}")
        elif log_data['level'] == 'WARN':
            print(f"警告: {log_data['service']} - {log_data['message']}")

# 使用示例
log_monitor = LogMonitor()

# 订阅错误日志
log_monitor.subscribe_logs("ERROR")

# 发布日志
log_monitor.publish_log("ERROR", "user-service", "数据库连接失败")
log_monitor.publish_log("WARN", "order-service", "库存不足")
```

### 4. 配置更新通知

**场景描述：** 分布式系统中配置变更的实时通知

**实现示例：**
```python
class ConfigManager:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.config_cache = {}
    
    def subscribe_config_updates(self, service_name):
        """订阅配置更新"""
        pattern = f"config:{service_name}:*"
        self.pubsub.psubscribe(pattern)
        
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                config_data = json.loads(message['data'])
                self.update_config(config_data)
    
    def publish_config_update(self, service_name, config_key, config_value):
        """发布配置更新"""
        channel = f"config:{service_name}:{config_key}"
        config_data = {
            "service": service_name,
            "key": config_key,
            "value": config_value,
            "timestamp": datetime.now().isoformat()
        }
        self.redis_client.publish(channel, json.dumps(config_data))
    
    def update_config(self, config_data):
        """更新本地配置"""
        key = f"{config_data['service']}:{config_data['key']}"
        self.config_cache[key] = config_data['value']
        print(f"配置已更新: {key} = {config_data['value']}")

# 使用示例
config_manager = ConfigManager()

# 订阅用户服务配置更新
config_manager.subscribe_config_updates("user-service")

# 发布配置更新
config_manager.publish_config_update("user-service", "max_connections", "100")
config_manager.publish_config_update("user-service", "timeout", "30")

## 发布订阅注意事项

### 1. 消息可靠性

**问题：** Redis发布订阅不保证消息100%可靠传递

**原因：**
- 网络断开时消息丢失
- 订阅者离线时无法接收消息
- 无消息持久化机制

**解决方案：**
```python
class ReliablePubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.message_queue = []
    
    def publish_with_ack(self, channel, message):
        """带确认的发布"""
        # 存储消息到队列
        message_id = self.store_message(channel, message)
        
        # 发布消息
        self.redis_client.publish(channel, json.dumps({
            "id": message_id,
            "data": message,
            "timestamp": datetime.now().isoformat()
        }))
        
        return message_id
    
    def store_message(self, channel, message):
        """存储消息到队列"""
        message_id = str(uuid.uuid4())
        message_data = {
            "id": message_id,
            "channel": channel,
            "data": message,
            "timestamp": datetime.now().isoformat()
        }
        
        # 存储到Redis List
        self.redis_client.lpush(f"queue:{channel}", json.dumps(message_data))
        return message_id
    
    def subscribe_with_recovery(self, channel):
        """带恢复的订阅"""
        # 先处理队列中的历史消息
        self.process_queued_messages(channel)
        
        # 订阅实时消息
        self.pubsub.subscribe(channel)
        
        for message in self.pubsub.listen():
            if message['type'] == 'message':
                self.process_message(json.loads(message['data']))
    
    def process_queued_messages(self, channel):
        """处理队列中的历史消息"""
        while True:
            message_data = self.redis_client.rpop(f"queue:{channel}")
            if not message_data:
                break
            
            message = json.loads(message_data)
            self.process_message(message)
    
    def process_message(self, message):
        """处理消息"""
        print(f"处理消息: {message['data']}")
        # 发送确认
        self.send_ack(message['id'])
    
    def send_ack(self, message_id):
        """发送确认"""
        self.redis_client.setex(f"ack:{message_id}", 3600, "1")
```

### 2. 性能考虑

**问题：** 大量订阅者可能影响性能

**优化策略：**
```python
class OptimizedPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.subscriber_count = 0
    
    def monitor_subscriber_count(self, channel):
        """监控订阅者数量"""
        count = self.redis_client.pubsub_numsub(channel)[0][1]
        if count > 1000:
            print(f"警告: 频道 {channel} 订阅者过多: {count}")
            self.optimize_channel(channel)
    
    def optimize_channel(self, channel):
        """优化频道性能"""
        # 1. 使用模式订阅减少频道数量
        # 2. 实现消息分片
        # 3. 使用集群模式分散负载
        
        # 示例：消息分片
        shard_count = 10
        for i in range(shard_count):
            shard_channel = f"{channel}:shard:{i}"
            self.redis_client.publish(shard_channel, "分片消息")
    
    def subscribe_with_sharding(self, base_channel, shard_id):
        """分片订阅"""
        channel = f"{base_channel}:shard:{shard_id}"
        self.pubsub.subscribe(channel)
        
        for message in self.pubsub.listen():
            if message['type'] == 'message':
                self.process_sharded_message(message['data'])
    
    def process_sharded_message(self, message):
        """处理分片消息"""
        print(f"处理分片消息: {message}")
```

### 3. 内存管理

**问题：** 长时间订阅可能占用内存

**解决方案：**
```python
class MemoryOptimizedPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.subscription_timeout = 3600  # 1小时超时
    
    def subscribe_with_timeout(self, channel):
        """带超时的订阅"""
        # 设置订阅超时
        self.redis_client.setex(f"sub_timeout:{channel}", 
                               self.subscription_timeout, "1")
        
        self.pubsub.subscribe(channel)
        
        start_time = time.time()
        for message in self.pubsub.listen():
            # 检查超时
            if time.time() - start_time > self.subscription_timeout:
                print(f"订阅超时，取消订阅: {channel}")
                break
            
            if message['type'] == 'message':
                self.process_message(message['data'])
    
    def cleanup_expired_subscriptions(self):
        """清理过期订阅"""
        expired_keys = self.redis_client.keys("sub_timeout:*")
        for key in expired_keys:
            channel = key.replace("sub_timeout:", "")
            self.pubsub.unsubscribe(channel)
            self.redis_client.delete(key)
```

### 4. 错误处理

**常见错误和解决方案：**

```python
class RobustPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.max_retries = 3
    
    def subscribe_with_retry(self, channel):
        """带重试的订阅"""
        retry_count = 0
        
        while retry_count < self.max_retries:
            try:
                self.pubsub.subscribe(channel)
                
                for message in self.pubsub.listen():
                    if message['type'] == 'message':
                        self.process_message(message['data'])
                        
            except redis.ConnectionError as e:
                retry_count += 1
                print(f"连接错误，重试 {retry_count}/{self.max_retries}: {e}")
                time.sleep(2 ** retry_count)  # 指数退避
                
            except Exception as e:
                print(f"未知错误: {e}")
                break
    
    def publish_with_retry(self, channel, message):
        """带重试的发布"""
        retry_count = 0
        
        while retry_count < self.max_retries:
            try:
                result = self.redis_client.publish(channel, message)
                return result
                
            except redis.ConnectionError as e:
                retry_count += 1
                print(f"发布失败，重试 {retry_count}/{self.max_retries}: {e}")
                time.sleep(2 ** retry_count)
        
        raise Exception("发布消息失败，已达到最大重试次数")
```

## Redis发布订阅底层原理

### 1. 数据结构

Redis发布订阅使用以下数据结构：

**1. 频道订阅表**
```c
// 伪代码表示
typedef struct dict {
    dictEntry **table;  // 哈希表
    unsigned long size;  // 表大小
    unsigned long used;  // 已使用数量
} dict;

// 频道订阅表：channel -> client_list
dict *pubsub_channels;
```

**2. 模式订阅表**
```c
// 伪代码表示
typedef struct list {
    listNode *head;
    listNode *tail;
    unsigned long len;
} list;

// 模式订阅表：pattern -> client_list
dict *pubsub_patterns;
```

### 2. 订阅机制

**频道订阅流程：**
1. 客户端发送`SUBSCRIBE`命令
2. Redis解析频道名称
3. 在`pubsub_channels`中查找或创建频道
4. 将客户端添加到频道的订阅者列表
5. 返回订阅确认消息

**模式订阅流程：**
1. 客户端发送`PSUBSCRIBE`命令
2. Redis解析模式字符串
3. 在`pubsub_patterns`中查找或创建模式
4. 将客户端添加到模式的订阅者列表
5. 返回订阅确认消息

### 3. 发布机制

**消息发布流程：**
1. 客户端发送`PUBLISH`命令
2. Redis解析频道名称和消息内容
3. 查找`pubsub_channels`中的订阅者
4. 查找`pubsub_patterns`中匹配的模式订阅者
5. 向所有订阅者发送消息
6. 返回订阅者数量

**消息分发算法：**
```c
// 伪代码
int publishMessage(char *channel, char *message) {
    int receivers = 0;
    
    // 1. 发送给频道订阅者
    list *clients = dictGet(pubsub_channels, channel);
    if (clients) {
        listIter *iter = listGetIterator(clients, AL_START_HEAD);
        listNode *node;
        
        while ((node = listNext(iter)) != NULL) {
            client *c = listNodeValue(node);
            addReply(c, createMessageReply(channel, message));
            receivers++;
        }
        listReleaseIterator(iter);
    }
    
    // 2. 发送给模式订阅者
    dictIterator *iter = dictGetIterator(pubsub_patterns);
    dictEntry *entry;
    
    while ((entry = dictNext(iter)) != NULL) {
        char *pattern = dictGetKey(entry);
        list *clients = dictGetVal(entry);
        
        if (stringmatch(pattern, channel)) {
            listIter *list_iter = listGetIterator(clients, AL_START_HEAD);
            listNode *node;
            
            while ((node = listNext(list_iter)) != NULL) {
                client *c = listNodeValue(node);
                addReply(c, createPMessageReply(pattern, channel, message));
                receivers++;
            }
            listReleaseIterator(list_iter);
        }
    }
    dictReleaseIterator(iter);
    
    return receivers;
}
```

### 4. 内存管理

**订阅者管理：**
- 客户端断开连接时自动清理订阅
- 使用引用计数管理订阅关系
- 定期清理无效订阅

**内存优化：**
- 共享订阅者列表减少内存占用
- 使用压缩字符串存储频道名称
- 实现订阅者列表的懒删除

### 5. 性能优化

**1. 订阅者列表优化**
```c
// 使用跳表优化大量订阅者的查找
typedef struct skiplist {
    skiplistNode *header, *tail;
    unsigned long length;
    int level;
} skiplist;

// 订阅者列表使用跳表存储
skiplist *subscribers;
```

**2. 模式匹配优化**
```c
// 使用Trie树优化模式匹配
typedef struct trie_node {
    struct trie_node *children[256];
    list *clients;
    int is_end;
} trie_node;

trie_node *pattern_trie;
```

**3. 消息缓冲**
```c
// 消息缓冲队列
typedef struct message_buffer {
    char *channel;
    char *message;
    time_t timestamp;
} message_buffer;

list *message_queue;
```

## Redis发布订阅关联的其它知识

### 1. 与消息队列的对比

**Redis Pub/Sub vs 消息队列：**

| 特性 | Redis Pub/Sub | 消息队列(如RabbitMQ) |
|------|---------------|---------------------|
| 持久化 | 不支持 | 支持 |
| 可靠性 | 不保证 | 保证 |
| 实时性 | 高 | 中等 |
| 复杂度 | 简单 | 复杂 |
| 适用场景 | 实时通知 | 可靠消息传递 |

### 2. 与WebSocket的集成

**WebSocket + Redis Pub/Sub架构：**
```python
import asyncio
import websockets
import redis.asyncio as redis

class WebSocketPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.connections = set()
    
    async def register(self, websocket):
        """注册WebSocket连接"""
        self.connections.add(websocket)
    
    async def unregister(self, websocket):
        """注销WebSocket连接"""
        self.connections.remove(websocket)
    
    async def subscribe_channel(self, websocket, channel):
        """订阅频道"""
        pubsub = self.redis_client.pubsub()
        await pubsub.subscribe(channel)
        
        try:
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    await websocket.send(message['data'])
        except websockets.exceptions.ConnectionClosed:
            await pubsub.unsubscribe(channel)
    
    async def publish_message(self, channel, message):
        """发布消息"""
        await self.redis_client.publish(channel, message)

# WebSocket服务器
async def websocket_handler(websocket, path):
    pubsub = WebSocketPubSub()
    await pubsub.register(websocket)
    
    try:
        async for message in websocket:
            # 处理订阅请求
            if message.startswith('SUBSCRIBE:'):
                channel = message.split(':')[1]
                await pubsub.subscribe_channel(websocket, channel)
    finally:
        await pubsub.unregister(websocket)

# 启动WebSocket服务器
start_server = websockets.serve(websocket_handler, "localhost", 8765)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
```

### 3. 与微服务架构的结合

**微服务间通信：**
```python
class MicroservicePubSub:
    def __init__(self, service_name):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.service_name = service_name
        self.pubsub = self.redis_client.pubsub()
    
    def subscribe_service_events(self):
        """订阅服务事件"""
        pattern = f"service:{self.service_name}:*"
        self.pubsub.psubscribe(pattern)
        
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                event_data = json.loads(message['data'])
                self.handle_service_event(event_data)
    
    def publish_service_event(self, event_type, event_data):
        """发布服务事件"""
        channel = f"service:{self.service_name}:{event_type}"
        event = {
            "service": self.service_name,
            "type": event_type,
            "data": event_data,
            "timestamp": datetime.now().isoformat()
        }
        self.redis_client.publish(channel, json.dumps(event))
    
    def handle_service_event(self, event_data):
        """处理服务事件"""
        if event_data['type'] == 'health_check':
            self.respond_health_check(event_data)
        elif event_data['type'] == 'config_update':
            self.update_config(event_data['data'])

# 用户服务示例
class UserService(MicroservicePubSub):
    def __init__(self):
        super().__init__("user-service")
    
    def handle_service_event(self, event_data):
        if event_data['type'] == 'user_created':
            self.notify_user_created(event_data['data'])
        elif event_data['type'] == 'user_updated':
            self.notify_user_updated(event_data['data'])
    
    def notify_user_created(self, user_data):
        """通知用户创建事件"""
        self.publish_service_event("user_created", user_data)
    
    def notify_user_updated(self, user_data):
        """通知用户更新事件"""
        self.publish_service_event("user_updated", user_data)
```

### 4. 与分布式系统的集成

**分布式锁和发布订阅：**
```python
class DistributedLockPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
    
    def acquire_lock(self, lock_name, timeout=10):
        """获取分布式锁"""
        lock_key = f"lock:{lock_name}"
        lock_value = str(uuid.uuid4())
        
        # 尝试获取锁
        result = self.redis_client.set(lock_key, lock_value, 
                                     ex=timeout, nx=True)
        
        if result:
            # 发布锁获取事件
            self.redis_client.publish(f"lock:{lock_name}:acquired", 
                                    lock_value)
            return lock_value
        return None
    
    def release_lock(self, lock_name, lock_value):
        """释放分布式锁"""
        lock_key = f"lock:{lock_name}"
        
        # 使用Lua脚本确保原子性
        lua_script = """
        if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
        else
            return 0
        end
        """
        
        result = self.redis_client.eval(lua_script, 1, lock_key, lock_value)
        
        if result:
            # 发布锁释放事件
            self.redis_client.publish(f"lock:{lock_name}:released", 
                                    lock_value)
            return True
        return False
    
    def subscribe_lock_events(self, lock_name):
        """订阅锁事件"""
        pattern = f"lock:{lock_name}:*"
        self.pubsub.psubscribe(pattern)
        
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                event_type = message['channel'].split(':')[-1]
                lock_value = message['data']
                
                if event_type == 'acquired':
                    print(f"锁 {lock_name} 被获取: {lock_value}")
                elif event_type == 'released':
                    print(f"锁 {lock_name} 被释放: {lock_value}")

# 使用示例
lock_manager = DistributedLockPubSub()

# 订阅锁事件
lock_manager.subscribe_lock_events("user_resource")

# 获取锁
lock_value = lock_manager.acquire_lock("user_resource", timeout=30)
if lock_value:
    try:
        # 执行业务逻辑
        print("执行业务逻辑...")
    finally:
        # 释放锁
        lock_manager.release_lock("user_resource", lock_value)
```

### 5. 与缓存策略的结合

**缓存失效通知：**
```python
class CacheInvalidationPubSub:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, db=0)
        self.pubsub = self.redis_client.pubsub()
        self.local_cache = {}
    
    def subscribe_cache_events(self):
        """订阅缓存事件"""
        pattern = "cache:*"
        self.pubsub.psubscribe(pattern)
        
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                event_data = json.loads(message['data'])
                self.handle_cache_event(event_data)
    
    def invalidate_cache(self, cache_key, reason="manual"):
        """使缓存失效"""
        # 删除本地缓存
        if cache_key in self.local_cache:
            del self.local_cache[cache_key]
        
        # 发布失效事件
        event_data = {
            "key": cache_key,
            "reason": reason,
            "timestamp": datetime.now().isoformat()
        }
        self.redis_client.publish(f"cache:{cache_key}:invalidated", 
                                json.dumps(event_data))
    
    def handle_cache_event(self, event_data):
        """处理缓存事件"""
        cache_key = event_data['key']
        
        if cache_key in self.local_cache:
            del self.local_cache[cache_key]
            print(f"本地缓存已失效: {cache_key}")
    
    def get_cached_data(self, key):
        """获取缓存数据"""
        # 先查本地缓存
        if key in self.local_cache:
            return self.local_cache[key]
        
        # 查Redis缓存
        data = self.redis_client.get(key)
        if data:
            # 存入本地缓存
            self.local_cache[key] = data
            return data
        
        return None

# 使用示例
cache_manager = CacheInvalidationPubSub()

# 订阅缓存事件
cache_manager.subscribe_cache_events()

# 获取缓存数据
user_data = cache_manager.get_cached_data("user:123")

# 使缓存失效
cache_manager.invalidate_cache("user:123", "user_updated")
```

通过以上详细的内容，我们全面了解了Redis发布订阅模式的概念、实现、应用场景和注意事项。发布订阅模式为Redis提供了强大的消息传递能力，虽然有其局限性，但在合适的场景下能够提供高效、实时的消息通信解决方案。 