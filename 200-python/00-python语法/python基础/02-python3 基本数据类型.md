Python 3 中有六个标准的数据类型：
- Numbers（数字）
- String（字符串）
- List（列表）
- Tuple（元组）
- Sets（集合）
- Dictionaries（字典）
# 1 Numbers（数字）

Python 3 支持 int（整型）、float（浮点型）、bool（布尔型）、complex（复数）。

数值类型的赋值和计算都是很直观的，就像大多数语言一样。内置的 type() 函数可以用来查询变量所指的对象类型。

```
>>> a, b, c, d = 20, 5.5, True, 4+3j
>>> print(type(a), type(b), type(c), type(d))
<class 'int'><class 'float'><class 'bool'><class 'complex'>
```

此外还可以用isinstance来判断：
```
>>>a=111
>>>isinstance(a,int)
True
>>>
```

**isinstance和type的区别在于：**
- type（）不会认为子类是一种父类类型。
- isinstance（）会认为子类是一种父类类型。
```
>>> class A:
...     pass
... 
>>> class B(A):
...     pass
... 
>>> isinstance(A(), A)
True
>>> type(A()) == A 
True
>>> isinstance(B(), A)
True
>>> type(B()) == A
False
```

## 1.1 del 语句删除一些对象引用
del 语句的语法是：
```
del var1[,var2[,var3[....,varN]]]
```

您可以通过使用 del 语句删除单个或多个对象。例如：
```
del var
del var_a, var_b
```

## 1.2 数值运算：
```
>>> 5 + 4  # 加法
9
>>> 4.3 - 2 # 减法
2.3
>>> 3 * 7  # 乘法
21
>>> 2 / 4  # 除法，得到一个浮点数
0.5
>>> 2 // 4 # 除法，得到一个整数
0
>>> 17 % 3 # 取余 
2
>>> 2 ** 5 # 乘方
32
```

## 1.3 注意
- 1、Python 可以同时为多个变量赋值，如 a, b = 1, 2。
- 2、一个变量可以通过赋值指向不同类型的对象。
- 3、数值的除法（/）总是返回一个浮点数，要获取整数使用​`//`​操作符。
- 4、在混合计算时，Python 会把整型转换成为浮点数。

# 2 String（字符串）

Python 中的字符串 str 用单引号(' ')或双引号 (" ") 括起来，同时使用反斜杠 (\) 转义特殊字符。
```
>>> s = 'Yes,he doesn\'t'
>>> print(s, type(s), len(s))
Yes,he doesn't  <class 'str'> 14
```

如果你不想让反斜杠发生转义，可以在字符串前面添加一个 r，表示原始字符串：

```
>>> print('C:\some\name')
C:\some
ame
>>> print(r'C:\some\name')
C:\some\name

```

# 3 List（列表）
列表是写在方括号之间、用逗号分隔开的元素列表。列表中元素的类型可以不相同：
```
>>> a = ['him', 25, 100, 'her']
>>> print(a)
['him', 25, 100, 'her']

```

列表还支持串联操作，使用 + 操作符：
```
>>> a = [1, 2, 3, 4, 5]
>>> a + [6, 7, 8]
[1, 2, 3, 4, 5, 6, 7, 8]

```

与 Python 字符串不一样的是，列表中的元素是可以改变的：
```
>>> a = [1, 2, 3, 4, 5, 6]
>>> a[0] = 9
>>> a[2:5] = [13, 14, 15]
>>> a
[9, 2, 13, 14, 15, 6]
>>> a[2:5] = []   # 删除
>>> a
[9, 2, 6]

```

List 内置了有很多方法，例如 append()、pop() 等等

# 4 Tuple（元组）
元组（tuple）与列表类似，不同之处在于元组的元素不能修改。元组写在小括号里，元素之间用逗号隔开。
元组中的元素类型也可以不相同：
```
>>> a = (1991, 2014, 'physics', 'math')
>>> print(a, type(a), len(a))
(1991, 2014, 'physics', 'math') <class 'tuple'> 4
```

