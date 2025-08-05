# Kafka应用场景详解

## 重点内容

本文档重点介绍Apache Kafka的主要应用场景，包括消息队列应用、日志收集、流处理应用、事件溯源、微服务通信、数据管道等核心应用领域，帮助读者理解Kafka在不同场景下的应用价值和实现方案。

## Kafka应用场景介绍

### 为什么选择Kafka
Kafka作为一个分布式流处理平台，具有以下核心优势：
- **高吞吐量**：能够处理每秒数百万条消息
- **低延迟**：毫秒级的消息处理延迟
- **高可用性**：通过副本机制保证数据可靠性
- **水平扩展**：支持集群动态扩展
- **持久化存储**：消息持久化到磁盘，支持数据回溯
- **多语言支持**：提供多种编程语言的客户端

### Kafka应用场景分类

#### 1. 消息队列应用
**核心特性**：解耦系统组件，异步处理
**适用场景**：系统间通信、任务队列、通知系统

#### 2. 日志收集应用
**核心特性**：集中化日志管理，实时分析
**适用场景**：应用日志收集、系统监控、安全审计

#### 3. 流处理应用
**核心特性**：实时数据处理，复杂事件处理
**适用场景**：实时分析、CEP、机器学习

#### 4. 事件溯源应用
**核心特性**：事件驱动架构，状态重建
**适用场景**：微服务架构、审计系统、数据同步

#### 5. 微服务通信应用
**核心特性**：服务间解耦，事件驱动
**适用场景**：微服务架构、API网关、服务发现

#### 6. 数据管道应用
**核心特性**：数据集成，ETL处理
**适用场景**：数据仓库、数据湖、实时ETL

## 底层原理

### 消息队列应用原理

#### 1. 生产者-消费者模式
**核心组件**：
- **Producer**：消息生产者
- **Consumer**：消息消费者
- **Topic**：消息主题
- **Partition**：消息分区

**实现原理**：
```java
// 生产者实现
public class MessageProducer {
    private final KafkaTemplate<String, String> kafkaTemplate;
    
    public void sendMessage(String topic, String message) {
        kafkaTemplate.send(topic, message)
            .addCallback(
                result -> log.info("Message sent: topic={}, partition={}", 
                    result.getRecordMetadata().topic(), 
                    result.getRecordMetadata().partition()),
                ex -> log.error("Failed to send message", ex)
            );
    }
}

// 消费者实现
@Component
public class MessageConsumer {
    
    @KafkaListener(topics = "user-events", groupId = "user-group")
    public void consumeMessage(String message) {
        log.info("Received message: {}", message);
        processMessage(message);
    }
}
```

#### 2. 消息路由机制
**路由策略**：
- **Key-based路由**：基于消息Key进行分区
- **Round-robin路由**：轮询分配分区
- **Custom路由**：自定义分区策略

**路由实现**：
```java
public class CustomPartitioner implements Partitioner {
    
    @Override
    public int partition(String topic, Object key, byte[] keyBytes, 
                        Object value, byte[] valueBytes, Cluster cluster) {
        List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
        int numPartitions = partitions.size();
        
        if (keyBytes == null) {
            // 没有Key时使用轮询
            return Math.abs(ThreadLocalRandom.current().nextInt()) % numPartitions;
        }
        
        // 基于Key的哈希分区
        return Math.abs(Arrays.hashCode(keyBytes)) % numPartitions;
    }
}
```

### 日志收集应用原理

#### 1. 日志收集架构
**核心组件**：
- **Log Agent**：日志收集代理
- **Kafka Cluster**：日志存储集群
- **Log Processor**：日志处理组件
- **Storage System**：日志存储系统

**架构设计**：
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Log Agent     │    │   Kafka         │
│   (Logs)        │───►│   (Filebeat)    │───►│   Cluster       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   Log           │
                                              │   Processor     │
                                              └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │   Storage       │
                                              │   (ES/HDFS)     │
                                              └─────────────────┘
```

#### 2. 日志处理流程
**处理步骤**：
1. **日志收集**：Agent收集应用日志
2. **日志解析**：解析日志格式和字段
3. **日志过滤**：过滤无关日志
4. **日志转换**：转换日志格式
5. **日志存储**：存储到目标系统

**实现示例**：
```java
@Component
public class LogProcessor {
    
