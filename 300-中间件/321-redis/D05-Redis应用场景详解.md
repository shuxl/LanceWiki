# Redis应用场景详解

## 本文重点

1. **缓存应用场景**：掌握Redis作为缓存的典型应用场景和实现方案
2. **分布式锁实现**：了解基于Redis的分布式锁设计和实现原理
3. **计数器与排行榜**：掌握Redis在计数器和排行榜场景中的应用
4. **限流与熔断**：了解基于Redis的限流和熔断机制实现
5. **消息队列应用**：掌握Redis Stream在消息队列场景中的使用
6. **会话存储方案**：了解Redis在会话管理中的应用

## Redis应用场景概念与介绍

### Redis应用场景概述

Redis作为高性能的内存数据库，在众多应用场景中发挥着重要作用：

- **缓存系统**：提升系统性能，减少数据库压力
- **分布式锁**：解决分布式环境下的并发控制问题
- **计数器系统**：实现高并发的计数和统计功能
- **排行榜系统**：支持实时排序和排名功能
- **限流系统**：控制请求频率，保护系统稳定性
- **消息队列**：实现异步消息处理
- **会话存储**：管理用户会话状态

### 应用场景选择原则

**选择Redis应用场景的考虑因素：**

1. **性能要求**：需要高性能、低延迟的场景
2. **数据特性**：临时数据、缓存数据、会话数据
3. **并发需求**：高并发读写场景
4. **一致性要求**：对数据一致性要求不严格的场景
5. **容量限制**：数据量相对较小的场景

## Redis缓存应用场景

### 1. 数据库查询缓存

#### 1.1 查询结果缓存

**设计思想：**
将数据库查询结果缓存到Redis中，减少数据库访问次数，提升查询性能。

**实现方案：**
```java
@Service
public class UserService {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    @Autowired
    private UserMapper userMapper;
    
    public User getUserById(Long userId) {
        // 构建缓存键
        String cacheKey = "user:" + userId;
        
        // 尝试从缓存获取
        User user = (User) redisTemplate.opsForValue().get(cacheKey);
        if (user != null) {
            return user;
        }
        
        // 缓存未命中，从数据库查询
        user = userMapper.selectById(userId);
        if (user != null) {
            // 设置缓存，过期时间30分钟
            redisTemplate.opsForValue().set(cacheKey, user, Duration.ofMinutes(30));
        }
        
        return user;
    }
}
```

**缓存策略：**
- **缓存键设计**：`业务前缀:主键ID`
- **过期时间**：根据数据更新频率设置
- **缓存穿透防护**：缓存空值或使用布隆过滤器

#### 1.2 热点数据缓存

**设计思想：**
识别并缓存访问频率高的热点数据，提升系统整体性能。

**实现方案：**
```java
@Component
public class HotDataCache {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    // 热点数据缓存
    public void cacheHotData(String key, Object data) {
        // 热点数据设置较长过期时间
        redisTemplate.opsForValue().set(key, data, Duration.ofHours(2));
    }
    
    // 获取热点数据
    public Object getHotData(String key) {
        return redisTemplate.opsForValue().get(key);
    }
    
    // 热点数据预热
    public void preloadHotData() {
        // 系统启动时预加载热点数据
        List<String> hotKeys = getHotKeyList();
        for (String key : hotKeys) {
            Object data = loadDataFromDB(key);
            cacheHotData(key, data);
        }
    }
}
```

### 2. 页面缓存

#### 2.1 静态页面缓存

**设计思想：**
将动态生成的页面内容缓存到Redis中，减少页面渲染时间。

**实现方案：**
```java
@Controller
public class PageController {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @GetMapping("/product/{id}")
    public String getProductPage(@PathVariable Long id, Model model) {
        String cacheKey = "page:product:" + id;
        
        // 尝试从缓存获取页面内容
        String pageContent = redisTemplate.opsForValue().get(cacheKey);
        if (pageContent != null) {
            return pageContent;
        }
        
        // 生成页面内容
        Product product = productService.getProductById(id);
        model.addAttribute("product", product);
        
        // 渲染页面
        String content = renderPage("product", model);
        
        // 缓存页面内容
        redisTemplate.opsForValue().set(cacheKey, content, Duration.ofMinutes(10));
        
        return content;
    }
}
```

#### 2.2 接口响应缓存

**设计思想：**
缓存API接口的响应结果，减少重复计算和数据库查询。

**实现方案：**
```java
@RestController
public class ApiController {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @GetMapping("/api/products")
    public ResponseEntity<String> getProducts(@RequestParam Map<String, String> params) {
        // 构建缓存键
        String cacheKey = "api:products:" + params.hashCode();
        
        // 尝试从缓存获取
        String response = redisTemplate.opsForValue().get(cacheKey);
        if (response != null) {
            return ResponseEntity.ok(response);
        }
        
        // 执行业务逻辑
        List<Product> products = productService.getProducts(params);
        String jsonResponse = objectMapper.writeValueAsString(products);
        
        // 缓存响应
        redisTemplate.opsForValue().set(cacheKey, jsonResponse, Duration.ofMinutes(5));
        
        return ResponseEntity.ok(jsonResponse);
    }
}
```

## Redis分布式锁应用场景

### 1. 分布式锁设计原理

#### 1.1 基本要求

**分布式锁的核心要求：**
- **互斥性**：同一时间只能有一个客户端持有锁
- **防死锁**：锁必须能够自动释放
- **可重入性**：同一个客户端可以多次获取同一把锁
- **高性能**：获取和释放锁的操作要快速

