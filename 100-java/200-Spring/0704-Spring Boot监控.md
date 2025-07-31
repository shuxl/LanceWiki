# Spring Boot监控

## 重点内容
- Spring Boot Actuator监控端点
- 健康检查和自定义健康指示器
- 指标收集和Micrometer集成
- 应用信息暴露和自定义端点
- 监控数据可视化和告警
- 性能监控和链路追踪

## Spring Boot监控概念或介绍

Spring Boot监控是Spring Boot框架提供的应用监控和管理功能，通过Spring Boot Actuator模块实现。它提供了丰富的监控端点，可以监控应用的健康状态、性能指标、配置信息等，帮助开发者了解应用的运行状态，及时发现和解决问题。

### 监控功能特点
1. **健康检查**：提供应用健康状态检查
2. **指标收集**：收集应用运行时的各种指标
3. **信息暴露**：暴露应用配置、环境等信息
4. **自定义端点**：支持自定义监控端点
5. **安全控制**：提供细粒度的安全控制
6. **可视化**：支持与监控系统集成

## 底层原理

### 关键类和接口

#### Endpoint接口
```java
public interface Endpoint<T> {
    
    // 端点ID
    String getId();
    
    // 端点是否启用
    boolean isEnabled();
    
    // 端点是否敏感
    boolean isSensitive();
    
    // 端点响应
    T invoke();
}
```

#### HealthIndicator接口
```java
public interface HealthIndicator {
    
    // 健康检查
    Health health();
    
    // 默认实现
    default Health getHealth(boolean includeDetails) {
        Health health = health();
        return includeDetails ? health : health.withoutDetails();
    }
}
```

#### MeterRegistry接口
```java
public interface MeterRegistry extends MeterProvider {
    
    // 创建计数器
    Counter counter(String name, Iterable<Tag> tags);
    
    // 创建计时器
    Timer timer(String name, Iterable<Tag> tags);
    
    // 创建仪表
    Gauge gauge(String name, Iterable<Tag> tags, ToDoubleFunction<T> obj);
    
    // 创建分布摘要
    DistributionSummary summary(String name, Iterable<Tag> tags);
}
```

### 关键类图

```
EndpointAutoConfiguration
    ↓
Endpoint
    ↓
HealthIndicator
    ↓
MeterRegistry
    ↓
Micrometer
    ↓
Monitoring System
```

### 核心代码讲解

#### 1. 健康检查端点
```java
@Endpoint(id = "health")
public class HealthEndpoint {
    
    private final HealthIndicator healthIndicator;
    
    public HealthEndpoint(HealthIndicator healthIndicator) {
        this.healthIndicator = healthIndicator;
    }
    
    @ReadOperation
    public Health health() {
        return this.healthIndicator.health();
    }
    
    @ReadOperation
    public Health healthForComponent(@Selector String name) {
        HealthIndicator indicator = getHealthIndicator(name);
        return indicator.health();
    }
}
```

#### 2. 自定义健康指示器
```java
@Component
public class DatabaseHealthIndicator implements HealthIndicator {
    
    @Autowired
    private DataSource dataSource;
    
    @Override
    public Health health() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(1000)) {
                return Health.up()
                    .withDetail("database", "Available")
                    .withDetail("validationQuery", "SELECT 1")
                    .build();
            } else {
                return Health.down()
                    .withDetail("database", "Unavailable")
                    .withDetail("error", "Connection validation failed")
                    .build();
            }
        } catch (SQLException e) {
            return Health.down()
                .withDetail("database", "Unavailable")
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

#### 3. 指标收集
```java
@Component
public class MetricsService {
    
    private final MeterRegistry meterRegistry;
    private final Counter requestCounter;
    private final Timer requestTimer;
    
    public MetricsService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.requestCounter = Counter.builder("app.requests.total")
            .description("Total number of requests")
            .register(meterRegistry);
        this.requestTimer = Timer.builder("app.requests.duration")
            .description("Request duration")
            .register(meterRegistry);
    }
    
    public void recordRequest() {
        requestCounter.increment();
    }
    
    public Timer.Sample startTimer() {
        return Timer.start(meterRegistry);
    }
    
    public void stopTimer(Timer.Sample sample) {
        sample.stop(requestTimer);
    }
}
```

### 设计思想

#### 1. 端点驱动
通过REST端点暴露监控信息，便于集成和访问。

#### 2. 健康检查
提供应用健康状态检查，支持自定义健康指示器。

#### 3. 指标收集
通过Micrometer收集应用指标，支持多种监控系统。

#### 4. 安全控制
提供细粒度的安全控制，保护敏感监控信息。

## Spring Boot Actuator端点

### 内置端点
```properties
# application.properties
# 启用所有端点
management.endpoints.web.exposure=*