    @KafkaListener(topics = "application-logs", groupId = "log-processor")
    public void processLog(String logMessage) {
        try {
            // 1. 解析日志
            LogEntry logEntry = parseLog(logMessage);
            
            // 2. 过滤日志
            if (shouldProcessLog(logEntry)) {
                // 3. 转换日志
                ProcessedLog processedLog = transformLog(logEntry);
                
                // 4. 存储日志
                storeLog(processedLog);
            }
        } catch (Exception e) {
            log.error("Error processing log: {}", logMessage, e);
        }
    }
    
    private LogEntry parseLog(String logMessage) {
        // 实现日志解析逻辑
        return LogParser.parse(logMessage);
    }
    
    private boolean shouldProcessLog(LogEntry logEntry) {
        // 实现日志过滤逻辑
        return logEntry.getLevel().equals("ERROR") || 
               logEntry.getLevel().equals("WARN");
    }
}
```

### 流处理应用原理

#### 1. 流处理架构
**核心组件**：
- **Stream Processor**：流处理器
- **State Store**：状态存储
- **Window Processor**：窗口处理器
- **Aggregator**：聚合器

**处理模式**：
```java
public class StreamProcessingTopology {
    
    public static Topology buildTopology() {
        StreamsBuilder builder = new StreamsBuilder();
        
        // 1. 输入流
        KStream<String, UserEvent> inputStream = builder.stream("user-events");
        
        // 2. 流处理
        KStream<String, ProcessedEvent> processedStream = inputStream
            .filter((key, value) -> value != null)
            .mapValues(this::enrichEvent)
            .groupByKey()
            .windowedBy(TimeWindows.of(Duration.ofMinutes(5)))
            .aggregate(
                () -> new EventAggregator(),
                (key, value, aggregate) -> aggregate.add(value),
                Materialized.as("event-store")
            )
            .toStream()
            .mapValues(aggregator -> aggregator.getResult());
        
        // 3. 输出流
        processedStream.to("processed-events");
        
        return builder.build();
    }
}
```

#### 2. 复杂事件处理
**CEP实现**：
```java
public class ComplexEventProcessor {
    
    @KafkaListener(topics = "user-actions", groupId = "cep-processor")
    public void processUserAction(UserAction action) {
        // 1. 更新用户状态
        updateUserState(action);
        
        // 2. 检测复杂事件
        detectComplexEvents(action);
        
        // 3. 触发响应动作
        triggerResponses(action);
    }
    
    private void detectComplexEvents(UserAction action) {
        // 检测用户行为模式
        if (isSuspiciousActivity(action)) {
            publishSecurityAlert(action);
        }
        
        // 检测业务机会
        if (isBusinessOpportunity(action)) {
            publishRecommendation(action);
        }
    }
}
```

### 事件溯源应用原理

#### 1. 事件溯源架构
**核心概念**：
- **Event Store**：事件存储
- **Event Sourcing**：事件溯源
- **CQRS**：命令查询职责分离
- **Event Replay**：事件重放

**架构设计**：
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Command       │    │   Event         │    │   Query         │
│   Handler       │───►│   Store         │◄───│   Model         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Domain        │    │   Event         │    │   Read          │
│   Model         │    │   Stream        │    │   Model         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### 2. 事件存储实现
**事件存储设计**：
```java
@Entity
public class EventStore {
    @Id
    private String eventId;
    
    private String aggregateId;
    private String eventType;
    private String eventData;
    private long version;
    private LocalDateTime timestamp;
    
    // getters and setters
}

@Service
public class EventSourcingService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void appendEvent(String aggregateId, String eventType, String eventData) {
        // 1. 创建事件
        EventStore event = new EventStore();
        event.setEventId(UUID.randomUUID().toString());
        event.setAggregateId(aggregateId);
        event.setEventType(eventType);
        event.setEventData(eventData);
        event.setTimestamp(LocalDateTime.now());
        
        // 2. 存储事件
        eventStoreRepository.save(event);
        