#### 1.2 实现方案

**基于SET NX EX的实现：**
```java
@Component
public class RedisDistributedLock {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String LOCK_PREFIX = "lock:";
    private static final long DEFAULT_EXPIRE_TIME = 30000; // 30秒
    
    /**
     * 获取分布式锁
     */
    public boolean acquireLock(String lockKey, String requestId, long expireTime) {
        String key = LOCK_PREFIX + lockKey;
        String value = requestId;
        
        // 使用SET NX EX命令原子性设置锁
        Boolean result = redisTemplate.opsForValue()
            .setIfAbsent(key, value, Duration.ofMillis(expireTime));
        
        return Boolean.TRUE.equals(result);
    }
    
    /**
     * 释放分布式锁
     */
    public boolean releaseLock(String lockKey, String requestId) {
        String key = LOCK_PREFIX + lockKey;
        
        // 使用Lua脚本保证原子性
        String script = "if redis.call('get', KEYS[1]) == ARGV[1] then " +
                       "return redis.call('del', KEYS[1]) " +
                       "else return 0 end";
        
        Long result = redisTemplate.execute(
            new DefaultRedisScript<>(script, Long.class),
            Collections.singletonList(key),
            requestId
        );
        
        return Long.valueOf(1).equals(result);
    }
}
```

### 2. 分布式锁应用场景

#### 2.1 库存扣减

**业务场景：**
在高并发环境下，确保库存扣减的原子性和一致性。

**实现方案：**
```java
@Service
public class InventoryService {
    
    @Autowired
    private RedisDistributedLock distributedLock;
    
    @Autowired
    private InventoryMapper inventoryMapper;
    
    public boolean deductInventory(Long productId, int quantity) {
        String lockKey = "inventory:" + productId;
        String requestId = UUID.randomUUID().toString();
        
        try {
            // 获取分布式锁
            boolean locked = distributedLock.acquireLock(lockKey, requestId, 10000);
            if (!locked) {
                throw new RuntimeException("获取锁失败");
            }
            
            // 检查库存
            Inventory inventory = inventoryMapper.selectById(productId);
            if (inventory.getStock() < quantity) {
                return false;
            }
            
            // 扣减库存
            inventory.setStock(inventory.getStock() - quantity);
            inventoryMapper.updateById(inventory);
            
            return true;
            
        } finally {
            // 释放锁
            distributedLock.releaseLock(lockKey, requestId);
        }
    }
}
```

#### 2.2 秒杀系统

**业务场景：**
在秒杀活动中，确保商品不会被超卖。

**实现方案：**
```java
@Service
public class SeckillService {
    
    @Autowired
    private RedisDistributedLock distributedLock;
    
    @Autowired
    private ProductService productService;
    
    public boolean seckill(Long productId, Long userId) {
        String lockKey = "seckill:" + productId;
        String requestId = UUID.randomUUID().toString();
        
        try {
            // 获取分布式锁
            boolean locked = distributedLock.acquireLock(lockKey, requestId, 5000);
            if (!locked) {
                return false;
            }
            
            // 检查是否已购买
            if (hasUserPurchased(productId, userId)) {
                return false;
            }
            
            // 检查库存
            if (!productService.deductInventory(productId, 1)) {
                return false;
            }
            
            // 记录购买记录
            recordPurchase(productId, userId);
            
            return true;
            
        } finally {
            distributedLock.releaseLock(lockKey, requestId);
        }
    }
}
```

## Redis计数器应用场景

### 1. 访问量统计

#### 1.1 页面访问统计

**设计思想：**
使用Redis的INCR命令实现高并发的访问量统计。

**实现方案：**
```java
@Service
public class VisitStatisticsService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 记录页面访问
     */
    public void recordPageVisit(String pageId) {
        String key = "visit:page:" + pageId;
        
        // 增加访问计数
        redisTemplate.opsForValue().increment(key);
        
        // 设置过期时间（可选）
        redisTemplate.expire(key, Duration.ofDays(30));
    }
    
    /**
     * 获取页面访问量
     */
    public Long getPageVisitCount(String pageId) {
        String key = "visit:page:" + pageId;
        String count = redisTemplate.opsForValue().get(key);
        return count != null ? Long.parseLong(count) : 0L;
    }
    
    /**
     * 获取热门页面
     */
    public List<String> getHotPages(int limit) {
        Set<String> keys = redisTemplate.keys("visit:page:*");
        if (keys == null || keys.isEmpty()) {
            return Collections.emptyList();
        }
        
        // 获取所有页面的访问量
        List<Map.Entry<String, Long>> pageVisits = new ArrayList<>();
        for (String key : keys) {
            String pageId = key.replace("visit:page:", "");
            Long count = getPageVisitCount(pageId);
            pageVisits.add(new AbstractMap.SimpleEntry<>(pageId, count));
        }
        
        // 按访问量排序
        pageVisits.sort((a, b) -> b.getValue().compareTo(a.getValue()));
        
        // 返回前N个
        return pageVisits.stream()
            .limit(limit)
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
    }
}
```

#### 1.2 用户行为统计

**设计思想：**
统计用户的点击、点赞、评论等行为数据。

