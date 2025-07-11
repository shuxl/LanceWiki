# 1 jvm调优的时机
不得不考虑进行JVM调优的是那些情况呢？
+ Heap内存（老年代）持续上涨达到设置的最大内存值；
+ Full GC 次数频繁；
+ GC 停顿时间过长（超过1秒）；
+ 应用出现OutOfMemory 等内存异常；
+ 应用中有使用本地缓存且占用大量内存空间；
+ 系统吞吐量与响应性能不高或下降。

# 2 JVM调优的目标
吞吐量、延迟、内存占用三者类似CAP，构成了一个不可能三角，只能选择其中两个进行调优，不可三者兼得。  
+ 延迟：GC低停顿和GC低频率；
+ 低内存占用；
+ 高吞吐量;

选择了其中两个，必然会会以牺牲另一个为代价。

下面展示了一些JVM调优的量化目标参考实例：
+ Heap 内存使用率 <= 70%;
+ Old generation内存使用率<= 70%;
+ avgpause <= 1秒;【?avg是啥】
+ Full gc 次数0 或 avg pause interval >= 24小时 ;

注意：不同应用的JVM调优量化目标是不一样的。

# 3 JVM调优的步骤
一般情况下，JVM调优可通过以下步骤进行：
+ 分析系统系统运行情况：分析GC日志及dump文件，判断是否需要优化，确定瓶颈问题点；
+ 确定JVM调优量化目标；
+ 确定JVM调优参数（根据历史JVM参数来调整）；
+ 依次确定调优内存、延迟、吞吐量等指标；
+ 对比观察调优前后的差异；
+ 不断的分析和调整，直到找到合适的JVM参数配置；
+ 找到最合适的参数，将这些参数应用到所有服务器，并进行后续跟踪。

以上操作步骤中，某些步骤是需要多次不断迭代完成的。一般是从满足程序的内存使用需求开始的，之后是时间延迟的要求，最后才是吞吐量的要求，要基于这个步骤来不断优化，每一个步骤都是进行下一步的基础，不可逆行。

# 4 JVM 核心参数
下面来看一下JDK的JVM参数。