        // 3. 发布事件到Kafka
        kafkaTemplate.send("event-stream", aggregateId, eventData);
    }
    
    public List<EventStore> getEvents(String aggregateId) {
        return eventStoreRepository.findByAggregateIdOrderByVersion(aggregateId);
    }
    
    public void replayEvents(String aggregateId) {
        List<EventStore> events = getEvents(aggregateId);
        
        for (EventStore event : events) {
            // 重放事件
            replayEvent(event);
        }
    }
}
```

### 微服务通信应用原理

#### 1. 微服务通信模式
**通信模式**：
- **同步通信**：REST API、gRPC
- **异步通信**：消息队列、事件驱动
- **混合通信**：同步+异步结合

**事件驱动架构**：
```java
// 事件发布者
@Service
public class OrderService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void createOrder(OrderRequest request) {
        // 1. 创建订单
        Order order = orderRepository.save(new Order(request));
        
        // 2. 发布订单创建事件
        OrderCreatedEvent event = new OrderCreatedEvent(order.getId(), order.getUserId());
        kafkaTemplate.send("order-events", event.toJson());
        
        // 3. 发布库存检查事件
        InventoryCheckEvent inventoryEvent = new InventoryCheckEvent(order.getItems());
        kafkaTemplate.send("inventory-events", inventoryEvent.toJson());
    }
}

// 事件消费者
@Component
public class InventoryService {
    
    @KafkaListener(topics = "inventory-events", groupId = "inventory-service")
    public void handleInventoryCheck(String eventJson) {
        InventoryCheckEvent event = JsonUtils.parse(eventJson, InventoryCheckEvent.class);
        
        // 处理库存检查
        checkInventory(event.getItems());
    }
}

@Component
public class NotificationService {
    
    @KafkaListener(topics = "order-events", groupId = "notification-service")
    public void handleOrderCreated(String eventJson) {
        OrderCreatedEvent event = JsonUtils.parse(eventJson, OrderCreatedEvent.class);
        
        // 发送通知
        sendOrderNotification(event.getUserId(), event.getOrderId());
    }
}
```

#### 2. 服务发现和负载均衡
**服务发现实现**：
```java
@Component
public class ServiceDiscovery {
    
    @KafkaListener(topics = "service-registry", groupId = "service-discovery")
    public void handleServiceRegistration(String serviceInfo) {
        ServiceInfo info = JsonUtils.parse(serviceInfo, ServiceInfo.class);
        
        // 注册服务
        registerService(info);
    }
    
    public List<ServiceInfo> discoverServices(String serviceName) {
        // 从Kafka获取服务信息
        return getServiceInfoFromKafka(serviceName);
    }
}
```

### 数据管道应用原理

#### 1. 数据管道架构
**核心组件**：
- **Data Source**：数据源
- **Data Processor**：数据处理器
- **Data Sink**：数据目标
- **Data Transformer**：数据转换器

**管道设计**：
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data          │    │   Kafka         │    │   Data          │
│   Source        │───►│   Connect       │───►│   Sink          │
│   (MySQL)       │    │   Pipeline      │    │   (Elasticsearch)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Data          │
                       │   Warehouse     │
                       │   (Hive/Snowflake)│
                       └─────────────────┘
```

#### 2. ETL处理实现
**ETL流程**：
```java
@Component
public class ETLProcessor {
    
    @KafkaListener(topics = "raw-data", groupId = "etl-processor")
    public void processRawData(String rawData) {
        try {
            // 1. Extract - 提取数据
            RawData data = extractData(rawData);
            
            // 2. Transform - 转换数据
            ProcessedData processedData = transformData(data);
            
            // 3. Load - 加载数据
            loadData(processedData);
            
        } catch (Exception e) {
            log.error("ETL processing failed", e);
            // 发送到错误队列
            sendToErrorQueue(rawData, e);
        }
    }
    
    private RawData extractData(String rawData) {
        // 实现数据提取逻辑
        return DataExtractor.extract(rawData);
    }
    
    private ProcessedData transformData(RawData data) {
        // 实现数据转换逻辑
        return DataTransformer.transform(data);
    }
    
    private void loadData(ProcessedData data) {
        // 实现数据加载逻辑
        DataLoader.load(data);
    }
}
```

## 使用场景

### 1. 电商系统应用场景

#### 订单处理流程
**场景描述**：电商平台的订单处理系统，包括订单创建、支付、库存管理、物流等环节