**实现方案：**
```java
@Service
public class UserBehaviorService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 记录用户行为
     */
    public void recordUserBehavior(Long userId, String behavior, String targetId) {
        String key = "behavior:" + userId + ":" + behavior;
        
        // 使用Set记录行为目标
        redisTemplate.opsForSet().add(key, targetId);
        
        // 设置过期时间
        redisTemplate.expire(key, Duration.ofDays(90));
    }
    
    /**
     * 获取用户行为统计
     */
    public Long getUserBehaviorCount(Long userId, String behavior) {
        String key = "behavior:" + userId + ":" + behavior;
        return redisTemplate.opsForSet().size(key);
    }
    
    /**
     * 检查用户是否执行过某行为
     */
    public boolean hasUserBehavior(Long userId, String behavior, String targetId) {
        String key = "behavior:" + userId + ":" + behavior;
        return Boolean.TRUE.equals(redisTemplate.opsForSet().isMember(key, targetId));
    }
}
```

### 2. 业务计数器

#### 2.1 订单计数器

**设计思想：**
统计订单数量、金额等业务指标。

**实现方案：**
```java
@Service
public class OrderCounterService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 增加订单计数
     */
    public void incrementOrderCount(String date) {
        String key = "order:count:" + date;
        redisTemplate.opsForValue().increment(key);
    }
    
    /**
     * 增加订单金额
     */
    public void incrementOrderAmount(String date, BigDecimal amount) {
        String key = "order:amount:" + date;
        redisTemplate.opsForValue().increment(key, amount.doubleValue());
    }
    
    /**
     * 获取订单统计
     */
    public OrderStatistics getOrderStatistics(String date) {
        String countKey = "order:count:" + date;
        String amountKey = "order:amount:" + date;
        
        String countStr = redisTemplate.opsForValue().get(countKey);
        String amountStr = redisTemplate.opsForValue().get(amountKey);
        
        Long count = countStr != null ? Long.parseLong(countStr) : 0L;
        BigDecimal amount = amountStr != null ? new BigDecimal(amountStr) : BigDecimal.ZERO;
        
        return new OrderStatistics(count, amount);
    }
}
```

## Redis排行榜应用场景

### 1. 游戏排行榜

#### 1.1 分数排行榜

**设计思想：**
使用Redis的ZSet数据结构实现实时排行榜功能。

**实现方案：**
```java
@Service
public class GameRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 更新玩家分数
     */
    public void updatePlayerScore(String playerId, double score) {
        String key = "ranking:game";
        redisTemplate.opsForZSet().add(key, playerId, score);
    }
    
    /**
     * 获取玩家排名
     */
    public Long getPlayerRank(String playerId) {
        String key = "ranking:game";
        return redisTemplate.opsForZSet().reverseRank(key, playerId);
    }
    
    /**
     * 获取玩家分数
     */
    public Double getPlayerScore(String playerId) {
        String key = "ranking:game";
        return redisTemplate.opsForZSet().score(key, playerId);
    }
    
    /**
     * 获取排行榜前N名
     */
    public List<RankingPlayer> getTopPlayers(int limit) {
        String key = "ranking:game";
        Set<ZSetOperations.TypedTuple<String>> topPlayers = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<RankingPlayer> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> player : topPlayers) {
            result.add(new RankingPlayer(player.getValue(), player.getScore(), rank++));
        }
        
        return result;
    }
    
    /**
     * 获取玩家周围的排名
     */
    public List<RankingPlayer> getPlayerSurroundings(String playerId, int range) {
        String key = "ranking:game";
        Long playerRank = getPlayerRank(playerId);
        if (playerRank == null) {
            return Collections.emptyList();
        }
        
        long start = Math.max(0, playerRank - range);
        long end = playerRank + range;
        
        Set<ZSetOperations.TypedTuple<String>> players = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, start, end);
        
        List<RankingPlayer> result = new ArrayList<>();
        long rank = start + 1;
        for (ZSetOperations.TypedTuple<String> player : players) {
            result.add(new RankingPlayer(player.getValue(), player.getScore(), rank++));
        }
        
        return result;
    }
}
```

#### 1.2 多维度排行榜

**设计思想：**
支持按不同维度（时间、地区、等级等）进行排名。

**实现方案：**
```java
@Service
public class MultiDimensionRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 更新多维度分数
     */
    public void updateMultiDimensionScore(String playerId, double score, String dimension) {
        String key = "ranking:" + dimension;
        redisTemplate.opsForZSet().add(key, playerId, score);
    }
    
    /**
     * 获取指定维度的排行榜
     */
    public List<RankingPlayer> getDimensionRanking(String dimension, int limit) {
        String key = "ranking:" + dimension;
        Set<ZSetOperations.TypedTuple<String>> topPlayers = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<RankingPlayer> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> player : topPlayers) {
            result.add(new RankingPlayer(player.getValue(), player.getScore(), rank++));
        }
        
        return result;
    }
    
    /**
     * 获取玩家在所有维度的排名
     */
    public Map<String, Long> getPlayerAllDimensionsRank(String playerId) {
        Map<String, Long> rankings = new HashMap<>();
        
        // 获取所有维度
        Set<String> dimensions = redisTemplate.keys("ranking:*");
        if (dimensions != null) {
            for (String key : dimensions) {
                String dimension = key.replace("ranking:", "");
                Long rank = redisTemplate.opsForZSet().reverseRank(key, playerId);
                if (rank != null) {
                    rankings.put(dimension, rank);
                }
            }
        }
        
        return rankings;
    }
}
```

### 2. 商品排行榜

#### 2.1 销量排行榜

**设计思想：**
基于商品销量数据生成实时排行榜。