# 启用特定端点
management.endpoints.web.exposure=health,info,metrics,env

# 端点基础路径
management.endpoints.web.base-path=/actuator

# 端点超时时间
management.endpoint.health.timeout=10s
```

### 端点列表
| 端点 | 描述 | 默认启用 |
|------|------|----------|
| `/actuator/health` | 应用健康状态 | 是 |
| `/actuator/info` | 应用信息 | 是 |
| `/actuator/metrics` | 应用指标 | 是 |
| `/actuator/env` | 环境变量 | 否 |
| `/actuator/configprops` | 配置属性 | 否 |
| `/actuator/beans` | Bean信息 | 否 |
| `/actuator/mappings` | 请求映射 | 否 |
| `/actuator/threaddump` | 线程转储 | 否 |
| `/actuator/heapdump` | 堆转储 | 否 |

### 健康检查端点
```json
{
  "status": "UP",
  "components": {
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 499963174912,
        "free": 419430400000,
        "threshold": 10485760
      }
    },
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "SELECT 1"
      }
    }
  }
}
```

## 自定义监控端点

### 自定义端点
```java
@Endpoint(id = "custom")
public class CustomEndpoint {
    
    @ReadOperation
    public Map<String, Object> customInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("timestamp", System.currentTimeMillis());
        info.put("version", "1.0.0");
        info.put("status", "running");
        return info;
    }
    
    @WriteOperation
    public void updateStatus(@Selector String name, String value) {
        // 更新状态逻辑
        System.out.println("Updating " + name + " to " + value);
    }
}
```

### 自定义健康指示器
```java
@Component
public class CustomHealthIndicator implements HealthIndicator {
    
    @Override
    public Health health() {
        // 检查自定义组件健康状态
        boolean isHealthy = checkCustomComponent();
        
        if (isHealthy) {
            return Health.up()
                .withDetail("customComponent", "Available")
                .withDetail("lastCheck", System.currentTimeMillis())
                .build();
        } else {
            return Health.down()
                .withDetail("customComponent", "Unavailable")
                .withDetail("error", "Component check failed")
                .build();
        }
    }
    
    private boolean checkCustomComponent() {
        // 自定义健康检查逻辑
        return true;
    }
}
```

## 指标收集和Micrometer

### Micrometer集成
```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### 自定义指标
```java
@Component
public class CustomMetrics {
    
    private final MeterRegistry meterRegistry;
    private final Counter customCounter;
    private final Timer customTimer;
    private final Gauge customGauge;
    
    public CustomMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        
        // 创建计数器
        this.customCounter = Counter.builder("app.custom.counter")
            .description("Custom application counter")
            .register(meterRegistry);
        
        // 创建计时器
        this.customTimer = Timer.builder("app.custom.timer")
            .description("Custom application timer")
            .register(meterRegistry);
        
        // 创建仪表
        this.customGauge = Gauge.builder("app.custom.gauge", this, this::getGaugeValue)
            .description("Custom application gauge")
            .register(meterRegistry);
    }
    
    public void incrementCounter() {
        customCounter.increment();
    }
    
    public Timer.Sample startTimer() {
        return Timer.start(meterRegistry);
    }
    
    public void stopTimer(Timer.Sample sample) {
        sample.stop(customTimer);
    }
    
    private double getGaugeValue() {
        // 返回仪表值
        return Math.random() * 100;
    }
}
```

### 业务指标收集
```java
@RestController
public class MetricsController {
    
    private final MeterRegistry meterRegistry;
    private final Counter requestCounter;
    private final Timer requestTimer;
    
    public MetricsController(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.requestCounter = Counter.builder("app.requests")
            .tag("endpoint", "api")
            .register(meterRegistry);
        this.requestTimer = Timer.builder("app.request.duration")
            .tag("endpoint", "api")
            .register(meterRegistry);
    }
    
    @GetMapping("/api/data")
    public ResponseEntity<String> getData() {
        Timer.Sample sample = Timer.start(meterRegistry);
        requestCounter.increment();
        
        try {
            // 业务逻辑
            String result = "Data";
            return ResponseEntity.ok(result);
        } finally {
            sample.stop(requestTimer);
        }
    }
}
```