**实现方案**：
```java
// 订单服务
@Service
public class OrderService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void createOrder(OrderRequest request) {
        // 1. 创建订单
        Order order = orderRepository.save(new Order(request));
        
        // 2. 发布订单创建事件
        OrderCreatedEvent event = new OrderCreatedEvent(order.getId(), order.getUserId());
        kafkaTemplate.send("order-events", event.toJson());
        
        // 3. 发布库存检查事件
        InventoryCheckEvent inventoryEvent = new InventoryCheckEvent(order.getItems());
        kafkaTemplate.send("inventory-events", inventoryEvent.toJson());
    }
}

// 库存服务
@Component
public class InventoryService {
    
    @KafkaListener(topics = "inventory-events", groupId = "inventory-service")
    public void handleInventoryCheck(String eventJson) {
        InventoryCheckEvent event = JsonUtils.parse(eventJson, InventoryCheckEvent.class);
        
        // 检查库存
        boolean available = checkInventory(event.getItems());
        
        if (available) {
            // 锁定库存
            lockInventory(event.getItems());
            
            // 发布库存锁定事件
            publishInventoryLockedEvent(event.getOrderId());
        } else {
            // 发布库存不足事件
            publishInventoryInsufficientEvent(event.getOrderId());
        }
    }
}

// 支付服务
@Component
public class PaymentService {
    
    @KafkaListener(topics = "payment-events", groupId = "payment-service")
    public void handlePayment(String eventJson) {
        PaymentEvent event = JsonUtils.parse(eventJson, PaymentEvent.class);
        
        // 处理支付
        PaymentResult result = processPayment(event);
        
        if (result.isSuccess()) {
            // 发布支付成功事件
            publishPaymentSuccessEvent(event.getOrderId());
        } else {
            // 发布支付失败事件
            publishPaymentFailedEvent(event.getOrderId());
        }
    }
}
```

#### 实时推荐系统
**场景描述**：基于用户实时行为生成个性化推荐

**实现方案**：
```java
@Component
public class RecommendationService {
    
    @KafkaListener(topics = "user-behavior", groupId = "recommendation-service")
    public void processUserBehavior(String behaviorJson) {
        UserBehavior behavior = JsonUtils.parse(behaviorJson, UserBehavior.class);
        
        // 更新用户画像
        updateUserProfile(behavior);
        
        // 生成推荐
        List<Recommendation> recommendations = generateRecommendations(behavior);
        
        // 发送推荐结果
        sendRecommendations(behavior.getUserId(), recommendations);
    }
    
    private List<Recommendation> generateRecommendations(UserBehavior behavior) {
        // 实现推荐算法
        return RecommendationEngine.generate(behavior);
    }
}
```

### 2. 金融系统应用场景

#### 实时风控系统
**场景描述**：实时监控交易行为，检测异常交易

**实现方案**：
```java
@Component
public class RiskControlService {
    
    @KafkaListener(topics = "transaction-events", groupId = "risk-control")
    public void monitorTransaction(String transactionJson) {
        Transaction transaction = JsonUtils.parse(transactionJson, Transaction.class);
        
        // 实时风控检查
        RiskAssessment risk = assessRisk(transaction);
        
        if (risk.getRiskLevel() == RiskLevel.HIGH) {
            // 发布高风险交易告警
            publishRiskAlert(transaction, risk);
            
            // 暂停交易
            suspendTransaction(transaction.getId());
        }
    }
    
    private RiskAssessment assessRisk(Transaction transaction) {
        // 实现风控算法
        return RiskEngine.assess(transaction);
    }
}
```

#### 实时清算系统
**场景描述**：实时处理交易清算和结算

**实现方案**：
```java
@Component
public class SettlementService {
    
    @KafkaListener(topics = "settlement-events", groupId = "settlement-service")
    public void processSettlement(String settlementJson) {
        SettlementEvent event = JsonUtils.parse(settlementJson, SettlementEvent.class);
        
        // 处理清算
        SettlementResult result = processSettlement(event);
        
        if (result.isSuccess()) {
            // 发布清算成功事件
            publishSettlementSuccessEvent(event.getTransactionId());
        } else {
            // 发布清算失败事件
            publishSettlementFailedEvent(event.getTransactionId());
        }
    }
}
```

