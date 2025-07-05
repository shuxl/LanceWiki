+ 基础数据结构
	+ String
		+ 可以存储 *任何数据。如数字，字符串，jpg图片或者序列化的对象*。
		+ 命令可以支持数字的加减法（+1，-1，+/-一个整数）
	+ List列表
		+ list是双向的，左右都可以push/pop，以及获取制定范围的值，以及通过索引获取制定值
		+ 用户：消息队列
	+ Set集合
		+ 用途：标签、点赞、收藏
	+ Hash散列
		+ 存储对象，比如用户信息
	+ ZSet集合
		+ 有序集合和集合一样也是 string 类型元素的集合,且不允许重复的成员，*不同的是每个元素都会关联一个 double 类型的分数*。redis 正是通过分数来为集合中的成员进行从小到大的排序
+ 三种特殊数据类型。（**HyperLogLogs**（基数统计）， **Bitmaps** (位图) 和 **geospatial** （地理位置）），个人理解：添加了一些工具类属性的逻辑
	+ HyperLogLogs：（HLL）是一种**概率数据结构**，用于**估计唯一元素的基数**（即集合中不同元素的数量）
		+ 用在**唯一访客统计**、**实时分析**、**去重统计操作**
		+ ChatGpt回答更精彩
	+ BitMap：一种用于处理位级别操作的数据结构。基于这种数据结构，用户还可以在器上面做一些统计类的工作
		+ Bitmap 通常用于需要高效存储和处理大量布尔值的场景，比如用户在线状态、日活跃用户统计等
	+ **geospatial** （地理位置）
+ Stream类型：它借鉴了Kafka的设计，是一个新的强大的支持多播的可持久化的消息队列。
	+ [ ] 暂不整理，可能需要看看和其它消息队列的差异
# 1 Redis数据结构简介