**实现方案：**
```java
@Service
public class ProductRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 增加商品销量
     */
    public void incrementProductSales(String productId, int quantity) {
        String key = "ranking:sales";
        redisTemplate.opsForZSet().incrementScore(key, productId, quantity);
    }
    
    /**
     * 获取销量排行榜
     */
    public List<ProductRanking> getSalesRanking(int limit) {
        String key = "ranking:sales";
        Set<ZSetOperations.TypedTuple<String>> topProducts = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<ProductRanking> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> product : topProducts) {
            result.add(new ProductRanking(product.getValue(), product.getScore().intValue(), rank++));
        }
        
        return result;
    }
    
    /**
     * 获取商品销量排名
     */
    public Long getProductSalesRank(String productId) {
        String key = "ranking:sales";
        return redisTemplate.opsForZSet().reverseRank(key, productId);
    }
}
```

## Redis限流应用场景

### 1. 接口限流

#### 1.1 固定窗口限流

**设计思想：**
在固定的时间窗口内限制请求次数。

**实现方案：**
```java
@Component
public class FixedWindowRateLimiter {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 固定窗口限流
     */
    public boolean isAllowed(String key, int limit, int windowSeconds) {
        String redisKey = "rate_limit:" + key;
        
        // 获取当前计数
        String countStr = redisTemplate.opsForValue().get(redisKey);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;
        
        if (count >= limit) {
            return false;
        }
        
        // 增加计数
        redisTemplate.opsForValue().increment(redisKey);
        
        // 设置过期时间
        if (count == 0) {
            redisTemplate.expire(redisKey, Duration.ofSeconds(windowSeconds));
        }
        
        return true;
    }
}
```

#### 1.2 滑动窗口限流

**设计思想：**
使用滑动窗口算法实现更精确的限流控制。

**实现方案：**
```java
@Component
public class SlidingWindowRateLimiter {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 滑动窗口限流
     */
    public boolean isAllowed(String key, int limit, int windowSeconds) {
        String redisKey = "sliding_rate_limit:" + key;
        long now = System.currentTimeMillis();
        long windowStart = now - (windowSeconds * 1000);
        
        // 移除窗口外的请求记录
        redisTemplate.opsForZSet().removeRangeByScore(redisKey, 0, windowStart);
        
        // 获取当前窗口内的请求数
        Long count = redisTemplate.opsForZSet().zCard(redisKey);
        
        if (count != null && count >= limit) {
            return false;
        }
        
        // 添加当前请求
        redisTemplate.opsForZSet().add(redisKey, String.valueOf(now), now);
        
        // 设置过期时间
        redisTemplate.expire(redisKey, Duration.ofSeconds(windowSeconds));
        
        return true;
    }
}
```

#### 1.3 令牌桶限流

**设计思想：**
使用令牌桶算法实现平滑的限流控制。

**实现方案：**
```java
@Component
public class TokenBucketRateLimiter {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 令牌桶限流
     */
    public boolean isAllowed(String key, int capacity, int rate, int tokens) {
        String redisKey = "token_bucket:" + key;
        long now = System.currentTimeMillis();
        
        // 获取当前令牌数和上次更新时间
        String bucketInfo = redisTemplate.opsForValue().get(redisKey);
        double currentTokens = capacity;
        long lastRefillTime = now;
        
        if (bucketInfo != null) {
            String[] parts = bucketInfo.split(":");
            currentTokens = Double.parseDouble(parts[0]);
            lastRefillTime = Long.parseLong(parts[1]);
        }
        
        // 计算需要补充的令牌数
        long timePassed = now - lastRefillTime;
        double tokensToAdd = (timePassed / 1000.0) * rate;
        currentTokens = Math.min(capacity, currentTokens + tokensToAdd);
        
        // 检查是否有足够的令牌
        if (currentTokens < tokens) {
            return false;
        }
        
        // 消耗令牌
        currentTokens -= tokens;
        
        // 更新令牌桶状态
        String newBucketInfo = currentTokens + ":" + now;
        redisTemplate.opsForValue().set(redisKey, newBucketInfo);
        
        return true;
    }
}
```

### 2. 用户限流

#### 2.1 用户行为限流

**设计思想：**
限制用户的特定行为频率，如发帖、评论等。

**实现方案：**
```java
@Service
public class UserRateLimitService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 检查用户行为限流
     */
    public boolean checkUserActionLimit(Long userId, String action, int limit, int windowSeconds) {
        String key = "user_limit:" + userId + ":" + action;
        
        // 获取当前计数
        String countStr = redisTemplate.opsForValue().get(key);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;
        
        if (count >= limit) {
            return false;
        }
        
        // 增加计数
        redisTemplate.opsForValue().increment(key);
        
        // 设置过期时间
        if (count == 0) {
            redisTemplate.expire(key, Duration.ofSeconds(windowSeconds));
        }
        
        return true;
    }
    
    /**
     * 获取用户剩余次数
     */
    public int getRemainingCount(Long userId, String action) {
        String key = "user_limit:" + userId + ":" + action;
        String countStr = redisTemplate.opsForValue().get(key);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;
        
        // 这里需要根据具体的限流策略计算剩余次数
        return Math.max(0, 10 - count); // 假设限制为10次
    }
}
```

## Redis消息队列应用场景

### 1. 基于Stream的消息队列

#### 1.1 简单消息队列

**设计思想：**
使用Redis Stream实现简单的消息队列功能。

