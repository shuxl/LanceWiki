# 1 Java内存模型概念或介绍

**本文重点：**
- 理解Java内存模型（JMM）的基本概念
- 掌握内存可见性和有序性的问题
- 熟悉volatile关键字的内存语义
- 了解synchronized的内存语义
- 掌握final关键字的内存语义
- 理解happens-before关系和内存屏障

## 1.1 什么是Java内存模型

Java内存模型（Java Memory Model，JMM）是Java虚拟机规范中定义的一种规范，用来屏蔽各种硬件和操作系统的内存访问差异，让Java程序在各种平台上都能达到一致的内存访问效果。

## 1.2 JMM的核心概念

1. **主内存（Main Memory）**：所有线程共享的内存区域
2. **工作内存（Working Memory）**：每个线程私有的内存区域
3. **内存可见性**：一个线程对共享变量的修改能够及时被其他线程看到
4. **有序性**：程序执行的顺序符合代码的先后顺序

## 1.3 内存模型的问题

```java
public class MemoryModelProblem {
    private boolean flag = false;
    private int value = 0;
    
    // 线程A执行
    public void write() {
        value = 1;        // 1
        flag = true;      // 2
    }
    
    // 线程B执行
    public void read() {
        if (flag) {       // 3
            System.out.println(value); // 4
        }
    }
}
```

在上面的代码中，由于重排序的存在，线程B可能看到`flag=true`但`value=0`的情况。

# 2 内存可见性

## 2.1 可见性问题

```java
public class VisibilityProblem {
    private boolean running = true;
    
    public void start() {
        Thread thread = new Thread(() -> {
            while (running) {
                // 这个循环可能永远不会退出
                // 因为running的值可能不会被及时刷新到工作内存
            }
        });
        thread.start();
    }
    
    public void stop() {
        running = false; // 这个修改可能不会被线程看到
    }
}
```

## 2.2 volatile解决可见性

```java
public class VolatileVisibility {
    private volatile boolean running = true; // 使用volatile保证可见性
    
    public void start() {
        Thread thread = new Thread(() -> {
            while (running) {
                // 现在循环会正常退出
            }
        });
        thread.start();
    }
    
    public void stop() {
        running = false; // 修改会立即被其他线程看到
    }
}
```

## 2.3 synchronized解决可见性

```java
public class SynchronizedVisibility {
    private boolean running = true;
    private final Object lock = new Object();
    
    public void start() {
        Thread thread = new Thread(() -> {
            while (true) {
                synchronized (lock) {
                    if (!running) {
                        break;
                    }
                }
            }
        });
        thread.start();
    }
    
    public void stop() {
        synchronized (lock) {
            running = false;
        }
    }
}
```

# 3 volatile关键字

## 3.1 volatile的内存语义

```java
public class VolatileExample {
    private volatile int value = 0;
    
    public void write() {
        value = 1; // 写操作
    }
    
    public int read() {
        return value; // 读操作
    }
}
```

volatile的内存语义：
1. **可见性**：对volatile变量的写操作会立即刷新到主内存
2. **有序性**：禁止指令重排序
3. **原子性**：对单个volatile变量的读写是原子的

## 3.2 volatile的局限性

```java
public class VolatileLimitation {
    private volatile int counter = 0;
    
    public void increment() {
        counter++; // 这个操作不是原子的
        // 等价于：int temp = counter; temp = temp + 1; counter = temp;
    }
    
    // 正确的做法
    private final AtomicInteger atomicCounter = new AtomicInteger(0);
    
    public void atomicIncrement() {
        atomicCounter.incrementAndGet(); // 原子操作
    }
}
```

## 3.3 volatile的使用场景

```java
public class VolatileUsage {
    // 1. 状态标志
    private volatile boolean shutdown = false;
    
    // 2. 双重检查锁定
    private volatile static Instance instance;
    
    public static Instance getInstance() {
        if (instance == null) {
            synchronized (Instance.class) {
                if (instance == null) {
                    instance = new Instance();
                }
            }
        }
        return instance;
    }
    
    // 3. 一次性安全发布
    private volatile Map<String, String> config;
    
    public void initConfig() {
        Map<String, String> temp = new HashMap<>();
        // 初始化配置
        config = temp; // volatile保证可见性
    }
}
```

# 4 synchronized关键字