> Redis基础文章非常多，关于基础数据结构类型，我推荐你先看下[官方网站内容](https://redis.io/topics/data-types)，然后再看下面的小结

首先对redis来说，所有的key（键）都是字符串。我们在谈基础数据结构时，讨论的是存储值的数据类型，主要包括常见的5种数据类型，分别是：String、List、Set、Zset、Hash。
![](img/Pasted%20image%2020240805150922.png)

|结构类型|结构存储的值|结构的读写能力|
|---|---|---|
|**String字符串**|可以是字符串、整数或浮点数|对整个字符串或字符串的一部分进行操作；对整数或浮点数进行自增或自减操作；|
|**List列表**|一个链表，链表上的每个节点都包含一个字符串|对链表的两端进行push和pop操作，读取单个或多个元素；根据值查找或删除元素；|
|**Set集合**|包含字符串的无序集合|字符串的集合，包含基础的方法有看是否存在添加、获取、删除；还包含计算交集、并集、差集等|
|**Hash散列**|包含键值对的无序散列表|包含方法有添加、获取、删除单个元素|
|**Zset有序集合**|和散列一样，用于存储键值对|字符串成员与浮点数分数之间的有序映射；元素的排列顺序由分数的大小决定；包含方法有添加、获取、删除单个元素以及根据分值范围或成员来获取元素|

# 2 基础数据结构详解

> 内容其实比较简单，我觉得理解的重点在于这个结构怎么用，能够用来做什么？所以我在梳理时，围绕**图例**，**命令**，**执行**和**场景**来阐述。@pdai

## 2.1 String字符串

> String是redis中最基本的数据类型，一个key对应一个value。

String类型是二进制安全的，意思是 redis 的 string 可以包含任何数据。如数字，字符串，jpg图片或者序列化的对象。

- **图例**

下图是一个String类型的实例，其中键为hello，值为world

![](img/Pasted%20image%2020240805151022.png)

- **命令使用**

| 命令     | 简述          | 使用                |
| ------ | ----------- | ----------------- |
| GET    | 获取存储在给定键中的值 | GET name          |
| SET    | 设置存储在给定键中的值 | SET name value    |
| DEL    | 删除存储在给定键中的值 | DEL name          |
| INCR   | 将键存储的值加1    | INCR key          |
| DECR   | 将键存储的值减1    | DECR key          |
| INCRBY | 将键存储的值加上整数  | INCRBY key amount |
| DECRBY | 将键存储的值减去整数  | DECRBY key amount |

- **命令执行**

``` 
127.0.0.1:6379> set hello world
OK
127.0.0.1:6379> get hello
"world"
127.0.0.1:6379> del hello
(integer) 1
127.0.0.1:6379> get hello
(nil)
127.0.0.1:6379> set counter 2
OK
127.0.0.1:6379> get counter
"2"
127.0.0.1:6379> incr counter
(integer) 3
127.0.0.1:6379> get counter
"3"
127.0.0.1:6379> incrby counter 100
(integer) 103
127.0.0.1:6379> get counter
"103"
127.0.0.1:6379> decr counter
(integer) 102
127.0.0.1:6379> get counter
"102"
```

- **实战场景**
    - **缓存**： 经典使用场景，把常用信息，字符串，图片或者视频等信息放到redis中，redis作为缓存层，mysql做持久化层，降低mysql的读写压力。
    - **计数器**：redis是单线程模型，一个命令执行完才会执行下一个，同时数据可以一步落地到其他的数据源。
    - **session**：常见方案spring session + redis实现session共享，

## 2.2 List列表

> Redis中的List其实就是链表（Redis用双端链表实现List）。

使用List结构，我们可以轻松地实现最新**消息排队功能**（比如新浪微博的TimeLine）。List的另一个应用就是消息队列，可以利用List的 PUSH 操作，将任务存放在List中，然后工作线程再用 POP 操作将任务取出进行执行。

- **图例**

![](img/Pasted%20image%2020240805151521.png)

- **命令使用**

| 命令     | 简述                                                              | 使用               |
| ------ | --------------------------------------------------------------- | ---------------- |
| RPUSH  | 将给定值推入到列表右端                                                     | RPUSH key value  |
| LPUSH  | 将给定值推入到列表左端                                                     | LPUSH key value  |
| RPOP   | 从列表的右端弹出一个值，并返回被弹出的值                                            | RPOP key         |
| LPOP   | 从列表的左端弹出一个值，并返回被弹出的值                                            | LPOP key         |
| LRANGE | 获取列表在给定范围上的所有值                                                  | LRANGE key 0 -1  |
| LINDEX | 通过索引获取列表中的元素。你也可以使用负数下标，以 -1 表示列表的最后一个元素， -2 表示列表的倒数第二个元素，以此类推。 | LINDEX key index |

- 使用列表的技巧
    - lpush+lpop=Stack(栈)
    - lpush+rpop=Queue（队列）
    - lpush+ltrim=Capped Collection（有限集合）
    - lpush+brpop=Message Queue（消息队列）
- **命令执行**
```
127.0.0.1:6379> lpush mylist 1 2 ll ls mem
(integer) 5
127.0.0.1:6379> lrange mylist 0 -1
1) "mem"
2) "ls"
3) "ll"
4) "2"
5) "1"
127.0.0.1:6379> lindex mylist -1
"1"
127.0.0.1:6379> lindex mylist 10        # index不在 mylist 的区间范围内
(nil)
```

- **实战场景**
    - **微博TimeLine**: 有人发布微博，用lpush加入时间轴，展示新的列表信息。
    - **消息队列**

## 2.3 Set集合

> Redis 的 Set 是 String 类型的无序集合。集合成员是唯一的，这就意味着集合中不能出现重复的数据。

Redis 中集合是通过哈希表实现的，所以添加，删除，查找的复杂度都是 O(1)。

- **图例**

![](img/Pasted%20image%2020240805152238.png)

- **命令使用**

| 命令        | 简述                        | 使用                   |
| --------- | ------------------------- | -------------------- |
| SADD      | 向集合添加一个或多个成员              | SADD key value       |
| SCARD     | 获取集合的成员数                  | SCARD key            |
| SMEMBERS  | 返回集合中的所有成员                | SMEMBERS key member  |
| SISMEMBER | 判断 member 元素是否是集合 key 的成员 | SISMEMBER key member |

其它一些集合操作，请参考这里https://www.runoob.com/redis/redis-sets.html

- **命令执行**

```
127.0.0.1:6379> sadd myset hao hao1 xiaohao hao
(integer) 3
127.0.0.1:6379> smembers myset
1) "xiaohao"
2) "hao1"
3) "hao"
127.0.0.1:6379> sismember myset hao
(integer) 1
```

- **实战场景**
    - **标签**（tag）,给用户添加标签，或者用户给消息添加标签，这样有同一标签或者类似标签的可以给推荐关注的事或者关注的人。
    - **点赞，或点踩，收藏等**，可以放到set中实现

## 2.4 Hash散列

> Redis hash 是一个 string 类型的 field（字段） 和 value（值） 的映射表，hash 特别适合用于存储对象。

- **图例**

![](img/Pasted%20image%2020240805152650.png)

- **命令使用**

|命令|简述|使用|
|---|---|---|
|HSET|添加键值对|HSET hash-key sub-key1 value1|
|HGET|获取指定散列键的值|HGET hash-key key1|
|HGETALL|获取散列中包含的所有键值对|HGETALL hash-key|
|HDEL|如果给定键存在于散列中，那么就移除这个键|HDEL hash-key sub-key1|

- **命令执行**

```
127.0.0.1:6379> hset user name1 hao
(integer) 1
127.0.0.1:6379> hset user email1 hao@163.com
(integer) 1
127.0.0.1:6379> hgetall user
1) "name1"
2) "hao"
3) "email1"
4) "hao@163.com"
127.0.0.1:6379> hget user user
(nil)
127.0.0.1:6379> hget user name1
"hao"
127.0.0.1:6379> hset user name2 xiaohao
(integer) 1
127.0.0.1:6379> hset user email2 xiaohao@163.com
(integer) 1
127.0.0.1:6379> hgetall user
1) "name1"
2) "hao"
3) "email1"
4) "hao@163.com"
5) "name2"
6) "xiaohao"
7) "email2"
8) "xiaohao@163.com"
```

- **实战场景**
    - **缓存**： 能直观，相比string更节省空间，的维护缓存信息，如用户信息，视频信息等。

## 2.5 Zset有序集合

> Redis 有序集合和集合一样也是 string 类型元素的集合,且不允许重复的成员。不同的是每个元素都会关联一个 double 类型的分数。redis 正是通过分数来为集合中的成员进行从小到大的排序。

有序集合的成员是唯一的, 但分数(score)却可以重复。有序集合是通过两种数据结构实现：

1. **压缩列表(ziplist)**: ziplist是为了提高存储效率而设计的一种特殊编码的双向链表。它可以存储字符串或者整数，存储整数时是采用整数的二进制而不是字符串形式存储。它能在O(1)的时间复杂度下完成list两端的push和pop操作。但是因为每次操作都需要重新分配ziplist的内存，所以实际复杂度和ziplist的内存使用量相关
2. **跳跃表（zSkiplist)**: 跳跃表的性能可以保证在查找，删除，添加等操作的时候在对数期望时间内完成，这个性能是可以和平衡树来相比较的，而且在实现方面比平衡树要优雅，这是采用跳跃表的主要原因。跳跃表的复杂度是O(log(n))。

