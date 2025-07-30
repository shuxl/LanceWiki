# 1 String的线程安全
+ `String由于有final修饰，是immutable（不可变）的，安全性是简单而纯粹的`怎么理解？
	+ 任何尝试修改这个对象的方法，例如substring、toUpperCase等，都会返回一个新的String对象，而不是修改原有的对象
+ StringBuffer是线程安全类型的，那为何StringBuilder不能保障线程安全
	+ synchronized 关键字加在了方法上