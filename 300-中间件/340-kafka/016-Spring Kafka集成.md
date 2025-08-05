# Spring Kafka集成详解

## 重点内容

本文档重点介绍Spring Kafka集成框架，包括Spring Kafka配置、@KafkaListener使用、KafkaTemplate使用、事务支持、错误处理、测试支持等核心功能，帮助读者理解和使用Spring Kafka进行消息驱动开发。

## Spring Kafka介绍

### 什么是Spring Kafka
Spring Kafka是Spring Framework提供的Kafka集成模块，它简化了Kafka客户端的使用，提供了声明式的消息监听器、模板化的消息发送、事务支持等功能，使得在Spring应用中集成Kafka变得更加简单和高效。

### Spring Kafka的核心特性
- **声明式监听**：使用注解简化消息监听器开发
- **模板化发送**：提供KafkaTemplate简化消息发送
- **事务支持**：集成Spring事务管理
- **错误处理**：提供丰富的错误处理机制
- **测试支持**：提供嵌入式Kafka测试环境
- **配置简化**：通过配置文件简化Kafka配置

### Spring Kafka架构设计

#### 1. 核心组件架构
**主要组件**：
- **KafkaTemplate**：消息发送模板
- **@KafkaListener**：消息监听器注解
- **KafkaListenerContainerFactory**：监听器容器工厂
- **KafkaTransactionManager**：事务管理器
- **KafkaMessageListenerContainer**：消息监听容器

**架构图**：
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Spring        │    │   Spring        │    │   Apache        │
│   Application   │◄──►│   Kafka         │◄──►│   Kafka         │
│   (Business)    │    │   Framework     │    │   Cluster       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   @KafkaListener│    │   KafkaTemplate │    │   Topics        │
│   (Consumer)    │    │   (Producer)    │    │   (Messages)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### 2. 消息处理流程
**生产者流程**：
1. 应用调用KafkaTemplate
2. Spring Kafka处理序列化
3. 发送到Kafka集群
4. 返回发送结果

**消费者流程**：
1. Kafka集群推送消息
2. Spring Kafka接收消息
3. 反序列化消息
4. 调用@KafkaListener方法
5. 处理业务逻辑

## 底层原理

### Spring Kafka核心类设计

#### 1. KafkaTemplate设计
**核心类**：`org.springframework.kafka.core.KafkaTemplate`

**关键方法**：
```java
public class KafkaTemplate<K, V> implements KafkaOperations<K, V> {
    
    // 同步发送消息
    public ListenableFuture<SendResult<K, V>> send(String topic, V data);
    public ListenableFuture<SendResult<K, V>> send(String topic, K key, V data);
    
    // 异步发送消息
    public CompletableFuture<SendResult<K, V>> sendDefault(V data);
    public CompletableFuture<SendResult<K, V>> sendDefault(K key, V data);
    
    // 事务性发送
    public ListenableFuture<SendResult<K, V>> executeInTransaction(OperationsCallback<K, V> callback);
}
```

**设计思想**：
- 模板模式，封装复杂的Kafka操作
- 支持同步和异步发送
- 集成Spring事务管理
- 提供丰富的回调机制

#### 2. @KafkaListener注解处理
**核心注解**：`org.springframework.kafka.annotation.KafkaListener`

**注解处理器**：`org.springframework.kafka.annotation.KafkaListenerAnnotationBeanPostProcessor`

**处理流程**：
```java
public class KafkaListenerAnnotationBeanPostProcessor implements BeanPostProcessor {
    
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) {
        // 1. 扫描类中的@KafkaListener注解
        Method[] methods = bean.getClass().getMethods();
        for (Method method : methods) {
            KafkaListener annotation = method.getAnnotation(KafkaListener.class);
            if (annotation != null) {
                // 2. 创建监听器容器
                createListenerContainer(bean, method, annotation);
            }
        }
        return bean;
    }
    
    private void createListenerContainer(Object bean, Method method, KafkaListener annotation) {
        // 3. 配置监听器容器
        KafkaListenerContainerFactory<?> factory = getContainerFactory(annotation);
        MessageListenerContainer container = factory.createContainer(annotation.topics());
        
        // 4. 设置消息监听器
        container.setupMessageListener(new MethodInvokingMessageListener(bean, method));
        
        // 5. 启动容器
        container.start();
    }
}
```