- **图例**

![](img/Pasted%20image%2020240805153106.png)

- **命令使用**

|命令|简述|使用|
|---|---|---|
|ZADD|将一个带有给定分值的成员添加到有序集合里面|ZADD zset-key 178 member1|
|ZRANGE|根据元素在有序集合中所处的位置，从有序集合中获取多个元素|ZRANGE zset-key 0-1 withccores|
|ZREM|如果给定元素成员存在于有序集合中，那么就移除这个元素|ZREM zset-key member1|

更多命令请参考这里 https://www.runoob.com/redis/redis-sorted-sets.html

- **命令执行**

```
127.0.0.1:6379> zadd myscoreset 100 hao 90 xiaohao
(integer) 2
127.0.0.1:6379> ZRANGE myscoreset 0 -1
1) "xiaohao"
2) "hao"
127.0.0.1:6379> ZSCORE myscoreset hao
"100"
```

- **实战场景**
    - **排行榜**：有序集合经典使用场景。例如小说视频等网站需要对用户上传的小说视频做排行榜，榜单可以按照用户关注数，更新时间，字数等打分，做排行。

# 3 三种特殊类型详解
## 3.1 HyperLogLogs（基数统计）

> Redis 2.8.9 版本更新了 Hyperloglog 数据结构！

- **什么是基数？**

