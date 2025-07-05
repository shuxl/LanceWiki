架构
    1 broker （服务器节点）
        Kafka 集群包含一个或多个服务器，服务器节点称为broker。
        broker存储topic的数据。如果某topic有N个partition，集群有N个broker，那么每个broker存储该topic的一个partition。
        如果某topic有N个partition，集群有(N+M)个broker，那么其中有N个broker存储该topic的一个partition，剩下的M个broker不存储该topic的partition数据。
        如果某topic有N个partition，集群中broker数目少于N个，那么一个broker存储该topic的一个或多个partition。在实际生产环境中，尽量避免这种情况的发生，这种情况容易导致Kafka集群数据不均衡。
    2 Topic （消息的类别-数据库表）
        每条发布到Kafka集群的消息都有一个类别，这个类别被称为Topic。（物理上不同Topic的消息分开存储，逻辑上一个Topic的消息虽然保存于一个或多个broker上但用户只需指定消息的Topic即可生产或消费数据而不必关心数据存于何处）
        类似于数据库的表名
    3 Partition （分区）
        topic中的数据分割为一个或多个partition。每个topic至少有一个partition。每个partition中的数据使用多个segment文件存储。partition中的数据是有序的，不同partition间的数据丢失了数据的顺序。如果topic有多个partition，消费数据时就不能保证数据的顺序。在需要严格保证消息的消费顺序的场景下，需要将partition数目设为1。

    4 Producer
        生产者即数据的发布者，该角色将消息发布到Kafka的topic中。broker接收到生产者发送的消息后，broker将该消息追加到当前用于追加数据的segment文件中。生产者发送的消息，存储到一个partition中，生产者也可以指定数据存储的partition。
    5 Consumer
        消费者可以从broker中读取数据。消费者可以消费多个topic中的数据。
    6 Consumer Group
        每个Consumer属于一个特定的Consumer Group（可为每个Consumer指定group name，若不指定group name则属于默认的group）。这是kafka用来实现一个topic消息的广播（发给所有的consumer）和单播（发给任意一个consumer）的手段。一个topic可以有多个CG。topic的消息会复制-给consumer。如果需要实现广播，只要每个consumer有一个独立的CG就可以了。要实现单播只要所有的consumer在同一个CG。用CG还可以将consumer进行自由的分组而不需要多次发送消息到不同的topic。

    7 Leader （分区的对外提供读写的主副本）
        每个partition有多个副本，其中有且仅有一个作为Leader，Leader是当前负责数据的读写的partition。
    8 Follower （备份副本）
        Follower跟随Leader，所有写请求都通过Leader路由，数据变更会广播给所有Follower，Follower与Leader保持数据同步。如果Leader失效，则从Follower中选举出一个新的Leader。当Follower与Leader挂掉、卡住或者同步太慢，leader会把这个follower从“in sync replicas”（ISR）列表中删除，重新创建一个Follower。
    9 Offset
        kafka的存储文件都是按照offset.kafka来命名，用offset做名字的好处是方便查找。例如你想找位于2049的位置，只要找到2048.kafka的文件即可。当然the first offset就是00000000000.kafka



分布式模型
    Kafka生产者客户端发布消息到服务端的指定主题，会指定消息所属的分区。生产者发布消息时根据消息是否有键，采用不同的分区策略。消息没有键时，通过轮询方式进行客户端负载均衡；消息有键时，根据分区语义（例如hash）确保相同键的消息总是发送到同一分区。
    Kafka的消费者通过订阅主题来消费消息，并且每个消费者都会设置一个消费组名称。因为生产者发布到主题的每一条消息都只会发送给消费者组的一个消费者。所以，如果要实现传统消息系统的“队列”模型，可以让每个消费者都拥有相同的消费组名称，这样消息就会负责均衡到所有的消费者；如果要实现“发布-订阅”模型，则每个消费者的消费者组名称都不相同，这样每条消息就会广播给所有的消费者。

增加吞吐量
    一个topic做多个分区，同时使用消费者组内建更多的消费者去监听更多的分区

Push 和 Pull
    push模式的目标是尽可能以最快速度传递消息，但是这样很容易造成Consumer来不及处理消息，典型的表现就是拒绝服务以及网络拥塞。而pull模式则可以根据Consumer的消费能力以适当的速率消费消息。
    kafka选择由Producer向broker push消息并由Consumer从broker pull消息。

ISR 所有与leader副本保持一定程度同步的副本（包括leader副本在内）组成 ISR (In Sync Replicas)
    AR ： 分区中的所有副本统称为 AR (Assigned Replicas)。
    OSR：于leader副本同步滞后过多的副本（不包括leader副本）将组成 OSR （Out-of-Sync Replied）
    ISR是AR的一个子集，AR = ISR + OSR。
    ISR 的伸缩性。leader副本负责维护和跟踪 ISR 集合中所有follower副本的滞后状态，当follower副本落后太多或失效时，leader副本会把它从 ISR 集合中剔除。如果 OSR 集合中所有follower副本“追上”了leader副本，那么leader副本会把它从 OSR 集合转移至 ISR 集合。默认情况下，当leader副本发生故障时，只有在 ISR 集合中的follower副本才有资格被选举为新的leader，而在 OSR 集合中的副本则没有任何机会（不过这个可以通过配置来改变）。