## 4.1 5.1、基本参数 ##

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-Xms</td> 
   <td>初始堆大小</td> 
   <td>内存的1/64</td> 
   <td>默认(MinHeapFreeRatio参数可以调整)空余堆内存小于40%时，JVM就会增大堆直到-Xmx的最大限制.</td> 
  </tr> 
  <tr> 
   <td>-Xmx</td> 
   <td>最大堆大小</td> 
   <td>内存的1/4</td> 
   <td>默认(MaxHeapFreeRatio参数可以调整)空余堆内存大于70%时，JVM会减少堆直到 -Xms的最小限制</td> 
  </tr> 
  <tr> 
   <td>-Xmn</td> 
   <td>年轻代大小</td> 
   <td></td> 
   <td><strong>注意</strong>：此处的大小是（eden+ 2 survivor space).与jmap -heap中显示的New gen是不同的。 整个堆大小=年轻代大小 + 年老代大小 + 持久代大小. 增大年轻代后,将会减小年老代大小.此值对系统性能影响较大,Sun官方推荐配置为整个堆的3/8</td> 
  </tr> 
  <tr> 
   <td>-XX:NewSize</td> 
   <td>设置年轻代大小</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:MaxNewSize</td> 
   <td>年轻代最大值</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:PermSize</td> 
   <td>设置持久代(perm gen)初始值</td> 
   <td>内存的1/64</td> 
   <td>JDK1.8以前</td> 
  </tr> 
  <tr> 
   <td>-XX:MaxPermSize</td> 
   <td>设置持久代最大值</td> 
   <td>内存的1/4</td> 
   <td>JDK1.8以前</td> 
  </tr> 
  <tr> 
   <td>-Xss</td> 
   <td>每个线程的堆栈大小</td> 
   <td></td> 
   <td>JDK5.0以后每个线程堆栈大小为1M,以前每个线程堆栈大小为256K.更具应用的线程所需内存大小进行 调整.在相同物理内存下,减小这个值能生成更多的线程.但是操作系统对一个进程内的线程数还是有限制的,不能无限生成,经验值在3000~5000左右 一般小的应用， 如果栈不是很深， 应该是128k够用的 大的应用建议使用256k。这个选项对性能影响比较大，需要严格的测试。（校长） 和threadstacksize选项解释很类似,官方文档似乎没有解释,在论坛中有这样一句话:"” -Xss is translated in a VM flag named ThreadStackSize” 一般设置这个值就可以了。</td> 
  </tr> 
  <tr> 
   <td>-<em>XX:ThreadStackSize</em></td> 
   <td>Thread Stack Size</td> 
   <td></td> 
   <td>(0 means use default stack size) [Sparc: 512; Solaris x86: 320 (was 256 prior in 5.0 and earlier); Sparc 64 bit: 1024; Linux amd64: 1024 (was 0 in 5.0 and earlier); all others 0.]</td> 
  </tr> 
  <tr> 
   <td>-XX:NewRatio</td> 
   <td>年轻代(包括Eden和两个Survivor区)与年老代的比值(除去持久代)</td> 
   <td></td> 
   <td>-XX:NewRatio=4表示年轻代与年老代所占比值为1:4,年轻代占整个堆栈的1/5 Xms=Xmx并且设置了Xmn的情况下，该参数不需要进行设置。</td> 
  </tr> 
  <tr> 
   <td>-XX:SurvivorRatio</td> 
   <td>Eden区与Survivor区的大小比值</td> 
   <td></td> 
   <td>设置为8,则两个Survivor区与一个Eden区的比值为2:8,一个Survivor区占整个年轻代的1/10</td> 
  </tr> 
  <tr> 
   <td>-XX:LargePageSizeInBytes</td> 
   <td>内存页的大小不可设置过大， 会影响Perm的大小</td> 
   <td></td> 
   <td>=128m</td> 
  </tr> 
  <tr> 
   <td>-XX:+UseFastAccessorMethods</td> 
   <td>原始类型的快速优化</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+DisableExplicitGC</td> 
   <td>关闭System.gc()</td> 
   <td></td> 
   <td>这个参数需要严格的测试</td> 
  </tr> 
  <tr> 
   <td>-XX:+ExplicitGCInvokesConcurrent</td> 
   <td>关闭System.gc()</td> 
   <td>disabled</td> 
   <td>Enables invoking of concurrent GC by using the System.gc() request. This option is disabled by default and can be enabled only together with the -XX:+UseConcMarkSweepGC option.</td> 
  </tr> 
  <tr> 
   <td>-XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses</td> 
   <td>关闭System.gc()</td> 
   <td>disabled</td> 
   <td>Enables invoking of concurrent GC by using the System.gc() request and unloading of classes during the concurrent GC cycle. This option is disabled by default and can be enabled only together with the -XX:+UseConcMarkSweepGC option.</td> 
  </tr> 
  <tr> 
   <td>-XX:MaxTenuringThreshold</td> 
   <td>垃圾最大年龄</td> 
   <td></td> 
   <td>如果设置为0的话,则年轻代对象不经过Survivor区,直接进入年老代. 对于年老代比较多的应用,可以提高效率.如果将此值设置为一个较大值,则年轻代对象会在Survivor区进行多次复制,这样可以增加对象再年轻代的存活 时间,增加在年轻代即被回收的概率 该参数只有在串行GC时才有效.</td> 
  </tr> 
  <tr> 
   <td>-XX:+AggressiveOpts</td> 
   <td>加快编译</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+UseBiasedLocking</td> 
   <td>锁机制的性能改善</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-Xnoclassgc</td> 
   <td>禁用垃圾回收</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:SoftRefLRUPolicyMSPerMB</td> 
   <td>每兆堆空闲空间中SoftReference的存活时间</td> 
   <td>1s</td> 
   <td>softly reachable objects will remain alive for some amount of time after the last time they were referenced. The default value is one second of lifetime per free megabyte in the heap</td> 
  </tr> 
  <tr> 
   <td>-XX:PretenureSizeThreshold</td> 
   <td>对象超过多大是直接在旧生代分配</td> 
   <td>0</td> 
   <td>单位字节 新生代采用Parallel Scavenge GC时无效 另一种直接在旧生代分配的情况是大的数组对象,且数组中无外部引用对象.</td> 
  </tr> 
  <tr> 
   <td>-XX:TLABWasteTargetPercent</td> 
   <td>TLAB占eden区的百分比</td> 
   <td>1%</td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+<em>CollectGen0First</em></td> 
   <td>FullGC时是否先YGC</td> 
   <td>false</td> 
   <td></td> 
  </tr> 
 </tbody> 
</table>