举个例子，A = {1, 2, 3, 4, 5}， B = {3, 5, 6, 7, 9}；那么基数（不重复的元素）= 1, 2, 4, 6, 7, 9； （允许容错，即可以接受一定误差）

- **HyperLogLogs 基数统计用来解决什么问题**？

这个结构可以非常省内存的去统计各种计数，比如注册 IP 数、每日访问 IP 数、页面实时UV、在线用户数，共同好友数等。

- **它的优势体现在哪**？
一个大型的网站，每天 IP 比如有 100 万，粗算一个 IP 消耗 15 字节，那么 100 万个 IP 就是 15M。而 HyperLogLog 在 Redis 中每个键占用的内容都是 12K，理论存储近似接近 2^64 个值，不管存储的内容是什么，它一个基于基数估算的算法，只能比较准确的估算出基数，可以使用少量固定的内存去存储并识别集合中的唯一元素。而且这个估算的基数并不一定准确，是一个带有 0.81% 标准错误的近似值（对于可以接受一定容错的业务场景，比如IP数统计，UV等，是可以忽略不计的）。

- **相关命令使用**

```
127.0.0.1:6379> pfadd key1 a b c d e f g h i	# 创建第一组元素
(integer) 1
127.0.0.1:6379> pfcount key1					# 统计元素的基数数量
(integer) 9
127.0.0.1:6379> pfadd key2 c j k l m e g a		# 创建第二组元素
(integer) 1
127.0.0.1:6379> pfcount key2
(integer) 8
127.0.0.1:6379> pfmerge key3 key1 key2			# 合并两组：key1 key2 -> key3 并集
OK
127.0.0.1:6379> pfcount key3
(integer) 13
```

### 3.1.1 chatGpt回答

HyperLogLog（HLL）是一种概率数据结构，用于估计唯一元素的基数（即集合中不同元素的数量）。它在 Redis 中作为一种非常高效的工具来处理大型数据集的基数估计，尤其在内存占用方面具有显著优势。

#### 3.1.1.1 HyperLogLog 的特点

1. **高效的内存使用**：
   - 传统的集合数据结构（如哈希表）需要存储每个唯一元素，而 HyperLogLog 只需少量内存（大约 12 KB）即可处理 2^64 个不同元素的基数估计。

2. **概率性**：
   - HyperLogLog 是一种概率算法，因此结果不是绝对精确的，但误差通常在 0.81% 左右，对于很多应用来说已经足够精确。

3. **并行友好**：
   - HyperLogLog 可以方便地进行合并操作，这使得在分布式系统中进行基数估计变得更加高效。

#### 3.1.1.2 Redis 中的 HyperLogLog 操作

在 Redis 中，HyperLogLog 相关的命令非常简单且易于使用，主要包括以下几种：

1. **PFADD key element [element ...]**：
   - 将一个或多个元素添加到 HyperLogLog 数据结构中。如果添加了新的唯一元素，返回 1，否则返回 0。

   ```shell
   PFADD myhll a b c
   ```

