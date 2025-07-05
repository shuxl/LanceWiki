在分析过acquire方法之后，这次来看看与之对应的release方法：
``` java
public final boolean release(long arg) {
        if (tryRelease(arg)) {
            Node h = head;
            if (h != null && h.waitStatus != 0)
                unparkSuccessor(h);
            return true;
        }
        return false;
    }
```

tryRelease(arg)方法是由子类实现的，方法返回true表示释放成功，下一步就是从队列中将线程释放掉，并且唤醒同步队列中的第一个线程的线程。
由于解锁是从头节点开始的，所以取Node h = head，然后的判断条件：if (h != null && h.waitStatus != 0)，我们可以分析一下可能的几种情况:

1. head = null
	head 还未初始化。初始情况下，head = null，当第一个节点入队后，head 会被初始为一个虚拟（dummy）节点。这里，如果还没节点入队就调用 release 释放同步状态，就会出现 h = null 的情况
2. head != null && waitStatus = 0：表明后继节点对应的线程仍在运行中，不需要唤醒
3. head != null && waitStatus < 0：后继节点对应的线程可能被阻塞了，需要唤醒
当满足情况3的时候，进入了unparkSuccessor方法：

``` java
private void unparkSuccessor(Node node) {
        int ws = node.waitStatus;
        if (ws < 0)
            compareAndSetWaitStatus(node, ws, 0);
        Node s = node.next;
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);
    }
```

首先分析下`compareAndSetWaitStatus(node, ws, 0);`的作用，表面上就是将当前释放锁节点的waitStatus改成0，但是这里存在两个疑问：1. 为什么要改成0，2:为什么用CAS的方式改；

要搞清楚这两点，就要从shouldParkAfterFailedAcquire的代码中找线索，判断是否阻塞的一个关键因素，就是对前置节点的waitStatus状态进行判断，如果前置节点ws == Node.SIGNAL直接阻塞，否则的话先将前置节点compareAndSetWaitStatus(pred, ws, Node.SIGNAL);，然后进入下一次自旋。unparkSuccessor将状态改成0，是因为当前节点已经释放锁了，那么后续节点不需要阻塞了，不想让后续节点进入ws == Node.SIGNAL的分支中。

那么，为什么要用CAS的方式呢，我们首先要有个理念，就是线程的环境是瞬息万变的，unparkSuccessor的compareAndSetWaitStatus(node, ws, 0);和shouldParkAfterFailedAcquire的compareAndSetWaitStatus(pred, ws, Node.SIGNAL);是有可能同时执行的，而且他们操作的有可能是同一个节点的数据，那么就会有线程竞争，所以需要CAS，解决并发问题。

我们假设队列中只有两个节点:
![](img/Pasted%20image%2020240802152528.png)
B的shouldParkAfterFailedAcquire先执行完，将A的ws改成SIGNAL进入自旋，然后A.unparkSuccessor执行完改回0，此时B即使进入shouldParkAfterFailedAcquire也不会阻塞，而是进入下一次循环，这一次循环不同的是，锁已经被释放，并且A是头节点，那么B执行到acquireQueued的if (p == head && tryAcquire(arg)) {就能顺利获取到锁，B成功晋级成头节点(执行setHead(node);)

所以要搞清楚unparkSuccessor的这行代码，需要带着加锁的逻辑一起看，不然没法"串联"起来。

剩下的代码其实含义很明确：找到后面的第一个不是CANCLE状态的线程，唤醒他。这个遍历的过程是从后往前的，很奇怪吧，为什么不从前往后的，非要反着来？这里还是"瞬息万变"的理念，你想想，如果在遍历之前，突然有一个线程加入进来，添加到尾部，会有一个瞬间状态是这样的：
![](img/Pasted%20image%2020240802152546.png)
如果从前往后，那么就无法遍历到n4节点。