#### 3. 消息监听器容器
**核心类**：`org.springframework.kafka.listener.KafkaMessageListenerContainer`

**容器生命周期**：
```java
public class KafkaMessageListenerContainer<K, V> extends AbstractMessageListenerContainer<K, V> {
    
    @Override
    protected void doStart() {
        // 1. 创建消费者
        Consumer<K, V> consumer = createConsumer();
        
        // 2. 订阅Topic
        consumer.subscribe(Arrays.asList(topics));
        
        // 3. 启动消费线程
        startConsumerThread(consumer);
    }
    
    private void startConsumerThread(Consumer<K, V> consumer) {
        Thread consumerThread = new Thread(() -> {
            while (isRunning()) {
                try {
                    // 4. 轮询消息
                    ConsumerRecords<K, V> records = consumer.poll(Duration.ofMillis(100));
                    
                    // 5. 处理消息
                    for (ConsumerRecord<K, V> record : records) {
                        processMessage(record);
                    }
                    
                    // 6. 提交偏移量
                    consumer.commitSync();
                } catch (Exception e) {
                    handleConsumerException(e);
                }
            }
        });
        consumerThread.start();
    }
}
```

### 配置管理机制

#### 1. 自动配置类
**核心类**：`org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration`

**配置加载过程**：
```java
@Configuration
@ConditionalOnClass(KafkaTemplate.class)
@EnableConfigurationProperties(KafkaProperties.class)
public class KafkaAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    public KafkaTemplate<?, ?> kafkaTemplate(ProducerFactory<Object, Object> producerFactory) {
        KafkaTemplate<Object, Object> template = new KafkaTemplate<>(producerFactory);
        // 配置默认序列化器
        template.setDefaultTopic(kafkaProperties.getTemplate().getDefaultTopic());
        return template;
    }
    
    @Bean
    @ConditionalOnMissingBean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<Object, Object>> 
            kafkaListenerContainerFactory(ConsumerFactory<Object, Object> consumerFactory) {
        ConcurrentKafkaListenerContainerFactory<Object, Object> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        // 配置并发消费者
        factory.setConcurrency(kafkaProperties.getListener().getConcurrency());
        return factory;
    }
}
```

#### 2. 属性配置绑定
**配置属性类**：`org.springframework.boot.autoconfigure.kafka.KafkaProperties`

**配置映射**：
```java
@ConfigurationProperties(prefix = "spring.kafka")
public class KafkaProperties {
    
    // Producer配置
    private final Producer producer = new Producer();
    
    // Consumer配置
    private final Consumer consumer = new Consumer();
    
    // Listener配置
    private final Listener listener = new Listener();
    
    // Template配置
    private final Template template = new Template();
    
    public static class Producer {
        private Map<String, String> properties = new HashMap<>();
        private String keySerializer = StringSerializer.class.getName();
        private String valueSerializer = StringSerializer.class.getName();
    }
    
    public static class Consumer {
        private Map<String, String> properties = new HashMap<>();
        private String keyDeserializer = StringDeserializer.class.getName();
        private String valueDeserializer = StringDeserializer.class.getName();
        private String groupId;
        private String autoOffsetReset = "latest";
    }
}
```

### 事务支持机制

#### 1. 事务管理器
**核心类**：`org.springframework.kafka.transaction.KafkaTransactionManager`

**事务实现**：
```java
public class KafkaTransactionManager extends AbstractPlatformTransactionManager {
    
    private final ProducerFactory<K, V> producerFactory;
    
    @Override
    protected Object doGetTransaction() {
        KafkaTransactionObject txObject = new KafkaTransactionObject();
        txObject.setProducerFactory(producerFactory);
        return txObject;
    }
    
    @Override
    protected void doBegin(Object transaction, TransactionDefinition definition) {
        KafkaTransactionObject txObject = (KafkaTransactionObject) transaction;
        
        // 1. 创建事务性Producer
        Producer<K, V> producer = producerFactory.createProducer();
        producer.beginTransaction();
        
        // 2. 设置事务上下文
        txObject.setProducer(producer);
        TransactionSynchronizationManager.bindResource(producerFactory, producer);
    }
    
    @Override
    protected void doCommit(DefaultTransactionStatus status) {
        KafkaTransactionObject txObject = (KafkaTransactionObject) status.getTransaction();
        Producer<K, V> producer = txObject.getProducer();
        
        // 提交事务
        producer.commitTransaction();
        producer.close();
    }
    
    @Override
    protected void doRollback(DefaultTransactionStatus status) {
        KafkaTransactionObject txObject = (KafkaTransactionObject) status.getTransaction();
        Producer<K, V> producer = txObject.getProducer();
        
        // 回滚事务
        producer.abortTransaction();
        producer.close();
    }
}
```