2. **PFCOUNT key [key ...]**：
   - 返回 HyperLogLog 的基数估计值。如果提供了多个 HyperLogLog，将返回它们合并后的基数估计值。

   ```shell
   PFCOUNT myhll
   ```

3. **PFMERGE destkey sourcekey [sourcekey ...]**：
   - 合并多个 HyperLogLog 到一个 HyperLogLog 中。目标 HyperLogLog 的基数估计值将包含所有源 HyperLogLog 中的所有元素。

   ```shell
   PFMERGE myhll2 myhll1 myhll
   ```

#### 3.1.1.3 使用场景

HyperLogLog 在以下场景中尤为适用：

1. **唯一访客统计**：
   - 在网站分析中，可以用 HyperLogLog 来统计独立访客数，而不必保存每个访客的详细信息，节省大量内存。

2. **实时分析**：
   - 对于实时流数据的基数估计，如日志分析、事件计数等，HyperLogLog 提供了高效且精确的解决方案。

3. **去重操作**：
   - 在大数据处理中，需要对数据进行去重统计，HyperLogLog 可以高效完成这一任务。

总的来说，Redis 中的 HyperLogLog 提供了一种高效且内存友好的方式来处理基数估计问题，使得处理大规模数据变得更加可行。

## 3.2 Bitmap （位存储）

> Bitmap 即位图数据结构，都是操作二进制位来进行记录，只有0 和 1 两个状态。

- **用来解决什么问题**？
比如：统计用户信息，活跃，不活跃！ 登录，未登录！ 打卡，不打卡！ **两个状态的，都可以使用 Bitmaps**！

如果存储一年的打卡状态需要多少内存呢？ 365 天 = 365 bit 1字节 = 8bit 46 个字节左右！

- **相关命令使用**
使用bitmap 来记录 周一到周日的打卡！ 周一：1 周二：0 周三：0 周四：1 ......

```
127.0.0.1:6379> setbit sign 0 1
(integer) 0
127.0.0.1:6379> setbit sign 1 1
(integer) 0
127.0.0.1:6379> setbit sign 2 0
(integer) 0
127.0.0.1:6379> setbit sign 3 1
(integer) 0
127.0.0.1:6379> setbit sign 4 0
(integer) 0
127.0.0.1:6379> setbit sign 5 0
(integer) 0
127.0.0.1:6379> setbit sign 6 1
(integer) 0
```

查看某一天是否有打卡！

```
127.0.0.1:6379> getbit sign 3
(integer) 1
127.0.0.1:6379> getbit sign 5
(integer) 0
```

统计操作，统计 打卡的天数！

```
127.0.0.1:6379> bitcount sign # 统计这周的打卡记录，就可以看到是否有全勤！
(integer) 3
```

### 3.2.1 chatGpt回答
Redis 的 Bitmap 是一种用于处理位级别操作的数据结构。Bitmap 实际上是字符串类型的一部分，通过对字符串的每个比特位进行操作，实现了存储和操作大量二进制数据的功能。Bitmap 通常用于需要高效存储和处理大量布尔值的场景，比如用户在线状态、日活跃用户统计等。

#### 3.2.1.1 Bitmap 的特点

1. **高效的内存使用**：
   - 每个位仅占用一比特的内存空间，这使得 Bitmap 能够非常高效地存储大量布尔值。

2. **位操作**：
   - 支持直接对比特位进行操作，包括设置、清除、取反等操作。

3. **简单易用**：
   - Redis 提供了一系列简单的命令来操作 Bitmap，使其易于使用。

#### 3.2.1.2 Redis 中的 Bitmap 操作

在 Redis 中，Bitmap 的操作主要通过以下几个命令实现：

1. **SETBIT key offset value**：
   - 设置指定 key 的 Bitmap 中的 offset 位为 value（0 或 1）。如果 key 不存在，Redis 会自动创建一个新的 Bitmap。

   ```shell
   SETBIT mybitmap 7 1
   ```

   上述命令将 mybitmap 的第 7 位设置为 1。

