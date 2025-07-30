- 来源 https://blog.csdn.net/IToBeNo_1/article/details/123404852?spm=1001.2014.3001.5502
# 1 acquire
该方法是一个模板方法，用于线程获取【锁】
``` java
public final void acquire(int arg) {
       if (!tryAcquire(arg) && acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
           selfInterrupt();
}
```

## 1.1 流程解析：
1. 先执行tryAcquire，这是方法是给子类实现的，用于直接获取共享变量（对state变量CAS操作），也就是【锁】

2. 当tryAcquire执行失败，则执行acquireQueued(addWaiter(Node.EXCLUSIVE), arg)

3. 先看addWaiter(Node.EXCLUSIVE)，Node.EXCLUSIVE表示创建一个排他线程节点，并将节点加入到等到队列中，需要注意哦，加入队列之后并没有将线程阻塞，这步工作由acquireQueued完成：
    1. 队列为空时：
        compareAndSetHead(new Node())，就是将head和tail都指向new Node(),即当前线程节点
	2. 队列不为空时：
	    ![](img/Pasted%20image%2020240802112040.png)
	    ![](img/Pasted%20image%2020240802112109.png)
	    ![](img/Pasted%20image%2020240802112123.png)
	    ![](img/Pasted%20image%2020240802112135.png)
	    ![](img/Pasted%20image%2020240802112146.png)

4. addWaiter执行完成，返回的是当前线程节点的引用，并且作为acquireQueued的参数，如此进入acquireQueued方法，再次试图获取【锁】，失败则阻塞当前线程，先看下代码：
```
final boolean acquireQueued(final Node node, long arg) {
        boolean failed = true;
        try {
            boolean interrupted = false;
            for (;;) {
                final Node p = node.predecessor();
                if (p == head && tryAcquire(arg)) {
                    setHead(node);
                    p.next = null; // help GC
                    failed = false;
                    return interrupted;
                }
                if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
            }
        } finally {
            if (failed)
                cancelAcquire(node);
        }
    }
```

参数node，就是addWaiter的返回值，是已经加入到队列的当前线程的节点，这里需要有几点需要提一下：
    (1). 当前节点一定在队尾;
    (2). failed变量只有内部流程抛异常的时候，才会保持true，导致finally执行到cancelAcquire,简单讲就是当前线程获取锁的过程发生异常会放弃锁。
    在acquire一开始的时候就试图获取锁，失败了才会执行到这个地方来，这个过程中线程的运行环境瞬息万变，那么如果当前线程加入队列之后，现在已经只剩他自己了，那不应该阻塞，应该再试试看能不能获取到锁，所以看到代码if (p == head && tryAcquire(arg)) {的判断，如果很幸运成功，那么需要将当前节点从队列中"弹"出去，然后再退出，"弹出去"的过程其实就是将当前节点变成head节点(一个空节点)：
    ![](img/Pasted%20image%2020240802112822.png)
    ![](img/Pasted%20image%2020240802112929.png)
    ![](img/Pasted%20image%2020240802112940.png)
    ![](img/Pasted%20image%2020240802112952.png)
    ![](img/Pasted%20image%2020240802113003.png)

如果还是没有成功，原因有两个：
    (1). 当前节点不是首节点（前面还有人等着呢）；
    (2). 争夺【锁】失败
    此时执行`if (shouldParkAfterFailedAcquire(p, node) && parkAndCheckInterrupt())`，字面义就是先判断线程应不应该被阻塞，如果不应该，则进入下一次for(;;)自旋，如果应该阻塞，则调用parkAndCheckInterrupt，阻塞失败的话，也会进入下一次自旋。

5. 那怎么知道应不应该阻塞呢？看看shouldParkAfterFailedAcquire的逻辑：
``` java
    private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
        int ws = pred.waitStatus;
        if (ws == Node.SIGNAL)
            return true;
        if (ws > 0) {
            do {
                node.prev = pred = pred.prev;
            } while (pred.waitStatus > 0);
            pred.next = node;
        } else {
            compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
        }
        return false;
    }
```

这个方法中最重要的就是搞懂waitStatus变量的作用，这个值总共有以下几种值:
``` java
static final int CANCELLED =  1;
static final int SIGNAL    = -1; // 
static final int CONDITION = -2;
static final int PROPAGATE = -3;
```

只有CANCELLED是ws > 0的，它表示某个线程节点取消等待，放弃参与锁竞争，如果发现前置节点是这种状态，那么就要跳过他，再往链表的前面界面找找有没有"正常"的节点，这也是if (ws > 0) {分支的执行目的，这个过程动图表示：
![](img/Pasted%20image%2020240802113143.png)
![](img/Pasted%20image%2020240802113159.png)
![](img/Pasted%20image%2020240802113210.png)
![](img/Pasted%20image%2020240802113219.png)

ws == Node.SIGNAL直接返回true，关键在于理解SIGNAL的含义，我认为有两个含义：
    (1). 节点本身还没有获取到锁;
    (2). 存在后继节点，等待唤醒
if (ws == Node.SIGNAL)这个ws是前一个节点的状态，他是SIGNAL说明他也在等待锁，那么当前我这个节点还想个屁吃，直接阻塞着等待就好了。
else包含了pred.waitStatus == 0 和 PROPAGATE状态，注意哦，我们现在是刚刚结束addWaiter的流程，走到这里的，所以是尾节点，当然也有可能队列中只有一个节点，所以也有可能既是头节点又是尾节点，那么前置节点的状态有几种情况：
   (1). 头节点，则pred.waitStatus == 0
   (2). 原来的尾节点；如果前直节点是EXCLUSIVE则pred.waitStatus == 0，如果前节点是SHARED，则有可能是pred.waitStatus \=\=PROPAGATE,这种情况发生在链路上写线程释放锁的时候，会将后续的读线程状态置为PROPAGATE
线程环境瞬息万变，这两种情况，都不急着阻塞，因为是有可能马上就没有线程竞争了，尤其是第一种情况，前置节点是第一个，但是加锁失败了，等一等可能就到我们自己了，所以先用compareAndSetWaitStatus(pred, ws, Node.SIGNAL);标记一下，然后回到上一层的acquireQueued方法会发现其实是进入到下一次自旋中。

如果说shouldParkAfterFailedAcquire返回true了，那么没办法了，说明穷尽伎俩也没不可能马上拿到锁了，那就等着呗，就会进入parkAndCheckInterrupt中：
```
private final boolean parkAndCheckInterrupt() {
	LockSupport.park(this);
	return Thread.interrupted();
}
```

这简单的代码也是AQS的要素之一，就是LockSupport.park方法啦，把线程阻塞，需要注意的是，阻塞期间如果被interrupt中断，是不抛出异常，而是返回中断标识，if (shouldParkAfterFailedAcquire(p, node) &&parkAndCheckInterrupt())的分支在发生中断的时候会进入分支代码，interrupted = true;标记下曾经发生过中断，这么做是因为调用过Thread.interrupted()之后，线程的中断标志就会被重置了，如果以后想要知道线程在等待、自旋过程中有没有发生过中断，就没办法了，所以设置了一个interrupted变量来保存历史。

acquireQueued会一直等到线程获取锁才返回，这个过程中存在多次自旋、线程阻塞，而他的返回值就是interrupted变量，如果返回true表示曾经发生过中断，那么就在线程上"还原现场"，利用selfInterrupt();设置一下中断标志，这样外部调用方才能感知到线程曾经发生过中断。