#### 2. 事务性操作
**事务模板使用**：
```java
@Service
public class TransactionalKafkaService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Transactional
    public void processWithTransaction(String message) {
        // 1. 数据库操作
        userRepository.save(new User("test"));
        
        // 2. Kafka发送（在事务中）
        kafkaTemplate.send("user-events", message);
        
        // 3. 如果任何操作失败，都会回滚
    }
    
    @Transactional
    public void executeInTransaction() {
        kafkaTemplate.executeInTransaction(operations -> {
            // 在事务中执行多个Kafka操作
            operations.send("topic1", "message1");
            operations.send("topic2", "message2");
            return null;
        });
    }
}
```

## 使用场景

### 1. 消息发送场景
**场景描述**：使用KafkaTemplate发送消息到Kafka集群

**实现示例**：
```java
@Service
public class MessageProducerService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    // 同步发送
    public void sendMessageSync(String topic, String message) {
        try {
            ListenableFuture<SendResult<String, String>> future = 
                kafkaTemplate.send(topic, message);
            
            SendResult<String, String> result = future.get(10, TimeUnit.SECONDS);
            log.info("Message sent successfully: topic={}, partition={}, offset={}", 
                result.getRecordMetadata().topic(),
                result.getRecordMetadata().partition(),
                result.getRecordMetadata().offset());
        } catch (Exception e) {
            log.error("Failed to send message", e);
            throw new RuntimeException("Message sending failed", e);
        }
    }
    
    // 异步发送
    public void sendMessageAsync(String topic, String message) {
        CompletableFuture<SendResult<String, String>> future = 
            kafkaTemplate.send(topic, message);
        
        future.whenComplete((result, throwable) -> {
            if (throwable != null) {
                log.error("Failed to send message asynchronously", throwable);
            } else {
                log.info("Message sent asynchronously: topic={}, partition={}", 
                    result.getRecordMetadata().topic(),
                    result.getRecordMetadata().partition());
            }
        });
    }
    
    // 带Key的发送
    public void sendMessageWithKey(String topic, String key, String message) {
        kafkaTemplate.send(topic, key, message)
            .addCallback(
                result -> log.info("Message sent with key: key={}", key),
                ex -> log.error("Failed to send message with key: key={}", key, ex)
            );
    }
}
```

### 2. 消息消费场景
**场景描述**：使用@KafkaListener消费Kafka消息

**实现示例**：
```java
@Component
public class MessageConsumerService {
    
    // 简单消息消费
    @KafkaListener(topics = "user-events", groupId = "user-group")
    public void consumeUserEvents(String message) {
        log.info("Received user event: {}", message);
        // 处理用户事件
        processUserEvent(message);
    }
    
    // 带消费者组和分区分配的消息消费
    @KafkaListener(
        topics = "order-events",
        groupId = "order-group",
        containerFactory = "orderListenerContainerFactory"
    )
    public void consumeOrderEvents(
            @Payload String message,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION_ID) int partition,
            @Header(KafkaHeaders.OFFSET) long offset) {
        
        log.info("Received order event: topic={}, partition={}, offset={}, message={}", 
            topic, partition, offset, message);
        
        // 处理订单事件
        processOrderEvent(message);
    }
    
    // 批量消息消费
    @KafkaListener(
        topics = "batch-events",
        groupId = "batch-group",
        containerFactory = "batchListenerContainerFactory"
    )
    public void consumeBatchEvents(List<String> messages) {
        log.info("Received batch of {} messages", messages.size());
        
        for (String message : messages) {
            processBatchEvent(message);
        }
    }
    
    // 带错误处理的消息消费
    @KafkaListener(
        topics = "error-prone-events",
        groupId = "error-group",
        errorHandler = "kafkaErrorHandler"
    )
    public void consumeWithErrorHandling(String message) {
        try {
            processEventWithPotentialError(message);
        } catch (Exception e) {
            log.error("Error processing message: {}", message, e);
            throw e; // 重新抛出异常，触发错误处理器
        }
    }
}
```