2. **GETBIT key offset**：
   - 获取指定 key 的 Bitmap 中的 offset 位的值。

   ```shell
   GETBIT mybitmap 7
   ```

   上述命令将返回 mybitmap 的第 7 位的值。

3. **BITCOUNT key [start end]**：
   - 统计 Bitmap 中值为 1 的比特位的数量，可以选择性地统计指定范围内的比特位。

   ```shell
   BITCOUNT mybitmap
   ```

   上述命令将统计 mybitmap 中所有值为 1 的比特位数量。

4. **BITOP operation destkey key [key ...]**：
   - 对一个或多个 Bitmap 执行位运算（AND、OR、XOR、NOT），结果保存到 destkey。

   ```shell
   BITOP AND resultbitmap bitmap1 bitmap2
   ```

   上述命令将 bitmap1 和 bitmap2 执行 AND 操作，结果保存到 resultbitmap。

5. **BITPOS key bit [start] [end]**：
   - 查找第一个设置为 bit（0 或 1）的比特位的位置，可以选择性地在指定范围内查找。

   ```shell
   BITPOS mybitmap 1
   ```

   上述命令将返回 mybitmap 中第一个值为 1 的比特位的位置。

#### 3.2.1.3 使用场景

Bitmap 在以下场景中尤为适用：

1. **用户在线状态**：
   - 用 Bitmap 记录用户在线状态，一个用户对应一个比特位，高效存储和查询在线用户。

2. **日活跃用户统计**：
   - 通过 Bitmap 记录每个用户在某天是否活跃，快速统计日活跃用户数量。

3. **权限管理**：
   - 使用 Bitmap 存储和检查权限标志，快速判断用户是否具有某种权限。

4. **A/B 测试**：
   - 在 A/B 测试中，通过 Bitmap 高效记录和分析用户分组和行为数据。

Bitmap 通过其高效的内存使用和便捷的位操作，为 Redis 提供了一种强大的数据处理能力，适用于需要处理大量布尔值的各种应用场景。
## 3.3 geospatial (地理位置)

> Redis 的 Geo 在 Redis 3.2 版本就推出了! 这个功能可以推算地理位置的信息: 两地之间的距离, 方圆几里的人

Redis 提供了地理空间数据（Geospatial）的支持，这使得它可以处理与地理位置相关的数据，如存储地理坐标、计算距离、查找范围内的地点等。Redis 使用一种称为 Geohash 的编码技术，将地理坐标转换为字符串，从而实现高效的存储和查询。

### 3.3.1 Geospatial 数据类型的特点
1. **地理位置存储**：
	+ 支持存储地理位置（经度和纬度）及其关联的数据。
2. **高效的空间查询**：
	+ 可以快速进行范围查询、距离计算、邻近点查找等操作。
3. **Geohash 编码**：
	+ 使用 Geohash 编码将地理坐标转换为可排序的字符串，便于高效存储和检索。
### 3.3.2 常用方法介绍
#### 3.3.2.1 geoadd

> 添加地理位置

```
127.0.0.1:6379> geoadd china:city 118.76 32.04 manjing 112.55 37.86 taiyuan 123.43 41.80 shenyang
(integer) 3
127.0.0.1:6379> geoadd china:city 144.05 22.52 shengzhen 120.16 30.24 hangzhou 108.96 34.26 xian
(integer) 3
```

**规则**

