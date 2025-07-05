Exchange 
    fanout：消息全部转发到与之绑定的queue上。不需要routingkey
    direct：routeKey必须完全匹配，才会被队列接收。
    topic：模式匹配。符号“#”匹配一个或多个词，符号“*”匹配不多不少一个词
    header：少使用

rabbitmq三种部署模式
    单节点模式。非集群模式，只有一个节点，挂了业务瘫痪，只能等待。
    普通模式。默认集群模式，某个节点挂了，该节点上的消息不能用，有影响的业务瘫痪，只能等待节点恢复重启可用（必须持久化消息情况下）
    镜像模式：把需要的队列做成镜像队列，存在于多个节点，属于RabbitMQ的HA方案。

HA镜像模式队列（吞吐量下降）。三种策略：
    1）同步至所有的
    2）同步最多N个机器
    3）只同步至符合指定名称的nodes

Mq发送消息的3种模式：none，manual（手动确认后，mq才会删除消息），auto（默认）
    manual模式：
        我们需要手动将连接工厂设置MANUAL后再接收到消息后我们需要手动确认，mq才会删除消息。否则会一直等待到消费端重启才会进行重新分发数据
        channel.basicAck(long,boolean); 确认收到消息，消息将被队列移除，false只确认当前consumer一个消息收到，true确认所有consumer获得的消息。
        channel.basicNack(long,boolean,boolean); 确认否定消息，第一个boolean表示一个consumer还是所有，第二个boolean表示requeue是否重新回到队列，true重新入队。
        channel.basicReject(long,boolean); 拒绝消息，requeue=false 表示不再重新入队，如果配置了死信队列则进入死信队列。

当消息回滚到消息队列时，这条消息不会回到队列尾部，而是仍是在队列头部，这时消费者会又接收到这条消息，如果想消息进入队尾，须确认消息后再次发送消息。
消息不丢失
    +消息持久化。Exchange；queue；message持久化发送（deliveryMode=2）
    +ACK确认机制。Message ackNowledgment机制，消费端消费完成，通知服务端后服务端才把消息从内村中删除
    +设置集群镜像模式（集群部署模式）。
    +消息补偿机制。消息补偿机制需要建立在消息要写入DB日志，发送日志，接受日志，两者的状态必须记录。然后根据DB日志记录check 消息发送消费是否成功，不成功，进行消息补偿措施，重新发送消息处理。
        1. 生产者消息丢失：rabbitmq事务（同步），开启confirm模式（异步，channel加listener，headleAck，handleNack），数据退回监听（channel加listener，handleReturn。exchange没有路由到queue上时）。
        2. rabbit丢失消息：mq设置持久化。
        3. 消费者丢失信息：设置manual模式。

Rabbti的5种队列
    1、简单队列。一对一
    2、work 模式。一个生产者对应多个消费者，但是只能有一个消费者获得消息！！！（多个消费者使用一个queue）
    3、发布/订阅模式。一个消费者将消息首先发送到交换器，交换器绑定到多个队列，然后被监听该队列的消费者所接收并消费
    4、路由模式。生产者将消息发送到direct交换器，在绑定队列和交换器的时候有一个路由key，生产者发送的消息会指定一个路由key，那么消息只会发送到相应key相同的队列，接着监听该队列的消费者消费消息。
    5、主题模式。上面的路由模式是根据路由key进行完整的匹配（完全相等才发送消息），这里的通配符模式通俗的来讲就是模糊匹配。

生产者生产过程：
    链接rabbitmq，获取channel，声明exchange，创建message，发布message，关闭channel，关闭链接
消费者消费过程：
    连接rabbitmq，获取channel，声明exchange，声明queue，绑定exchange和queue，消费message，关闭channel，关闭连接