元组与字符串类似，可以被索引且下标索引从 0 开始，也可以进行截取/切片（看上面，这里不再赘述）。
其实，可以把字符串看作一种特殊的元组。
```
>>> tup = (1, 2, 3, 4, 5, 6)
>>> print(tup[0], tup[1:5])
1 (2, 3, 4, 5)
>>> tup[0] = 11  # 修改元组元素的操作是非法的

```

虽然 tuple 的元素不可改变，但它可以包含可变的对象，比如 list 列表。

构造包含 0 个或 1 个元素的 tuple 是个特殊的问题，所以有一些额外的语法规则：
```
tup1 = () # 空元组
tup2 = (20,) # 一个元素，需要在元素后添加逗号

```

另外，元组也支持用 + 操作符：
```
>>> tup1, tup2 = (1, 2, 3), (4, 5, 6)
>>> print(tup1+tup2)
(1, 2, 3, 4, 5, 6)

```

string、list 和 tuple 都属于 sequence（序列）。

注意：
- 1、与字符串一样，元组的元素不能修改。
- 2、元组也可以被索引和切片，方法都是一样的。
- 3、注意构造包含 0 或 1 个元素的元组的特殊语法规则。
- 4、元组也可以使用 + 操作符进行拼接。

# 5 Sets（集合）

集合（set）是一个无序不重复元素的集。
基本功能是进行成员关系测试和消除重复元素。
可以使用大括号 或者 set() 函数创建 set 集合，注意：创建一个空集合必须用 set() 而不是 { }，因为{ }是用来创建一个空字典。
```
>>> student = {'Tom', 'Jim', 'Mary', 'Tom', 'Jack', 'Rose'}
>>> print(student)   # 重复的元素被自动去掉
{'Jim', 'Jack', 'Mary', 'Tom', 'Rose'}
>>> 'Rose' in student  # membership testing（成员测试）
True
>>> # set可以进行集合运算
... 
>>> a = set('abracadabra')
>>> b = set('alacazam')
>>> a
{'a', 'b', 'c', 'd', 'r'}
>>> a - b     # a和b的差集
{'b', 'd', 'r'}
>>> a | b     # a和b的并集
{'l', 'm', 'a', 'b', 'c', 'd', 'z', 'r'}
>>> a & b     # a和b的交集
{'a', 'c'}
>>> a ^ b     # a和b中不同时存在的元素
{'l', 'm', 'b', 'd', 'z', 'r'}

```

# 6 Dictionaries（字典）
字典（dictionary）是 Python 中另一个非常有用的内置数据类型。
字典是一种映射类型（mapping type），它是一个无序的键值对（key-value）集合。
关键字（key）必须使用不可变类型，也就是说list和包含可变类型的 tuple 不能做关键字。
在同一个字典中，关键字（key）必须互不相同。
```
>>> dic = {}  # 创建空字典
>>> tel = {'Jack':1557, 'Tom':1320, 'Rose':1886}
>>> tel
{'Tom': 1320, 'Jack': 1557, 'Rose': 1886}
>>> tel['Jack']   # 主要的操作：通过key查询
1557
>>> del tel['Rose']  # 删除一个键值对
>>> tel['Mary'] = 4127  # 添加一个键值对
>>> tel
{'Tom': 1320, 'Jack': 1557, 'Mary': 4127}
>>> list(tel.keys())  # 返回所有key组成的list
['Tom', 'Jack', 'Mary']
>>> sorted(tel.keys()) # 按key排序
['Jack', 'Mary', 'Tom']
>>> 'Tom' in tel       # 成员测试
True
>>> 'Mary' not in tel  # 成员测试
False

```

构造函数 dict() 直接从键值对 sequence 中构建字典，当然也可以进行推导，如下：
```
>>> dict([('sape', 4139), ('guido', 4127), ('jack', 4098)])
{'jack': 4098, 'sape': 4139, 'guido': 4127}

>>> {x: x**2 for x in (2, 4, 6)}
{2: 4, 4: 16, 6: 36}

>>> dict(sape=4139, guido=4127, jack=4098)
{'jack': 4098, 'sape': 4139, 'guido': 4127}
```

另外，字典类型也有一些内置的函数，例如 clear()、keys()、values() 等。

注意：
- 1、字典是一种映射类型，它的元素是键值对。
- 2、字典的关键字必须为不可变类型，且不能重复。
- 3、创建空字典使用 { }。