## 应用信息暴露

### 应用信息配置
```yaml
# application.yml
info:
  app:
    name: "My Application"
    version: "1.0.0"
    description: "A Spring Boot application"
  build:
    artifact: "my-app"
    name: "my-app"
    version: "1.0.0"
  java:
    version: "11"
  os:
    name: "Linux"
    version: "5.4.0"
```

### 自定义信息端点
```java
@Component
public class CustomInfoContributor implements InfoContributor {
    
    @Override
    public void contribute(Info.Builder builder) {
        builder.withDetail("custom.info", "Custom application information")
               .withDetail("timestamp", System.currentTimeMillis())
               .withDetail("environment", System.getProperty("spring.profiles.active", "default"));
    }
}
```

## 监控数据可视化

### Prometheus集成
```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

### Grafana仪表板
```json
{
  "dashboard": {
    "title": "Spring Boot Application",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(app_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(app_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
```

## 性能监控

### 方法性能监控
```java
@Component
public class PerformanceMonitor {
    
    private final MeterRegistry meterRegistry;
    
    public PerformanceMonitor(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }
    
    @Timed(value = "app.method.execution", description = "Method execution time")
    @Counted(value = "app.method.calls", description = "Method call count")
    public String performOperation() {
        // 业务逻辑
        return "Operation completed";
    }
}
```

### 数据库性能监控
```java
@Component
public class DatabaseMetrics {
    
    private final MeterRegistry meterRegistry;
    private final DataSource dataSource;
    
    public DatabaseMetrics(MeterRegistry meterRegistry, DataSource dataSource) {
        this.meterRegistry = meterRegistry;
        this.dataSource = dataSource;
        
        // 监控连接池
        if (dataSource instanceof HikariDataSource) {
            HikariDataSource hikariDataSource = (HikariDataSource) dataSource;
            Gauge.builder("app.db.connections.active", hikariDataSource, HikariDataSource::getHikariPoolMXBean)
                .description("Active database connections")
                .register(meterRegistry);
        }
    }
}
```

## 链路追踪

### Sleuth集成
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
```

### 自定义追踪
```java
@Component
public class CustomTracer {
    
    private final Tracer tracer;
    
    public CustomTracer(Tracer tracer) {
        this.tracer = tracer;
    }
    
    public void traceOperation(String operationName) {
        Span span = tracer.nextSpan().name(operationName);
        try (Tracer.SpanInScope ws = tracer.withSpanInScope(span.start())) {
            // 业务逻辑
            span.tag("operation.type", "custom");
            span.tag("operation.status", "success");
        } finally {
            span.finish();
        }
    }
}
```

## 告警配置

### 告警规则
```yaml
# prometheus-alerts.yml
groups:
  - name: spring-boot-alerts
    rules:
      - alert: HighRequestRate
        expr: rate(app_requests_total[5m]) > 100
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High request rate detected"
          description: "Request rate is {{ $value }} requests per second"
      
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(app_request_duration_seconds_bucket[5m])) > 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }} seconds"
```

## Spring Boot监控关联的其它知识

### 1. Spring Boot核心
- [Spring Boot自动配置](0701-Spring%20Boot自动配置.md)
- [Spring Boot启动原理](0702-Spring%20Boot启动原理.md)
- [Spring Boot配置管理](0703-Spring%20Boot配置管理.md)

### 2. 监控技术
- [Prometheus监控](../../300-中间件/prometheus.md)
- [Grafana可视化](../../300-中间件/grafana.md)
- [ELK日志分析](../../300-中间件/elk.md)

### 3. 性能优化
- [Java性能调优](../../100-java/100-Java基础/性能优化/性能调优.md)
- [JVM监控](../old/100-Java基础-old/JVM/0-JVM.md)

### 4. 微服务监控
- [Spring Cloud监控](../0301-Spring%20Cloud基础.md)
- [分布式链路追踪](../0302-分布式链路追踪.md)

### 5. 相关技术
- [HTTP协议](../../500-基础理论/通用计算机知识/一篇搞懂TCP、HTTP、Socket、Socket连接池.md)
- [JSON数据格式](../../200-python/00-python语法/python基础/02-python3%20基本数据类型.md)
- [RESTful API设计](../0201-Spring%20MVC基础.md) 