两级无法直接添加，我们一般会下载城市数据(这个网址可以查询 GEO： http://www.jsons.cn/lngcode)！

- 有效的经度从-180度到180度。
- 有效的纬度从-85.05112878度到85.05112878度。

```
# 当坐标位置超出上述指定范围时，该命令将会返回一个错误。
127.0.0.1:6379> geoadd china:city 39.90 116.40 beijin
(error) ERR invalid longitude,latitude pair 39.900000,116.400000
```

#### 3.3.2.2 geopos

> 获取指定的成员的经度和纬度

```
127.0.0.1:6379> geopos china:city taiyuan manjing
1) 1) "112.54999905824661255"
   1) "37.86000073876942196"
2) 1) "118.75999957323074341"
   1) "32.03999960287850968"
```

获得当前定位, 一定是一个坐标值!

#### 3.3.2.3 geodist

> 如果不存在, 返回空

单位如下
- m
- km
- mi 英里
- ft 英尺

```
127.0.0.1:6379> geodist china:city taiyuan shenyang m
"1026439.1070"
127.0.0.1:6379> geodist china:city taiyuan shenyang km
"1026.4391"
```

#### 3.3.2.4 georadius

> 附近的人 ==> 获得所有附近的人的地址, 定位, 通过半径来查询

获得指定数量的人

```
127.0.0.1:6379> georadius china:city 110 30 1000 km			以 100,30 这个坐标为中心, 寻找半径为1000km的城市
1) "xian"
2) "hangzhou"
3) "manjing"
4) "taiyuan"
127.0.0.1:6379> georadius china:city 110 30 500 km
1) "xian"
127.0.0.1:6379> georadius china:city 110 30 500 km withdist
1) 1) "xian"
   2) "483.8340"
127.0.0.1:6379> georadius china:city 110 30 1000 km withcoord withdist count 2
1) 1) "xian"
   2) "483.8340"
   3) 1) "108.96000176668167114"
      2) "34.25999964418929977"
2) 1) "manjing"
   2) "864.9816"
   3) 1) "118.75999957323074341"
      2) "32.03999960287850968"
```

参数 key 经度 纬度 半径 单位 [显示结果的经度和纬度] [显示结果的距离] [显示的结果的数量]

#### 3.3.2.5 georadiusbymember

> 显示与指定成员一定半径范围内的其他成员

```
127.0.0.1:6379> georadiusbymember china:city taiyuan 1000 km
1) "manjing"
2) "taiyuan"
3) "xian"
127.0.0.1:6379> georadiusbymember china:city taiyuan 1000 km withcoord withdist count 2
1) 1) "taiyuan"
   2) "0.0000"
   3) 1) "112.54999905824661255"
      2) "37.86000073876942196"
2) 1) "xian"
   2) "514.2264"
   3) 1) "108.96000176668167114"
      2) "34.25999964418929977"
```

参数与 georadius 一样

#### 3.3.2.6 geohash(较少使用)

> 该命令返回11个字符的hash字符串

```
127.0.0.1:6379> geohash china:city taiyuan shenyang
1) "ww8p3hhqmp0"
2) "wxrvb9qyxk0"
```

将二维的经纬度转换为一维的字符串, 如果两个字符串越接近, 则距离越近

#### 3.3.2.7 底层

> geo底层的实现原理实际上就是Zset, 我们可以通过Zset命令来操作geo

```
127.0.0.1:6379> type china:city
zset
```

查看全部元素 删除指定的元素

```
127.0.0.1:6379> zrange china:city 0 -1 withscores
 1) "xian"
 2) "4040115445396757"
 3) "hangzhou"
 4) "4054133997236782"
 5) "manjing"
 6) "4066006694128997"
 7) "taiyuan"
 8) "4068216047500484"
 9) "shenyang"
1)  "4072519231994779"
2)  "shengzhen"
3)  "4154606886655324"
127.0.0.1:6379> zrem china:city manjing
(integer) 1
127.0.0.1:6379> zrange china:city 0 -1
1) "xian"
2) "hangzhou"
3) "taiyuan"
4) "shenyang"
5) "shengzhen"
```

### 3.3.3 使用场景

Redis 的 Geospatial 功能在以下场景中尤为适用：
1. **位置服务**：
	+ 地理位置存储和查询，如商店、餐馆、ATM 等的位置信息。
2. **社交网络**：
	+ 查找附近的朋友、群组活动等。
3. **物流和配送**：
	+ 计算配送距离、查找最近的配送点等。
4. **旅游和出行**：
	+ 查找周边景点、酒店等服务。

# 4 Stream （暂时不整理）