### 3. 事务性消息处理场景
**场景描述**：在Spring事务中处理数据库操作和Kafka消息发送

**实现示例**：
```java
@Service
@Transactional
public class TransactionalMessageService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    // 事务性用户注册
    public void registerUser(UserRegistrationRequest request) {
        // 1. 保存用户到数据库
        User user = new User(request.getUsername(), request.getEmail());
        userRepository.save(user);
        
        // 2. 发送用户注册事件到Kafka
        UserRegisteredEvent event = new UserRegisteredEvent(user.getId(), user.getUsername());
        kafkaTemplate.send("user-registered", event.toJson());
        
        // 3. 如果任何操作失败，整个事务都会回滚
        log.info("User registered successfully: {}", user.getUsername());
    }
    
    // 事务性订单处理
    public void processOrder(OrderRequest request) {
        // 1. 创建订单
        Order order = new Order(request.getUserId(), request.getItems());
        orderRepository.save(order);
        
        // 2. 更新库存
        inventoryService.updateStock(request.getItems());
        
        // 3. 发送订单创建事件
        OrderCreatedEvent event = new OrderCreatedEvent(order.getId(), order.getUserId());
        kafkaTemplate.send("order-created", event.toJson());
        
        // 4. 发送库存更新事件
        StockUpdatedEvent stockEvent = new StockUpdatedEvent(request.getItems());
        kafkaTemplate.send("stock-updated", stockEvent.toJson());
    }
}
```

## 配置和优化

### 1. Spring Kafka配置

#### 基础配置
```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    client-id: spring-kafka-app
    
    # Producer配置
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
      acks: all
      retries: 3
      batch-size: 16384
      linger-ms: 1
      buffer-memory: 33554432
      compression-type: snappy
    
    # Consumer配置
    consumer:
      group-id: spring-kafka-group
      auto-offset-reset: latest
      enable-auto-commit: false
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      max-poll-records: 500
      session-timeout-ms: 30000
      heartbeat-interval-ms: 10000
    
    # Listener配置
    listener:
      concurrency: 3
      poll-timeout: 3000
      ack-mode: manual_immediate
      type: single
```

#### 高级配置
```java
@Configuration
public class KafkaConfig {
    
    @Bean
    public ProducerFactory<String, String> producerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        configProps.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "spring-kafka-transaction");
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        configProps.put(ConsumerConfig.GROUP_ID_CONFIG, "spring-kafka-group");
        configProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        configProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        configProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
        configProps.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
    
    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> 
            kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.setConcurrency(3);
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL_IMMEDIATE);
        factory.getContainerProperties().setPollTimeout(3000);
        
        return factory;
    }
}
```

### 2. 错误处理配置

#### 错误处理器
```java
@Component
public class KafkaErrorHandler implements ConsumerAwareErrorHandler {
    
    @Override
    public void handle(Exception thrownException, 
                      List<ConsumerRecord<?, ?>> records, 
                      Consumer<?, ?> consumer) {
        
        log.error("Error processing Kafka records", thrownException);
        
        for (ConsumerRecord<?, ?> record : records) {
            log.error("Failed record: topic={}, partition={}, offset={}, key={}, value={}", 
                record.topic(), record.partition(), record.offset(), 
                record.key(), record.value());
            
            // 发送到死信队列
            sendToDeadLetterQueue(record);
        }
        
        // 根据异常类型决定是否继续消费
        if (thrownException instanceof DeserializationException) {
            // 反序列化错误，跳过消息
            consumer.seek(record.topicPartition(), record.offset() + 1);
        } else if (thrownException instanceof BusinessException) {
            // 业务异常，重试或跳过
            handleBusinessException(record, thrownException);
        }
    }
}
```

#### 重试机制
```java
@Configuration
public class RetryConfig {
    
    @Bean
    public RetryPolicy retryPolicy() {
        return RetryPolicy.builder()
            .maxAttempts(3)
            .backoff(Duration.ofSeconds(1))
            .retryOn(BusinessException.class)
            .build();
    }
    
    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> 
            retryableListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.setCommonErrorHandler(new DefaultErrorHandler(retryPolicy()));
        
        return factory;
    }
}
```

### 3. 监控和指标