**Jdk7版本的主要参数**

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-XX:PermSize</td> 
   <td>设置持久代</td> 
   <td></td> 
   <td>Jdk7版本及以前版本</td> 
  </tr> 
  <tr> 
   <td>-XX:MaxPermSize</td> 
   <td>设置最大持久代</td> 
   <td></td> 
   <td>Jdk7版本及以前版本</td> 
  </tr> 
 </tbody> 
</table>

**Jdk8版本的重要特有参数**

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-XX:MetaspaceSize</td> 
   <td>元空间大小</td> 
   <td></td> 
   <td>Jdk8版本</td> 
  </tr> 
  <tr> 
   <td>-XX:MaxMetaspaceSize</td> 
   <td>最大元空间</td> 
   <td></td> 
   <td>Jdk8版本</td> 
  </tr> 
 </tbody> 
</table>

## 4.2 5.2、并行收集器相关参数 ##

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-XX:+UseParallelGC</td> 
   <td>Full GC采用parallel MSC (此项待验证)</td> 
   <td></td> 
   <td>选择垃圾收集器为并行收集器.此配置仅对年轻代有效.即上述配置下,年轻代使用并发收集,而年老代仍旧使用串行收集.(此项待验证)</td> 
  </tr> 
  <tr> 
   <td>-XX:+UseParNewGC</td> 
   <td>设置年轻代为并行收集</td> 
   <td></td> 
   <td>可与CMS收集同时使用 JDK5.0以上,JVM会根据系统配置自行设置,所以无需再设置此值</td> 
  </tr> 
  <tr> 
   <td>-XX:ParallelGCThreads</td> 
   <td>并行收集器的线程数</td> 
   <td></td> 
   <td>此值最好配置与处理器数目相等 同样适用于CMS</td> 
  </tr> 
  <tr> 
   <td>-XX:+UseParallelOldGC</td> 
   <td>年老代垃圾收集方式为并行收集(Parallel Compacting)</td> 
   <td></td> 
   <td>这个是JAVA 6出现的参数选项</td> 
  </tr> 
  <tr> 
   <td>-XX:MaxGCPauseMillis</td> 
   <td>每次年轻代垃圾回收的最长时间(最大暂停时间)</td> 
   <td></td> 
   <td>如果无法满足此时间,JVM会自动调整年轻代大小,以满足此值.</td> 
  </tr> 
  <tr> 
   <td>-XX:+UseAdaptiveSizePolicy</td> 
   <td>自动选择年轻代区大小和相应的Survivor区比例</td> 
   <td></td> 
   <td>设置此选项后,并行收集器会自动选择年轻代区大小和相应的Survivor区比例,以达到目标系统规定的最低相应时间或者收集频率等,此值建议使用并行收集器时,一直打开.</td> 
  </tr> 
  <tr> 
   <td>-XX:GCTimeRatio</td> 
   <td>设置垃圾回收时间占程序运行时间的百分比</td> 
   <td></td> 
   <td>公式为1/(1+n)</td> 
  </tr> 
  <tr> 
   <td>-XX:+<em>ScavengeBeforeFullGC</em></td> 
   <td>Full GC前调用YGC</td> 
   <td>true</td> 
   <td>Do young generation GC prior to a full GC. (Introduced in 1.4.1.)</td> 
  </tr> 
 </tbody> 
</table>