### 3. 物联网应用场景

#### 设备监控系统
**场景描述**：实时监控IoT设备状态和性能

**实现方案**：
```java
@Component
public class DeviceMonitoringService {
    
    @KafkaListener(topics = "device-metrics", groupId = "device-monitoring")
    public void monitorDevice(String metricsJson) {
        DeviceMetrics metrics = JsonUtils.parse(metricsJson, DeviceMetrics.class);
        
        // 分析设备状态
        DeviceStatus status = analyzeDeviceStatus(metrics);
        
        // 检测异常
        if (status.hasAnomaly()) {
            // 发布设备异常告警
            publishDeviceAlert(metrics.getDeviceId(), status);
        }
        
        // 更新设备状态
        updateDeviceStatus(metrics.getDeviceId(), status);
    }
    
    private DeviceStatus analyzeDeviceStatus(DeviceMetrics metrics) {
        // 实现设备状态分析算法
        return DeviceAnalyzer.analyze(metrics);
    }
}
```

#### 智能家居系统
**场景描述**：智能家居设备的事件驱动控制

**实现方案**：
```java
@Component
public class SmartHomeService {
    
    @KafkaListener(topics = "home-events", groupId = "smart-home")
    public void handleHomeEvent(String eventJson) {
        HomeEvent event = JsonUtils.parse(eventJson, HomeEvent.class);
        
        // 根据事件类型执行相应动作
        switch (event.getType()) {
            case MOTION_DETECTED:
                handleMotionDetected(event);
                break;
            case TEMPERATURE_CHANGED:
                handleTemperatureChanged(event);
                break;
            case LIGHT_SWITCH:
                handleLightSwitch(event);
                break;
        }
    }
    
    private void handleMotionDetected(HomeEvent event) {
        // 检测到运动，开启灯光
        turnOnLights(event.getRoomId());
        
        // 发送通知
        sendNotification("Motion detected in " + event.getRoomId());
    }
}
```

## 配置和优化

### 1. 场景特定配置

#### 消息队列配置
```properties
# 高吞吐量配置
producer.batch.size=32768
producer.linger.ms=10
producer.compression.type=snappy
producer.buffer.memory=67108864

# 消费者配置
consumer.max.poll.records=1000
consumer.fetch.max.wait.ms=500
consumer.max.partition.fetch.bytes=1048576
```

#### 日志收集配置
```properties
# 日志Topic配置
log.topic.partitions=8
log.topic.replication.factor=3
log.topic.retention.ms=604800000

# 日志处理配置
log.processor.threads=4
log.processor.batch.size=100
log.processor.timeout.ms=5000
```

#### 流处理配置
```properties
# Streams配置
streams.application.id=streams-app
streams.num.threads=8
streams.commit.interval.ms=1000
streams.cache.max.bytes.buffering=10485760

# 状态存储配置
streams.state.dir=/tmp/kafka-streams
streams.rocksdb.max.write.buffer.number=4
streams.rocksdb.write.buffer.size=67108864
```

### 2. 性能优化策略

#### 吞吐量优化
```java
@Configuration
public class HighThroughputConfig {
    
    @Bean
    public ProducerFactory<String, String> highThroughputProducerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 批量发送配置
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 32768);
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, 10);
        configProps.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");
        configProps.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 67108864);
        
        // 并发配置
        configProps.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5);
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public ConsumerFactory<String, String> highThroughputConsumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 批量消费配置
        configProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 1000);
        configProps.put(ConsumerConfig.FETCH_MAX_BYTES_CONFIG, 52428800);
        configProps.put(ConsumerConfig.FETCH_MIN_BYTES_CONFIG, 1024);
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
}
```

#### 延迟优化
```java
@Configuration
public class LowLatencyConfig {
    
    @Bean
    public ProducerFactory<String, String> lowLatencyProducerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 低延迟配置
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, 1);
        configProps.put(ProducerConfig.ACKS_CONFIG, "1");
        configProps.put(ProducerConfig.RETRIES_CONFIG, 0);
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public ConsumerFactory<String, String> lowLatencyConsumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 低延迟消费配置
        configProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100);
        configProps.put(ConsumerConfig.FETCH_MAX_WAIT_MS_CONFIG, 100);
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
}
```

