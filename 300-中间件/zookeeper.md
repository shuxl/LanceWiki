
zookeeper 工作方式：
    》Zookeeper集群包含一个1个Leader，多个Follower
    》所有的Follower都可提供读服务
    》所有的写操作都会被forward到Leader
    》Client与Server通过NIO通信
    》全局串行化所有的写操作
    》保证同一客户端的指令被FIFO执行
    》保证消息通知的FIFO

zookeeper 读写：leader负责读写，follower负责读。follower遇到写，会提交给leader进行操作。
    写流程：一半以上的从节点写成功，返回给客户端成功。
        客户端连接到集群中某一个节点；客户端发送写请求；服务端连接节点，把该写请求转发给leader；leader处理写请求，一半以上的从节点也写成功，返回给客户端成功。
    读流程：客户端连接到集群中某一节点，读请求，直接返回。

最终一致性
    读数据时，有可能会脏读。比较推荐watch的方式，实现数据的及时生效。

zookeeper节点类型：持久节点；持久节点顺序节点；临时节点；临时顺序节点

Zookeeper分布式锁：使用临时顺序节点。
    + 获取锁。zk创建持久节点ParentLock。第一个客户端想要获得锁时，在ParentLock下创建临时顺序节点lock1，然后client1查找ParentLock下的所有临时顺序节点并排序，判断自己创建的节点Lock1是不是顺序最靠前的一个。如果是第一个节点，则成功获取锁。
    + 锁未释放时，后续节点创建自己的节点后，再查询节点时，如果发现自己不是最小的节点，注册前一个节点watcher事件。后续节点抢锁失败，进入等待状态。这恰恰形成了一个等待队列，很像是Java当中ReentrantLock所依赖的AQS（AbstractQueuedSynchronizer）
    + 释放锁。任务完成，client1会显示的删除节点；或者客户端奔溃，断开与zk的连接，节点自动删除。