## 4.3 5.3、CMS相关参数 ##

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-XX:+UseConcMarkSweepGC</td> 
   <td>使用CMS内存收集</td> 
   <td></td> 
   <td>测试中配置这个以后,-XX:NewRatio=4的配置失效了,原因不明.所以,此时年轻代大小最好用-Xmn设置.???</td> 
  </tr> 
  <tr> 
   <td>-XX:+AggressiveHeap</td> 
   <td></td> 
   <td></td> 
   <td>试图是使用大量的物理内存 长时间大内存使用的优化，能检查计算资源（内存， 处理器数量） 至少需要256MB内存 大量的CPU／内存， （在1.4.1在4CPU的机器上已经显示有提升）</td> 
  </tr> 
  <tr> 
   <td>-XX:CMSFullGCsBeforeCompaction</td> 
   <td>多少次后进行内存压缩</td> 
   <td></td> 
   <td>由于并发收集器不对内存空间进行压缩,整理,所以运行一段时间以后会产生"碎片",使得运行效率降低.此值设置运行多少次GC以后对内存空间进行压缩,整理.</td> 
  </tr> 
  <tr> 
   <td>-XX:+CMSParallelRemarkEnabled</td> 
   <td>降低标记停顿</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX+UseCMSCompactAtFullCollection</td> 
   <td>在FULL GC的时候， 对年老代的压缩</td> 
   <td></td> 
   <td>CMS是不会移动内存的， 因此， 这个非常容易产生碎片， 导致内存不够用， 因此， 内存的压缩这个时候就会被启用。 增加这个参数是个好习惯。 可能会影响性能,但是可以消除碎片</td> 
  </tr> 
  <tr> 
   <td>-XX:+UseCMSInitiatingOccupancyOnly</td> 
   <td>使用手动定义初始化定义开始CMS收集</td> 
   <td></td> 
   <td>禁止hostspot自行触发CMS GC</td> 
  </tr> 
  <tr> 
   <td>-XX:CMSInitiatingOccupancyFraction=70</td> 
   <td>使用cms作为垃圾回收 使用70％后开始CMS收集</td> 
   <td>92</td> 
   <td>为了保证不出现promotion failed(见下面介绍)错误,该值的设置需要满足以下公式<strong>CMSInitiatingOccupancyFraction计算公式</strong></td> 
  </tr> 
  <tr> 
   <td>-XX:CMSInitiatingPermOccupancyFraction</td> 
   <td>设置Perm Gen使用到达多少比率时触发</td> 
   <td>92</td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+CMSIncrementalMode</td> 
   <td>设置为增量模式</td> 
   <td></td> 
   <td>用于单CPU情况</td> 
  </tr> 
  <tr> 
   <td>-XX:+CMSClassUnloadingEnabled</td> 
   <td></td> 
   <td></td> 
   <td></td> 
  </tr> 
 </tbody> 
</table>

## 4.4 5.4、辅助信息 ##

<table style="display: table;"> 
 <thead> 
  <tr> 
   <th><strong>参数名称</strong></th> 
   <th><strong>含义</strong></th> 
   <th><strong>默认值</strong></th> 
   <th></th> 
  </tr> 
 </thead> 
 <tbody> 
  <tr> 
   <td>-XX:+PrintGC</td> 
   <td></td> 
   <td></td> 
   <td>输出形式: [GC 118250K-&gt;113543K(130112K), 0.0094143 secs] [Full GC 121376K-&gt;10414K(130112K), 0.0650971 secs]</td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintGCDetails</td> 
   <td></td> 
   <td></td> 
   <td>输出形式:[GC [DefNew: 8614K-&gt;781K(9088K), 0.0123035 secs] 118250K-&gt;113543K(130112K), 0.0124633 secs] [GC [DefNew: 8614K-&gt;8614K(9088K), 0.0000665 secs][Tenured: 112761K-&gt;10414K(121024K), 0.0433488 secs] 121376K-&gt;10414K(130112K), 0.0436268 secs]</td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintGCTimeStamps</td> 
   <td></td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintGC:PrintGCTimeStamps</td> 
   <td></td> 
   <td></td> 
   <td>可与-XX:+PrintGC -XX:+PrintGCDetails混合使用 输出形式:11.851: [GC 98328K-&gt;93620K(130112K), 0.0082960 secs]</td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintGCApplicationStoppedTime</td> 
   <td>打印垃圾回收期间程序暂停的时间.可与上面混合使用</td> 
   <td></td> 
   <td>输出形式:Total time for which application threads were stopped: 0.0468229 seconds</td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintGCApplicationConcurrentTime</td> 
   <td>打印每次垃圾回收前,程序未中断的执行时间.可与上面混合使用</td> 
   <td></td> 
   <td>输出形式:Application time: 0.5291524 seconds</td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintHeapAtGC</td> 
   <td>打印GC前后的详细堆栈信息</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-Xloggc:filename</td> 
   <td>把相关日志信息记录到文件以便分析. 与上面几个配合使用</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintClassHistogram</td> 
   <td>garbage collects before printing the histogram.</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>-XX:+PrintTLAB</td> 
   <td>查看TLAB空间的使用情况</td> 
   <td></td> 
   <td></td> 
  </tr> 
  <tr> 
   <td>XX:+PrintTenuringDistribution</td> 
   <td>查看每次minor GC后新的存活周期的阈值</td> 
   <td></td> 
   <td>Desired survivor size 1048576 bytes, new threshold 7 (max 15) new threshold 7即标识新的存活周期的阈值为7。</td> 
  </tr> 
 </tbody> 
</table>



# 5 引用
https://www.cnblogs.com/three-fighter/p/14644152.html