## 4.1 synchronized的内存语义

```java
public class SynchronizedMemorySemantics {
    private int value = 0;
    private final Object lock = new Object();
    
    public void write() {
        synchronized (lock) {
            value = 1; // 写操作
        }
        // 释放锁时，会将工作内存中的变量刷新到主内存
    }
    
    public int read() {
        synchronized (lock) {
            return value; // 读操作
        }
        // 获取锁时，会从主内存中读取最新的值
    }
}
```

synchronized的内存语义：
1. **可见性**：进入synchronized块时，会从主内存读取最新值；退出时，会将修改刷新到主内存
2. **有序性**：synchronized块内的代码不会被重排序到synchronized块外
3. **原子性**：synchronized块内的代码是原子执行的

## 4.2 synchronized的happens-before关系

```java
public class SynchronizedHappensBefore {
    private int a = 0;
    private int b = 0;
    private final Object lock = new Object();
    
    public void write() {
        a = 1; // 1
        synchronized (lock) {
            b = 1; // 2
        }
    }
    
    public void read() {
        synchronized (lock) {
            int tempB = b; // 3
        }
        int tempA = a; // 4
    }
}
```

在上面的代码中：
- 操作1 happens-before 操作2
- 操作3 happens-before 操作4
- 由于synchronized的happens-before关系，如果线程B看到`b=1`，那么一定能看到`a=1`

# 5 final关键字

## 5.1 final的内存语义

```java
public class FinalMemorySemantics {
    private final int value;
    private final Map<String, String> config;
    
    public FinalMemorySemantics() {
        value = 42; // final字段的初始化
        config = new HashMap<>(); // final引用字段的初始化
        config.put("key", "value");
    }
    
    public int getValue() {
        return value; // 读取final字段
    }
    
    public Map<String, String> getConfig() {
        return config; // 读取final引用
    }
}
```

final的内存语义：
1. **可见性**：final字段的初始化对其他线程立即可见
2. **有序性**：final字段的初始化不会被重排序到构造函数外
3. **不可变性**：final字段的值不能被修改

## 5.2 final字段的重排序规则

```java
public class FinalReordering {
    private int a;
    private final int b;
    private static FinalReordering instance;
    
    public FinalReordering() {
        a = 1; // 1
        b = 2; // 2
    }
    
    public static void write() {
        instance = new FinalReordering(); // 3
    }
    
    public static void read() {
        FinalReordering temp = instance; // 4
        if (temp != null) {
            int tempA = temp.a; // 5
            int tempB = temp.b; // 6
        }
    }
}
```

重排序规则：
- 操作1和操作2不能重排序到操作3之后
- 操作4不能重排序到操作5和操作6之后
- 如果线程B看到`tempB=2`，那么一定能看到`tempA=1`

# 6 happens-before关系

## 6.1 happens-before的定义

如果操作A happens-before 操作B，那么操作A的结果对操作B可见。

## 6.2 天然的happens-before关系

```java
public class HappensBeforeRules {
    private int value = 0;
    private volatile boolean flag = false;
    
    public void demonstrateRules() {
        // 1. 程序顺序规则：同一线程内，前面的操作happens-before后面的操作
        value = 1; // 1
        flag = true; // 2
        
        // 2. volatile规则：对volatile变量的写happens-before对它的读
        flag = true; // 3
        boolean temp = flag; // 4
        
        // 3. 传递性规则：如果A happens-before B，B happens-before C，那么A happens-before C
        value = 1; // 5
        flag = true; // 6
        boolean temp2 = flag; // 7
        // 5 happens-before 7
    }
}
```

## 6.3 synchronized的happens-before关系

```java
public class SynchronizedHappensBefore {
    private int a = 0;
    private int b = 0;
    private final Object lock = new Object();
    
    public void thread1() {
        a = 1; // 1
        synchronized (lock) {
            b = 1; // 2
        }
    }
    
    public void thread2() {
        synchronized (lock) {
            int tempB = b; // 3
        }
        int tempA = a; // 4
    }
}
```

synchronized的happens-before关系：
- 释放锁 happens-before 获取同一个锁
- 如果线程2看到`tempB=1`，那么一定能看到`tempA=1`

# 7 内存屏障

## 7.1 内存屏障的类型

