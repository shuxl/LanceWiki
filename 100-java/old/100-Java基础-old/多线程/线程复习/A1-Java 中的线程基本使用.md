下面我将通过多个Java代码示例，系统演示Thread的基本使用，涵盖Thread类与Runnable接口、`start()`与`run()`的区别、线程生命周期（新建、就绪、运行、阻塞、终止），以及常见操作（`sleep()`、`join()`、`yield()`、`interrupt()`）。所有示例均基于Java标准库编写，并附有详细注释和解释。关键概念会结合线程原理说明，并引用相关来源。

---

### 0.1.1 一、Thread类与Runnable接口的使用

Java中创建线程有两种核心方式：​**继承Thread类**或**实现Runnable接口**。Runnable接口更灵活，因为它允许类继承其他父类，而Thread类会占用唯一的继承机会。

#### 0.1.1.1 示例1：继承Thread类

```
public class MyThread extends Thread {
    @Override
    public void run() {
        System.out.println("Thread running: " + Thread.currentThread().getName());
    }

    public static void main(String[] args) {
        MyThread thread = new MyThread(); // 线程状态：新建（New）
        thread.start(); // 启动线程，进入就绪（Runnable）状态
    }
}
```

#### 0.1.1.2 示例2：实现Runnable接口（推荐）

```
public class MyRunnable implements Runnable {
    @Override
    public void run() {
        System.out.println("Runnable running: " + Thread.currentThread().getName());
    }

    public static void main(String[] args) {
        Thread thread = new Thread(new MyRunnable()); // 通过Runnable创建线程
        thread.start(); // 启动线程
    }
}
```

- ​**关键区别**​：
    - `Thread`是类，需继承它并重写`run()`；`Runnable`是接口，任务逻辑与线程控制解耦，支持多线程共享同一任务实例。
    - 实际开发中优先用`Runnable`，因其更灵活且兼容线程池。

---

### 0.1.2 二、`start()`与`run()`的区别

- ​**`start()`**​：启动新线程，JVM会调用`run()`方法在新线程中执行（异步）。
- ​**`run()`**​：普通方法调用，在当前线程同步执行，​**不会创建新线程**。

#### 0.1.2.1 示例3：演示`start()` vs `run()`

```
public class StartVsRun {
    public static void main(String[] args) {
        Thread thread = new Thread(() -> {
            System.out.println("Executing in: " + Thread.currentThread().getName());
        });

        System.out.println("Calling run():");
        thread.run(); // 同步执行，输出 "main"（主线程）

        System.out.println("Calling start():");
        thread.start(); // 异步执行，输出新线程名（如 "Thread-0"）
    }
}
```

输出结果：

```
Calling run():
Executing in: main
Calling start():
Executing in: Thread-0
```

- ​**原理**​：`start()`内部通过本地方法`start0()`触发新线程，而`run()`直接执行方法体。

---

### 0.1.3 三、线程生命周期

线程生命周期包括5个状态，其转换关系如下：

1. ​**新建（New）​**​：线程对象创建后，未调用`start()`。
2. ​**就绪（Runnable）​**​：调用`start()`后，等待CPU调度。
3. ​**运行（Running）​**​：获得CPU时间片，执行`run()`方法。
4. ​**阻塞（Blocked）​**​：因`sleep()`、`wait()`、I/O等暂停执行。
5. ​**终止（Terminated）​**​：`run()`执行完毕或异常退出。

#### 0.1.3.1 状态转换图：

```
新建 → start() → 就绪 ↔ 运行 → 终止
              ↑      ↓
             阻塞 ← 等待条件（如sleep()）
```

---

### 0.1.4 四、常见线程操作示例

以下演示`sleep()`、`join()`、`yield()`和`interrupt()`的用法。

#### 0.1.4.1 1. `sleep()`：线程休眠

使线程暂停指定时间（毫秒），进入阻塞状态，不释放锁。

```
public class SleepDemo {
    public static void main(String[] args) {
        new Thread(() -> {
            try {
                System.out.println("Sleeping for 2s...");
                Thread.sleep(2000); // 阻塞2秒
                System.out.println("Awake!");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
    }
}
```

#### 0.1.4.2 2. `join()`：等待线程结束

强制当前线程等待目标线程终止，常用于线程同步。

```
public class JoinDemo {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(() -> {
            System.out.println("Worker started");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("Worker finished");
        });

        worker.start();
        System.out.println("Main waiting for worker...");
        worker.join(); // 主线程阻塞，直到worker结束
        System.out.println("Main continues");
    }
}
```

#### 0.1.4.3 3. `yield()`：让出CPU时间

提示调度器当前线程愿意让出CPU，但**不保证生效**，线程仍处于就绪状态。

```
public class YieldDemo {
    public static void main(String[] args) {
        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Thread 1: " + i);
                Thread.yield(); // 提示让出CPU
            }
        }).start();

        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                System.out.println("Thread 2: " + i);
            }
        }).start();
    }
}
// 输出可能交替（如1,2,1,2），但非绝对
```

#### 0.1.4.4 4. `interrupt()`：中断线程

设置线程中断标志，通常需在`run()`中检查`isInterrupted()`或处理`InterruptedException`。

```
public class InterruptDemo {
    public static void main(String[] args) throws InterruptedException {
        Thread thread = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                System.out.println("Running...");
                try {
                    Thread.sleep(500); // sleep()会响应中断
                } catch (InterruptedException e) {
                    System.out.println("Interrupted during sleep!");
                    Thread.currentThread().interrupt(); // 重置中断标志
                }
            }
            System.out.println("Thread exited");
        });

        thread.start();
        Thread.sleep(2000);
        thread.interrupt(); // 发送中断信号
    }
}
```

- ​**关键点**​：
    - `interrupt()`仅设置标志位，线程需主动检查（如`isInterrupted()`）或通过阻塞方法（如`sleep()`）抛出`InterruptedException`响应。
    - 若线程在阻塞中被中断，会抛出`InterruptedException`并清除中断标志，需手动重置。

---

### 0.1.5 总结

- ​**Thread vs Runnable**​：优先用`Runnable`实现任务解耦。
- ​**`start()` vs `run()`**​：`start()`启动新线程，`run()`同步执行。
- ​**生命周期**​：新建 → 就绪 → 运行 → (阻塞) → 终止。
- ​**操作要点**​：
    - `sleep()`：定时阻塞，不释放锁。
    - `join()`：强制等待线程结束。
    - `yield()`：提示让出CPU，行为不确定。
    - `interrupt()`：协作式中断，需线程主动响应。

> 完整代码可参考[Thread类文档](https://docs.oracle.com/javase/8/docs/api/java/lang/Thread.html)。实际开发中建议使用`ExecutorService`线程池替代直接操作Thread。