**实现方案：**
```java
@Service
public class StreamMessageQueue {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String STREAM_KEY = "message_queue";
    
    /**
     * 发送消息
     */
    public String sendMessage(Map<String, String> message) {
        return redisTemplate.opsForStream().add(STREAM_KEY, message);
    }
    
    /**
     * 消费消息
     */
    public List<MapRecord<String, String, String>> consumeMessages(String consumerGroup, String consumer, int count) {
        // 创建消费者组（如果不存在）
        try {
            redisTemplate.opsForStream().createGroup(STREAM_KEY, consumerGroup);
        } catch (Exception e) {
            // 消费者组已存在
        }
        
        // 读取消息
        return redisTemplate.opsForStream().readGroup(consumerGroup, consumer, 
            StreamReadOptions.empty().count(count), 
            StreamOffset.create(STREAM_KEY, ReadOffset.from(">")));
    }
    
    /**
     * 确认消息
     */
    public Long acknowledgeMessage(String consumerGroup, String... messageIds) {
        return redisTemplate.opsForStream().acknowledge(consumerGroup, STREAM_KEY, messageIds);
    }
    
    /**
     * 获取待处理消息
     */
    public PendingMessages pendingMessages(String consumerGroup) {
        return redisTemplate.opsForStream().pending(STREAM_KEY, consumerGroup);
    }
}
```

#### 1.2 延迟消息队列

**设计思想：**
实现延迟消息处理功能。

**实现方案：**
```java
@Service
public class DelayMessageQueue {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String DELAY_QUEUE_KEY = "delay_queue";
    
    /**
     * 发送延迟消息
     */
    public void sendDelayMessage(String message, long delaySeconds) {
        long executeTime = System.currentTimeMillis() + (delaySeconds * 1000);
        redisTemplate.opsForZSet().add(DELAY_QUEUE_KEY, message, executeTime);
    }
    
    /**
     * 处理延迟消息
     */
    public List<String> processDelayMessages() {
        long now = System.currentTimeMillis();
        
        // 获取到期的消息
        Set<String> messages = redisTemplate.opsForZSet()
            .rangeByScore(DELAY_QUEUE_KEY, 0, now);
        
        if (messages != null && !messages.isEmpty()) {
            // 移除已处理的消息
            redisTemplate.opsForZSet().removeRangeByScore(DELAY_QUEUE_KEY, 0, now);
            
            return new ArrayList<>(messages);
        }
        
        return Collections.emptyList();
    }
    
    /**
     * 启动延迟消息处理器
     */
    @Scheduled(fixedRate = 1000) // 每秒检查一次
    public void processDelayMessagesScheduled() {
        List<String> messages = processDelayMessages();
        for (String message : messages) {
            // 处理消息
            processMessage(message);
        }
    }
    
    private void processMessage(String message) {
        // 具体的消息处理逻辑
        System.out.println("Processing delay message: " + message);
    }
}
```

### 2. 发布订阅模式

#### 2.1 事件通知

**设计思想：**
使用Redis的发布订阅功能实现事件通知。

**实现方案：**
```java
@Component
public class EventPublisher {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 发布事件
     */
    public void publishEvent(String channel, String message) {
        redisTemplate.convertAndSend(channel, message);
    }
}

@Component
public class EventSubscriber implements MessageListener {
    
    @Override
    public void onMessage(Message message, byte[] pattern) {
        String channel = new String(message.getChannel());
        String body = new String(message.getBody());
        
        // 处理不同类型的消息
        switch (channel) {
            case "user:register":
                handleUserRegister(body);
                break;
            case "order:created":
                handleOrderCreated(body);
                break;
            case "product:updated":
                handleProductUpdated(body);
                break;
        }
    }
    
    private void handleUserRegister(String message) {
        // 处理用户注册事件
        System.out.println("User registered: " + message);
    }
    
    private void handleOrderCreated(String message) {
        // 处理订单创建事件
        System.out.println("Order created: " + message);
    }
    
    private void handleProductUpdated(String message) {
        // 处理商品更新事件
        System.out.println("Product updated: " + message);
    }
}
```

## Redis会话存储应用场景

### 1. 用户会话管理

#### 1.1 会话存储

**设计思想：**
使用Redis存储用户会话信息，支持分布式环境下的会话管理。

**实现方案：**
```java
@Service
public class SessionService {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String SESSION_PREFIX = "session:";
    private static final int SESSION_TIMEOUT = 1800; // 30分钟
    
    /**
     * 创建会话
     */
    public String createSession(Long userId, Map<String, Object> sessionData) {
        String sessionId = UUID.randomUUID().toString();
        String key = SESSION_PREFIX + sessionId;
        
        // 存储会话数据
        sessionData.put("userId", userId);
        sessionData.put("createTime", System.currentTimeMillis());
        sessionData.put("lastAccessTime", System.currentTimeMillis());
        
        redisTemplate.opsForHash().putAll(key, sessionData);
        redisTemplate.expire(key, Duration.ofSeconds(SESSION_TIMEOUT));
        
        return sessionId;
    }
    
    /**
     * 获取会话数据
     */
    public Map<Object, Object> getSession(String sessionId) {
        String key = SESSION_PREFIX + sessionId;
        
        // 更新最后访问时间
        redisTemplate.opsForHash().put(key, "lastAccessTime", System.currentTimeMillis());
        redisTemplate.expire(key, Duration.ofSeconds(SESSION_TIMEOUT));
        
        return redisTemplate.opsForHash().entries(key);
    }
    
    /**
     * 更新会话数据
     */
    public void updateSession(String sessionId, String field, Object value) {
        String key = SESSION_PREFIX + sessionId;
        redisTemplate.opsForHash().put(key, field, value);
        redisTemplate.expire(key, Duration.ofSeconds(SESSION_TIMEOUT));
    }
    
    /**
     * 删除会话
     */
    public void deleteSession(String sessionId) {
        String key = SESSION_PREFIX + sessionId;
        redisTemplate.delete(key);
    }
    
    /**
     * 检查会话是否存在
     */
    public boolean sessionExists(String sessionId) {
        String key = SESSION_PREFIX + sessionId;
        return Boolean.TRUE.equals(redisTemplate.hasKey(key));
    }
}
```