### 3. 监控和告警

#### 场景特定监控
```java
@Component
public class ScenarioMonitoring {
    
    // 消息队列监控
    @EventListener
    public void monitorMessageQueue(MessageEvent event) {
        // 监控消息处理延迟
        long latency = System.currentTimeMillis() - event.getTimestamp();
        meterRegistry.timer("message.processing.latency").record(latency, TimeUnit.MILLISECONDS);
        
        // 监控消息处理成功率
        if (event.isSuccess()) {
            meterRegistry.counter("message.processing.success").increment();
        } else {
            meterRegistry.counter("message.processing.error").increment();
        }
    }
    
    // 日志收集监控
    @EventListener
    public void monitorLogCollection(LogEvent event) {
        // 监控日志收集量
        meterRegistry.counter("log.collection.volume").increment();
        
        // 监控日志处理延迟
        long processingTime = event.getProcessingTime();
        meterRegistry.timer("log.processing.time").record(processingTime, TimeUnit.MILLISECONDS);
    }
    
    // 流处理监控
    @EventListener
    public void monitorStreamProcessing(StreamEvent event) {
        // 监控流处理延迟
        long latency = event.getLatency();
        meterRegistry.timer("stream.processing.latency").record(latency, TimeUnit.MILLISECONDS);
        
        // 监控状态存储大小
        long stateSize = event.getStateSize();
        meterRegistry.gauge("stream.state.size", stateSize);
    }
}
```

## 最佳实践

### 1. 场景设计最佳实践

#### 消息队列最佳实践
```java
@Service
public class MessageQueueBestPractices {
    
    // 1. 使用幂等性处理
    @KafkaListener(topics = "user-events", groupId = "user-service")
    public void handleUserEvent(String eventJson) {
        UserEvent event = JsonUtils.parse(eventJson, UserEvent.class);
        
        // 检查是否已处理
        if (isEventProcessed(event.getId())) {
            log.info("Event already processed: {}", event.getId());
            return;
        }
        
        // 处理事件
        processUserEvent(event);
        
        // 标记为已处理
        markEventAsProcessed(event.getId());
    }
    
    // 2. 使用死信队列处理失败消息
    @KafkaListener(topics = "dead-letter-queue", groupId = "dlq-processor")
    public void handleDeadLetter(String message) {
        log.error("Processing dead letter message: {}", message);
        
        // 分析失败原因
        analyzeFailureReason(message);
        
        // 重试或告警
        retryOrAlert(message);
    }
    
    // 3. 使用批量处理提高性能
    @KafkaListener(topics = "batch-events", groupId = "batch-processor")
    public void handleBatchEvents(List<String> messages) {
        log.info("Processing batch of {} messages", messages.size());
        
        for (String message : messages) {
            try {
                processMessage(message);
            } catch (Exception e) {
                log.error("Error processing message in batch", e);
                // 发送到死信队列
                sendToDeadLetterQueue(message, e);
            }
        }
    }
}
```

#### 日志收集最佳实践
```java
@Component
public class LogCollectionBestPractices {
    
    // 1. 使用结构化日志
    @KafkaListener(topics = "structured-logs", groupId = "log-processor")
    public void processStructuredLog(String logJson) {
        StructuredLog log = JsonUtils.parse(logJson, StructuredLog.class);
        
        // 根据日志级别分类处理
        switch (log.getLevel()) {
            case "ERROR":
                processErrorLog(log);
                break;
            case "WARN":
                processWarnLog(log);
                break;
            case "INFO":
                processInfoLog(log);
                break;
        }
    }
    
    // 2. 实现日志聚合
    private void aggregateLogs(List<StructuredLog> logs) {
        // 按时间窗口聚合日志
        Map<String, List<StructuredLog>> groupedLogs = logs.stream()
            .collect(Collectors.groupingBy(log -> 
                log.getTimestamp().truncatedTo(ChronoUnit.MINUTES).toString()));
        
        // 处理聚合后的日志
        for (Map.Entry<String, List<StructuredLog>> entry : groupedLogs.entrySet()) {
            processAggregatedLogs(entry.getKey(), entry.getValue());
        }
    }
    
    // 3. 实现日志压缩
    private void compressLogs(List<StructuredLog> logs) {
        // 压缩重复日志
        Map<String, Long> logCounts = logs.stream()
            .collect(Collectors.groupingBy(StructuredLog::getMessage, Collectors.counting()));
        
        // 只保留唯一的日志条目
        for (Map.Entry<String, Long> entry : logCounts.entrySet()) {
            if (entry.getValue() > 1) {
                log.info("Compressed {} duplicate logs: {}", entry.getValue(), entry.getKey());
            }
        }
    }
}
```

