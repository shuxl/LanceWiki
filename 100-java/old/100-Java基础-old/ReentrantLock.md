
AbstractQueuedSynchronizer
    ConditionObject implements Condition, java.io.Serializable
    static final class Node

ReentrantLock
    class Sync extends AbstractQueuedSynchronizer 
    class FairSync extends Sync
    class NonfairSync extends Sync

CountDownLatch 类似计数器的功能， 比如有一个任务A， 它要等待其他4个任务执行完毕之后才能执行， 此时就可以利用CountDownLatch来实现这种功能了。
Semaphore 可以控同时访问的线程个数，通过 acquire() 获取一个许可，如果没有就等待，而 release() 释放一个许可