#### 1.2 在线用户统计

**设计思想：**
统计当前在线用户数量和活跃用户信息。

**实现方案：**
```java
@Service
public class OnlineUserService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String ONLINE_USERS_KEY = "online_users";
    private static final String USER_SESSIONS_KEY = "user_sessions:";
    
    /**
     * 用户上线
     */
    public void userOnline(Long userId, String sessionId) {
        long now = System.currentTimeMillis();
        
        // 添加到在线用户集合
        redisTemplate.opsForZSet().add(ONLINE_USERS_KEY, userId.toString(), now);
        
        // 记录用户会话
        String userSessionsKey = USER_SESSIONS_KEY + userId;
        redisTemplate.opsForSet().add(userSessionsKey, sessionId);
        
        // 设置过期时间
        redisTemplate.expire(ONLINE_USERS_KEY, Duration.ofMinutes(30));
        redisTemplate.expire(userSessionsKey, Duration.ofMinutes(30));
    }
    
    /**
     * 用户下线
     */
    public void userOffline(Long userId, String sessionId) {
        // 移除用户会话
        String userSessionsKey = USER_SESSIONS_KEY + userId;
        redisTemplate.opsForSet().remove(userSessionsKey, sessionId);
        
        // 如果没有其他会话，则从在线用户中移除
        Long sessionCount = redisTemplate.opsForSet().size(userSessionsKey);
        if (sessionCount == null || sessionCount == 0) {
            redisTemplate.opsForZSet().remove(ONLINE_USERS_KEY, userId.toString());
            redisTemplate.delete(userSessionsKey);
        }
    }
    
    /**
     * 获取在线用户数量
     */
    public Long getOnlineUserCount() {
        return redisTemplate.opsForZSet().zCard(ONLINE_USERS_KEY);
    }
    
    /**
     * 获取在线用户列表
     */
    public Set<String> getOnlineUsers() {
        return redisTemplate.opsForZSet().range(ONLINE_USERS_KEY, 0, -1);
    }
    
    /**
     * 获取用户会话数量
     */
    public Long getUserSessionCount(Long userId) {
        String userSessionsKey = USER_SESSIONS_KEY + userId;
        return redisTemplate.opsForSet().size(userSessionsKey);
    }
}
```

## Redis排行榜应用场景

### 1. 游戏排行榜

#### 1.1 分数排行榜

**设计思想：**
使用Redis的ZSet数据结构实现实时排行榜功能。

**实现方案：**
```java
@Service
public class GameRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 更新玩家分数
     */
    public void updatePlayerScore(String playerId, double score) {
        String key = "ranking:game";
        redisTemplate.opsForZSet().add(key, playerId, score);
    }
    
    /**
     * 获取玩家排名
     */
    public Long getPlayerRank(String playerId) {
        String key = "ranking:game";
        return redisTemplate.opsForZSet().reverseRank(key, playerId);
    }
    
    /**
     * 获取玩家分数
     */
    public Double getPlayerScore(String playerId) {
        String key = "ranking:game";
        return redisTemplate.opsForZSet().score(key, playerId);
    }
    
    /**
     * 获取排行榜前N名
     */
    public List<RankingPlayer> getTopPlayers(int limit) {
        String key = "ranking:game";
        Set<ZSetOperations.TypedTuple<String>> topPlayers = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<RankingPlayer> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> player : topPlayers) {
            result.add(new RankingPlayer(player.getValue(), player.getScore(), rank++));
        }
        
        return result;
    }
}
```

#### 1.2 多维度排行榜

**设计思想：**
支持按不同维度（时间、地区、等级等）进行排名。

**实现方案：**
```java
@Service
public class MultiDimensionRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 更新多维度分数
     */
    public void updateMultiDimensionScore(String playerId, double score, String dimension) {
        String key = "ranking:" + dimension;
        redisTemplate.opsForZSet().add(key, playerId, score);
    }
    
    /**
     * 获取指定维度的排行榜
     */
    public List<RankingPlayer> getDimensionRanking(String dimension, int limit) {
        String key = "ranking:" + dimension;
        Set<ZSetOperations.TypedTuple<String>> topPlayers = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<RankingPlayer> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> player : topPlayers) {
            result.add(new RankingPlayer(player.getValue(), player.getScore(), rank++));
        }
        
        return result;
    }
}
```

### 2. 商品排行榜

#### 2.1 销量排行榜

**设计思想：**
基于商品销量数据生成实时排行榜。

**实现方案：**
```java
@Service
public class ProductRankingService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 增加商品销量
     */
    public void incrementProductSales(String productId, int quantity) {
        String key = "ranking:sales";
        redisTemplate.opsForZSet().incrementScore(key, productId, quantity);
    }
    
    /**
     * 获取销量排行榜
     */
    public List<ProductRanking> getSalesRanking(int limit) {
        String key = "ranking:sales";
        Set<ZSetOperations.TypedTuple<String>> topProducts = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
        
        List<ProductRanking> result = new ArrayList<>();
        long rank = 1;
        for (ZSetOperations.TypedTuple<String> product : topProducts) {
            result.add(new ProductRanking(product.getValue(), product.getScore().intValue(), rank++));
        }
        
        return result;
    }
}
```