### 2. 性能优化实践

#### 高吞吐量优化
```java
@Configuration
public class HighThroughputOptimization {
    
    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> 
            highThroughputListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        
        // 设置高并发
        factory.setConcurrency(8);
        
        // 设置批量消费
        factory.setBatchListener(true);
        factory.getContainerProperties().setPollTimeout(1000);
        
        // 设置消费者属性
        factory.getContainerProperties().setConsumerRebalanceListener(new ConsumerAwareRebalanceListener() {
            @Override
            public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
                // 分区分配时的优化
                optimizePartitionAssignment(partitions);
            }
        });
        
        return factory;
    }
    
    private void optimizePartitionAssignment(Collection<TopicPartition> partitions) {
        // 实现分区分配优化
        for (TopicPartition partition : partitions) {
            // 设置分区特定的配置
            configurePartitionOptimization(partition);
        }
    }
}
```

#### 低延迟优化
```java
@Configuration
public class LowLatencyOptimization {
    
    @Bean
    public ProducerFactory<String, String> lowLatencyProducerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 低延迟配置
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, 1);
        configProps.put(ProducerConfig.ACKS_CONFIG, "1");
        configProps.put(ProducerConfig.RETRIES_CONFIG, 0);
        configProps.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 1);
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public ConsumerFactory<String, String> lowLatencyConsumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 低延迟消费配置
        configProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100);
        configProps.put(ConsumerConfig.FETCH_MAX_WAIT_MS_CONFIG, 100);
        configProps.put(ConsumerConfig.FETCH_MIN_BYTES_CONFIG, 1);
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
}
```

### 3. 运维最佳实践

#### 监控告警
```java
@Component
public class ScenarioMonitoring {
    
    // 监控关键指标
    @Scheduled(fixedRate = 60000) // 每分钟执行一次
    public void monitorKeyMetrics() {
        // 监控消息处理延迟
        Timer.Sample sample = Timer.start(meterRegistry);
        processMetrics();
        sample.stop(Timer.builder("metrics.processing.time").register(meterRegistry));
        
        // 监控错误率
        long errorCount = meterRegistry.counter("message.processing.error").count();
        long totalCount = meterRegistry.counter("message.processing.total").count();
        
        if (totalCount > 0) {
            double errorRate = (double) errorCount / totalCount;
            if (errorRate > 0.05) { // 错误率超过5%
                sendAlert("High error rate detected: " + (errorRate * 100) + "%");
            }
        }
    }
    
    // 监控系统健康状态
    @EventListener
    public void monitorSystemHealth(HealthCheckEvent event) {
        if (!event.isHealthy()) {
            sendAlert("System health check failed: " + event.getDetails());
        }
    }
}
```

## 关联知识点

### 相关技术
- **[Kafka核心概念](001-Kafka核心概念详解.md)**：理解Kafka基础架构
- **[Kafka Producer详解](004-Kafka Producer详解.md)**：了解消息发送机制
- **[Kafka Consumer详解](005-Kafka Consumer详解.md)**：了解消息消费机制
- **[Kafka Streams详解](011-Kafka Streams详解.md)**：了解流处理框架
- **[Kafka Connect详解](010-Kafka Connect详解.md)**：了解数据集成框架

### 扩展阅读
- **[Kafka监控和运维](009-Kafka监控和运维.md)**：学习应用场景监控
- **[Kafka最佳实践](015-Kafka最佳实践.md)**：了解场景最佳实践
- **[Spring Kafka集成](016-Spring Kafka集成.md)**：了解Spring集成方案

### 实践项目
1. **电商订单系统**：构建完整的订单处理流程
2. **实时风控系统**：实现金融风控监控
3. **IoT监控平台**：构建设备监控和告警系统 