#### 监控配置
```java
@Configuration
@EnableKafka
public class KafkaMonitoringConfig {
    
    @Bean
    public MeterRegistry meterRegistry() {
        return new SimpleMeterRegistry();
    }
    
    @Bean
    public KafkaTemplate<String, String> monitoredKafkaTemplate(
            ProducerFactory<String, String> producerFactory,
            MeterRegistry meterRegistry) {
        
        KafkaTemplate<String, String> template = new KafkaTemplate<>(producerFactory);
        
        // 添加监控指标
        template.setProducerListener(new ProducerListener<String, String>() {
            @Override
            public void onSuccess(ProducerRecord<String, String> producerRecord, 
                                RecordMetadata recordMetadata) {
                meterRegistry.counter("kafka.producer.success").increment();
            }
            
            @Override
            public void onError(ProducerRecord<String, String> producerRecord, 
                              RecordMetadata recordMetadata, Exception exception) {
                meterRegistry.counter("kafka.producer.error").increment();
            }
        });
        
        return template;
    }
}
```

## 最佳实践

### 1. 应用设计最佳实践

#### 消息发送最佳实践
```java
@Service
public class KafkaProducerBestPractices {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    // 1. 使用异步发送提高性能
    public void sendMessageAsync(String topic, String message) {
        kafkaTemplate.send(topic, message)
            .addCallback(
                result -> log.info("Message sent successfully: topic={}, partition={}", 
                    result.getRecordMetadata().topic(), result.getRecordMetadata().partition()),
                ex -> log.error("Failed to send message", ex)
            );
    }
    
    // 2. 使用事务保证一致性
    @Transactional
    public void sendMessageInTransaction(String topic, String message) {
        // 数据库操作
        userRepository.save(new User("test"));
        
        // Kafka发送（在事务中）
        kafkaTemplate.send(topic, message);
    }
    
    // 3. 使用批量发送提高吞吐量
    public void sendBatchMessages(String topic, List<String> messages) {
        List<ListenableFuture<SendResult<String, String>>> futures = new ArrayList<>();
        
        for (String message : messages) {
            futures.add(kafkaTemplate.send(topic, message));
        }
        
        // 等待所有消息发送完成
        ListenableFuture<List<SendResult<String, String>>> allFutures = 
            new ListenableFutureTask<>(() -> futures.stream()
                .map(future -> {
                    try {
                        return future.get(10, TimeUnit.SECONDS);
                    } catch (Exception e) {
                        throw new RuntimeException("Failed to send message", e);
                    }
                })
                .collect(Collectors.toList()));
        
        allFutures.addCallback(
            results -> log.info("All {} messages sent successfully", results.size()),
            ex -> log.error("Failed to send batch messages", ex)
        );
    }
}
```

#### 消息消费最佳实践
```java
@Component
public class KafkaConsumerBestPractices {
    
    // 1. 使用手动提交偏移量
    @KafkaListener(
        topics = "user-events",
        groupId = "user-group",
        containerFactory = "manualAckListenerContainerFactory"
    )
    public void consumeWithManualAck(
            String message,
            Acknowledgment ack) {
        
        try {
            processUserEvent(message);
            // 手动提交偏移量
            ack.acknowledge();
        } catch (Exception e) {
            log.error("Error processing message", e);
            // 不提交偏移量，消息会被重新消费
        }
    }
    
    // 2. 使用批量消费提高性能
    @KafkaListener(
        topics = "batch-events",
        groupId = "batch-group",
        containerFactory = "batchListenerContainerFactory"
    )
    public void consumeBatch(List<String> messages) {
        log.info("Processing batch of {} messages", messages.size());
        
        for (String message : messages) {
            try {
                processBatchEvent(message);
            } catch (Exception e) {
                log.error("Error processing batch message: {}", message, e);
                // 处理单个消息错误
            }
        }
    }
    
    // 3. 使用条件消费
    @KafkaListener(
        topics = "conditional-events",
        groupId = "conditional-group",
        containerFactory = "conditionalListenerContainerFactory"
    )
    public void consumeConditionally(String message) {
        // 根据消息内容决定是否处理
        if (shouldProcessMessage(message)) {
            processConditionalEvent(message);
        } else {
            log.info("Skipping message: {}", message);
        }
    }
    
    private boolean shouldProcessMessage(String message) {
        // 实现条件判断逻辑
        return message != null && !message.isEmpty();
    }
}
```

