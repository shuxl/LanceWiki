锁。MyISAM和MEMORY存储引擎采用的是表级锁（table-level locking）；BDB存储引擎采用的是页面锁（page-level locking），但也支持表级锁；InnoDB存储引擎既支持行级锁（row-level locking），也支持表级锁，但默认情况下是采用行级锁。 
MyISAM表锁。表共享读锁，表独占写锁。读时，后续写操作被互斥，但是可以同步读。写时，其它线程读写都被锁。
间隙锁：无索引可以加时，走全表锁。有索引可以加时，在索引区间设置锁。
MVVC（多版本并发控制）：行数据的快照，关联事务的id。
    当前事务内的更新，可以读到；版本未提交，不能读到；版本已提交，但是却在快照创建后提交的，不能读到；版本已提交，且是在快照创建前提交的，可以读到；
Mysql事务隔离实现原理。
    串行化隔离：读加共享锁，写的时候加排它锁。
    可重复读：事务开始时生成全局的快照。
    读提交：每次执行语句时，都重新生成一次快照。

Mysql乐观锁和悲观锁
    定义：
        1、乐观锁：顾名思义，对每次的数据操作都保持乐观的态度，不担心数据会被修改，所以不会对数据进行上锁。由于数据没有上锁，这就存在数据会被多人读写的情况。所以每次修改数据的时候需要对数据进行判断是否被修改过。
        2、悲观锁：与乐观锁相反，对每次的数据操作都保存悲观的态度，总是担心数据会被修改，所以在自己操作的时候会对数据上锁，防止在自己操作的时候被他人同时操作导致更新丢失。
    场景：
        1、乐观锁：由于乐观锁的不上锁特性，所以在性能方面要比悲观锁好，比较适合用在DB的读大于写的业务场景。
        2、悲观锁：对于每一次数据修改都要上锁，如果在DB读取需要比较大的情况下有线程在执行数据修改操作会导致读操作全部被挂载起来，等修改线程释放了锁才能读到数据，体验极差。所以比较适合用在DB写大于读的情况。
    实现：
        1、乐观锁：目前比较常用的有两种方式，第一种是使用版本号或者时间戳。在表中加个version或updatetime字段，在每次更新操作时对此一下该字段，如果一致则更新数据，数据不等则放弃本次修改，根据实际业务需求做相应的处理。第二种是CAS方式，即Java中的compareAndSwap。CAS操作涉及到三个操作数，内存值（valueOffSet）、期望值（expect)、更新值（update）。当内存值与期望值一致时就会更新数据，反之不操作。
        2、悲观锁：一、数据库实现方式，使用数据库的读锁、写锁、行锁等实现进程的悬挂阻塞等当前操作完成后才能进行下一个操作。二、在Java里面可以使用synchronize实现悲观锁。
