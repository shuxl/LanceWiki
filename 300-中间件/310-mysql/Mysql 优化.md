# 1 索引
+ 建立索引：首先应考虑在 where 及 order by 涉及的列上建立索引
+ 规避不走索引
	+ 避免Where语句进行null判断
		+ `where num is null`
		+ 字段不要用Null填充，Null填充因为也要空间
	+ 避免在 where 子句中使用 != 或 <> 操作符
	+ Or 连接两个不同的字段，用union all替换
	+ not in
	+ like 语法
	+ `%A%`可以改为全文索引
	+ Where 语句中使用参数，`@变量`
	+ Where 语句 `=`左侧是表达式（如：加减法）
	+ Where 语句引入函数
	+ 复合索引字段，最左原则
	+ 类型转换
+ 尽量更好的走索引
	+ in 的范围如果可以改为范围，尽量用范围
+ 走更少的索引
	+ exist 替换in。通常主表是小表的时候
		```
		select num from a where num in(select num from b)
		-- 改为
		select num from a where exists(select 1 from b where num=a.num)
		```
+ 减少Join的基础元素
	+ Where条件相关表，如果分页查询。先分页，再连接其他表
+ 减少回表
	+ 多记录查询时，尽量Select需要用的字段
+ 索引空间。减少非必要的索引，一般不超过6个
+ B+树叶分裂问题。主键索引，使用连续值，不使用无许随机数
+ 能用数字字段尽量用数字。字符型比较需要多次比较，数字只要比较一次
+ 大事务不要用，提高并发