## Redis限流应用场景

### 1. 接口限流

#### 1.1 固定窗口限流

**设计思想：**
在固定的时间窗口内限制请求次数。

**实现方案：**
```java
@Component
public class FixedWindowRateLimiter {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 固定窗口限流
     */
    public boolean isAllowed(String key, int limit, int windowSeconds) {
        String redisKey = "rate_limit:" + key;
        
        // 获取当前计数
        String countStr = redisTemplate.opsForValue().get(redisKey);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;
        
        if (count >= limit) {
            return false;
        }
        
        // 增加计数
        redisTemplate.opsForValue().increment(redisKey);
        
        // 设置过期时间
        if (count == 0) {
            redisTemplate.expire(redisKey, Duration.ofSeconds(windowSeconds));
        }
        
        return true;
    }
}
```

#### 1.2 滑动窗口限流

**设计思想：**
使用滑动窗口算法实现更精确的限流控制。

**实现方案：**
```java
@Component
public class SlidingWindowRateLimiter {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 滑动窗口限流
     */
    public boolean isAllowed(String key, int limit, int windowSeconds) {
        String redisKey = "sliding_rate_limit:" + key;
        long now = System.currentTimeMillis();
        long windowStart = now - (windowSeconds * 1000);
        
        // 移除窗口外的请求记录
        redisTemplate.opsForZSet().removeRangeByScore(redisKey, 0, windowStart);
        
        // 获取当前窗口内的请求数
        Long count = redisTemplate.opsForZSet().zCard(redisKey);
        
        if (count != null && count >= limit) {
            return false;
        }
        
        // 添加当前请求
        redisTemplate.opsForZSet().add(redisKey, String.valueOf(now), now);
        
        // 设置过期时间
        redisTemplate.expire(redisKey, Duration.ofSeconds(windowSeconds));
        
        return true;
    }
}
```

### 2. 用户限流

#### 2.1 用户行为限流

**设计思想：**
限制用户的特定行为频率，如发帖、评论等。

**实现方案：**
```java
@Service
public class UserRateLimitService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 检查用户行为限流
     */
    public boolean checkUserActionLimit(Long userId, String action, int limit, int windowSeconds) {
        String key = "user_limit:" + userId + ":" + action;
        
        // 获取当前计数
        String countStr = redisTemplate.opsForValue().get(key);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;
        
        if (count >= limit) {
            return false;
        }
        
        // 增加计数
        redisTemplate.opsForValue().increment(key);
        
        // 设置过期时间
        if (count == 0) {
            redisTemplate.expire(key, Duration.ofSeconds(windowSeconds));
        }
        
        return true;
    }
}
```

## Redis消息队列应用场景

### 1. 基于Stream的消息队列

#### 1.1 简单消息队列

**设计思想：**
使用Redis Stream实现简单的消息队列功能。

**实现方案：**
```java
@Service
public class StreamMessageQueue {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String STREAM_KEY = "message_queue";
    
    /**
     * 发送消息
     */
    public String sendMessage(Map<String, String> message) {
        return redisTemplate.opsForStream().add(STREAM_KEY, message);
    }
    
    /**
     * 消费消息
     */
    public List<MapRecord<String, String, String>> consumeMessages(String consumerGroup, String consumer, int count) {
        // 创建消费者组（如果不存在）
        try {
            redisTemplate.opsForStream().createGroup(STREAM_KEY, consumerGroup);
        } catch (Exception e) {
            // 消费者组已存在
        }
        
        // 读取消息
        return redisTemplate.opsForStream().readGroup(consumerGroup, consumer, 
            StreamReadOptions.empty().count(count), 
            StreamOffset.create(STREAM_KEY, ReadOffset.from(">")));
    }
}
```

#### 1.2 延迟消息队列

**设计思想：**
实现延迟消息处理功能。

**实现方案：**
```java
@Service
public class DelayMessageQueue {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String DELAY_QUEUE_KEY = "delay_queue";
    
    /**
     * 发送延迟消息
     */
    public void sendDelayMessage(String message, long delaySeconds) {
        long executeTime = System.currentTimeMillis() + (delaySeconds * 1000);
        redisTemplate.opsForZSet().add(DELAY_QUEUE_KEY, message, executeTime);
    }
    
    /**
     * 处理延迟消息
     */
    public List<String> processDelayMessages() {
        long now = System.currentTimeMillis();
        
        // 获取到期的消息
        Set<String> messages = redisTemplate.opsForZSet()
            .rangeByScore(DELAY_QUEUE_KEY, 0, now);
        
        if (messages != null && !messages.isEmpty()) {
            // 移除已处理的消息
            redisTemplate.opsForZSet().removeRangeByScore(DELAY_QUEUE_KEY, 0, now);
            
            return new ArrayList<>(messages);
        }
        
        return Collections.emptyList();
    }
}
```

### 2. 发布订阅模式

#### 2.1 事件通知

**设计思想：**
使用Redis的发布订阅功能实现事件通知。