### 2. 性能优化实践

#### 并发优化
```java
@Configuration
public class KafkaPerformanceConfig {
    
    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> 
            highPerformanceListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        
        // 设置高并发
        factory.setConcurrency(8);
        
        // 设置批量消费
        factory.setBatchListener(true);
        factory.getContainerProperties().setPollTimeout(1000);
        
        // 设置消费者属性
        factory.getContainerProperties().setConsumerRebalanceListener(new ConsumerAwareRebalanceListener() {
            @Override
            public void onPartitionsRevokedBeforeCommit(Consumer<?, ?> consumer, 
                                                      Collection<TopicPartition> partitions) {
                // 分区撤销时的处理
            }
            
            @Override
            public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
                // 分区分配时的处理
            }
        });
        
        return factory;
    }
}
```

#### 内存优化
```java
@Configuration
public class KafkaMemoryConfig {
    
    @Bean
    public ProducerFactory<String, String> optimizedProducerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 内存优化配置
        configProps.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 67108864); // 64MB
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 32768); // 32KB
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, 10);
        configProps.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public ConsumerFactory<String, String> optimizedConsumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // 内存优化配置
        configProps.put(ConsumerConfig.FETCH_MAX_BYTES_CONFIG, 52428800); // 50MB
        configProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 1000);
        configProps.put(ConsumerConfig.FETCH_MIN_BYTES_CONFIG, 1024);
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
}
```

### 3. 测试最佳实践

#### 集成测试
```java
@SpringBootTest
@EmbeddedKafka(partitions = 1, topics = {"test-topic"})
class KafkaIntegrationTest {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Autowired
    private KafkaTestUtils kafkaTestUtils;
    
    @Test
    void testMessageSendingAndReceiving() throws Exception {
        // 发送消息
        String message = "test message";
        kafkaTemplate.send("test-topic", message);
        
        // 等待消息被消费
        ConsumerRecord<String, String> record = kafkaTestUtils.getSingleRecord("test-topic");
        
        assertEquals(message, record.value());
    }
    
    @Test
    void testBatchProcessing() throws Exception {
        // 发送批量消息
        List<String> messages = Arrays.asList("msg1", "msg2", "msg3");
        for (String message : messages) {
            kafkaTemplate.send("test-topic", message);
        }
        
        // 验证批量消费
        List<ConsumerRecord<String, String>> records = 
            kafkaTestUtils.getRecords("test-topic", 3, 5000);
        
        assertEquals(3, records.size());
    }
}
```

#### 单元测试
```java
@ExtendWith(MockitoExtension.class)
class KafkaServiceTest {
    
    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Mock
    private ListenableFuture<SendResult<String, String>> future;
    
    @InjectMocks
    private MessageService messageService;
    
    @Test
    void testSendMessage() throws Exception {
        // 准备测试数据
        String topic = "test-topic";
        String message = "test message";
        SendResult<String, String> result = mock(SendResult.class);
        
        // 模拟KafkaTemplate行为
        when(kafkaTemplate.send(topic, message)).thenReturn(future);
        when(future.get(anyLong(), any(TimeUnit.class))).thenReturn(result);
        
        // 执行测试
        messageService.sendMessage(topic, message);
        
        // 验证调用
        verify(kafkaTemplate).send(topic, message);
    }
}
```

## 关联知识点

### 相关技术
- **[Kafka核心概念](001-Kafka核心概念详解.md)**：理解Kafka基础架构
- **[Kafka Producer详解](004-Kafka Producer详解.md)**：了解消息发送机制
- **[Kafka Consumer详解](005-Kafka Consumer详解.md)**：了解消息消费机制
- **[Spring框架基础](../200-Spring/0101-Spring IoC容器.md)**：理解Spring核心概念

### 扩展阅读
- **[Kafka监控和运维](009-Kafka监控和运维.md)**：学习Spring Kafka监控
- **[Kafka最佳实践](015-Kafka最佳实践.md)**：了解Spring Kafka最佳实践
- **[Spring事务管理](../200-Spring/0103-Spring依赖注入.md)**：理解事务管理机制

### 实践项目
1. **消息驱动微服务**：构建基于Spring Kafka的微服务架构
2. **实时数据处理**：使用Spring Kafka进行实时数据流处理
3. **事件驱动架构**：实现基于事件的系统集成 