```java
public class MemoryBarriers {
    // LoadLoad屏障：确保Load1数据的装载先于Load2及后续装载指令
    // StoreStore屏障：确保Store1数据对其他处理器可见先于Store2及后续存储指令
    // LoadStore屏障：确保Load1数据装载先于Store2及后续的存储指令
    // StoreLoad屏障：确保Store1数据对其他处理器变得可见先于Load2及后续装载指令
    
    private volatile int value = 0;
    
    public void write() {
        value = 1; // StoreStore屏障 + StoreLoad屏障
    }
    
    public int read() {
        return value; // LoadLoad屏障 + LoadStore屏障
    }
}
```

## 7.2 volatile的内存屏障

```java
public class VolatileBarriers {
    private volatile int a = 0;
    private int b = 0;
    private int c = 0;
    
    public void write() {
        b = 1; // 1
        a = 1; // 2: StoreStore屏障
        c = 1; // 3
    }
    
    public void read() {
        int tempA = a; // 4: LoadLoad屏障
        int tempB = b; // 5
        int tempC = c; // 6
    }
}
```

volatile的内存屏障：
- 写操作前插入StoreStore屏障，后插入StoreLoad屏障
- 读操作前插入LoadLoad屏障，后插入LoadStore屏障

# 8 双重检查锁定

## 8.1 错误的实现

```java
public class DoubleCheckLocking {
    private static Instance instance;
    
    public static Instance getInstance() {
        if (instance == null) { // 第一次检查
            synchronized (DoubleCheckLocking.class) {
                if (instance == null) { // 第二次检查
                    instance = new Instance(); // 问题在这里
                }
            }
        }
        return instance;
    }
}
```

问题分析：
```java
// instance = new Instance(); 可能被重排序为：
memory = allocate(); // 1. 分配内存空间
instance = memory;   // 3. 设置instance指向内存空间
ctorInstance(memory); // 2. 初始化对象
```

## 8.2 正确的实现

```java
public class CorrectDoubleCheckLocking {
    private volatile static Instance instance; // 使用volatile
    
    public static Instance getInstance() {
        if (instance == null) {
            synchronized (CorrectDoubleCheckLocking.class) {
                if (instance == null) {
                    instance = new Instance();
                }
            }
        }
        return instance;
    }
}
```

## 8.3 基于类初始化的实现

```java
public class ClassBasedSingleton {
    private static class InstanceHolder {
        public static Instance instance = new Instance();
    }
    
    public static Instance getInstance() {
        return InstanceHolder.instance; // 触发类初始化
    }
}
```

# 9 内存模型的实践

## 9.1 线程安全的单例模式

```java
public class ThreadSafeSingleton {
    // 方法1：使用volatile
    private volatile static ThreadSafeSingleton instance;
    
    public static ThreadSafeSingleton getInstance() {
        if (instance == null) {
            synchronized (ThreadSafeSingleton.class) {
                if (instance == null) {
                    instance = new ThreadSafeSingleton();
                }
            }
        }
        return instance;
    }
    
    // 方法2：使用静态内部类
    private static class SingletonHolder {
        private static final ThreadSafeSingleton INSTANCE = new ThreadSafeSingleton();
    }
    
    public static ThreadSafeSingleton getInstance2() {
        return SingletonHolder.INSTANCE;
    }
}
```

## 9.2 线程安全的延迟初始化

```java
public class ThreadSafeLazyInitialization {
    private volatile Map<String, String> config;
    
    public Map<String, String> getConfig() {
        Map<String, String> temp = config;
        if (temp == null) {
            synchronized (this) {
                temp = config;
                if (temp == null) {
                    temp = new HashMap<>();
                    // 初始化配置
                    config = temp;
                }
            }
        }
        return temp;
    }
}
```

# 10 Java内存模型关联的其它知识

- [线程基础](501-线程基础.md) - 线程的基本概念和操作
- [锁机制](502-锁机制.md) - 线程同步和互斥机制
- [并发容器](503-并发容器.md) - 线程安全的集合类
- [线程池](504-线程池.md) - 线程的复用和管理
- [Java内存模型 JMM](../old/100-Java基础-old/201%20Java内存模型%20JMM.md) - JMM的详细说明
- [Java并发理论基础](../old/100-Java基础-old/多线程/A1%20Java并发-理论基础.md) - 并发编程的理论基础