**实现方案：**
```java
@Component
public class EventPublisher {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    /**
     * 发布事件
     */
    public void publishEvent(String channel, String message) {
        redisTemplate.convertAndSend(channel, message);
    }
}

@Component
public class EventSubscriber implements MessageListener {
    
    @Override
    public void onMessage(Message message, byte[] pattern) {
        String channel = new String(message.getChannel());
        String body = new String(message.getBody());
        
        // 处理不同类型的消息
        switch (channel) {
            case "user:register":
                handleUserRegister(body);
                break;
            case "order:created":
                handleOrderCreated(body);
                break;
        }
    }
    
    private void handleUserRegister(String message) {
        // 处理用户注册事件
        System.out.println("User registered: " + message);
    }
    
    private void handleOrderCreated(String message) {
        // 处理订单创建事件
        System.out.println("Order created: " + message);
    }
}
```

## Redis会话存储应用场景

### 1. 用户会话管理

#### 1.1 会话存储

**设计思想：**
使用Redis存储用户会话信息，支持分布式环境下的会话管理。

**实现方案：**
```java
@Service
public class SessionService {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String SESSION_PREFIX = "session:";
    private static final int SESSION_TIMEOUT = 1800; // 30分钟
    
    /**
     * 创建会话
     */
    public String createSession(Long userId, Map<String, Object> sessionData) {
        String sessionId = UUID.randomUUID().toString();
        String key = SESSION_PREFIX + sessionId;
        
        // 存储会话数据
        sessionData.put("userId", userId);
        sessionData.put("createTime", System.currentTimeMillis());
        sessionData.put("lastAccessTime", System.currentTimeMillis());
        
        redisTemplate.opsForHash().putAll(key, sessionData);
        redisTemplate.expire(key, Duration.ofSeconds(SESSION_TIMEOUT));
        
        return sessionId;
    }
    
    /**
     * 获取会话数据
     */
    public Map<Object, Object> getSession(String sessionId) {
        String key = SESSION_PREFIX + sessionId;
        
        // 更新最后访问时间
        redisTemplate.opsForHash().put(key, "lastAccessTime", System.currentTimeMillis());
        redisTemplate.expire(key, Duration.ofSeconds(SESSION_TIMEOUT));
        
        return redisTemplate.opsForHash().entries(key);
    }
    
    /**
     * 删除会话
     */
    public void deleteSession(String sessionId) {
        String key = SESSION_PREFIX + sessionId;
        redisTemplate.delete(key);
    }
}
```

#### 1.2 在线用户统计

**设计思想：**
统计当前在线用户数量和活跃用户信息。

**实现方案：**
```java
@Service
public class OnlineUserService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String ONLINE_USERS_KEY = "online_users";
    private static final String USER_SESSIONS_KEY = "user_sessions:";
    
    /**
     * 用户上线
     */
    public void userOnline(Long userId, String sessionId) {
        long now = System.currentTimeMillis();
        
        // 添加到在线用户集合
        redisTemplate.opsForZSet().add(ONLINE_USERS_KEY, userId.toString(), now);
        
        // 记录用户会话
        String userSessionsKey = USER_SESSIONS_KEY + userId;
        redisTemplate.opsForSet().add(userSessionsKey, sessionId);
        
        // 设置过期时间
        redisTemplate.expire(ONLINE_USERS_KEY, Duration.ofMinutes(30));
        redisTemplate.expire(userSessionsKey, Duration.ofMinutes(30));
    }
    
    /**
     * 获取在线用户数量
     */
    public Long getOnlineUserCount() {
        return redisTemplate.opsForZSet().zCard(ONLINE_USERS_KEY);
    }
    
    /**
     * 获取在线用户列表
     */
    public Set<String> getOnlineUsers() {
        return redisTemplate.opsForZSet().range(ONLINE_USERS_KEY, 0, -1);
    }
}
```

## Redis应用场景关联的其它知识

### 1. 缓存技术

- **[缓存架构设计](../500-基础理论/缓存架构设计.md)**：缓存系统的设计原则和架构模式
- **[缓存一致性](../500-基础理论/缓存一致性.md)**：缓存与数据库的一致性保证
- **[缓存穿透、击穿、雪崩](../D01-Redis缓存问题详解.md)**：缓存使用中的常见问题

### 2. 分布式系统

- **[分布式锁理论](../500-基础理论/分布式锁理论.md)**：分布式锁的设计原理和实现方式
- **[分布式事务](../500-基础理论/分布式事务.md)**：分布式环境下的事务处理
- **[一致性协议](../500-基础理论/一致性协议.md)**：分布式系统的一致性保证

### 3. 消息队列技术

- **[Kafka应用场景](../340-kafka/kafka应用场景.md)**：Kafka在不同场景中的应用
- **[RabbitMQ应用场景](../350-rabbitMQ/rabbitmq应用场景.md)**：RabbitMQ的应用实践
- **[消息队列架构](../500-基础理论/消息队列架构设计.md)**：消息队列系统的架构设计

### 4. 高并发系统

- **[高并发系统设计](../500-基础理论/高并发系统设计.md)**：高并发系统的设计原则
- **[限流熔断机制](../500-基础理论/限流熔断机制.md)**：系统保护机制的设计
- **[性能优化策略](../500-基础理论/性能优化策略.md)**：系统性能优化方法

### 5. 会话管理

- **[会话管理机制](../500-基础理论/会话管理机制.md)**：Web应用中的会话管理
- **[单点登录SSO](../500-基础理论/单点登录SSO.md)**：单点登录系统的实现
- **[身份认证授权](../500-基础理论/身份认证授权.md)**：用户身份认证和授权机制 