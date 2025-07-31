# 1 编码
默认情况下，Python 3 源码文件以 UTF-8 编码，所有字符串都是 unicode 字符串。 当然你也可以为源码文件指定不同的编码：
`# -*- coding: cp-1252 -*-`

# 2 注释
Python 中单行注释以 # 开头，多行注释采用三对单引号（'''）或者三对双引号（"""）将注释括起来。

```
#这是单行注释

"""
这是多行注释
这是多行注释
"""
'''
也可以用三个单引号来进行多行注释
'''
```

> 实际上python注释只有一种，就是单行注释，多行注释的这种使用方法类似于java的javadoc，三引号的这种使用方法实际上是用来声明多行长字符串的。

# 3 缩进

Python 最具特色的就是使用缩进来表示代码块。缩进的空格数是可变的，但是**同一个代码块的语句必须包含相同的缩进空格数**。

# 4 标准数据类型

Python 中有六个标准的数据类型：
- Number（数字）
- String（字符串）
- List（列表）
- Tuple（元组）
- Set（集合）
- Dictionary（字典）

Python3 的六个标准数据类型中：
- 不可变数据（3 个）：Number（数字）、String（字符串）、Tuple（元组）；
- 可变数据（3 个）：List（列表）、Dictionary（字典）、Set（集合）。

补充
* [01.01-python3 可变和不可变数据结构的理解](01.01-python3%20可变和不可变数据结构的理解.md)

# 5 类型判断
python可以用type函数来检查一个变量的类型，使用方法如下：

```
>>> x = "W3Cschool"
>>> type(x)
<type 'str'>
>>> x=100
>>> type(x)
<type 'int'>
>>> x=('1','2','3')
>>> type(x)
<type 'tuple'>
>>> x = ['1','2','3']
>>> type(x)
<type 'list'>

```

在脚本代码中的使用：

```
x = "W3Cschool"
print(type(x))
```

# 6 字符串
- Python 中单引号和双引号使用完全相同，但单引号和双引号不能匹配。
- 使用三对引号('''或""")可以囊括一个多行字符串。
- 与其他语言相似，python也使用 '\'作为转义字符
- 自然字符串， 通过在字符串前加 r 或 R。 如 r"this is a line with \n" 则\n会显示，并不是换行。
- Python 允许处理 unicode 字符串，加前缀 u 或 U， 如 u"this is an unicode string"。
- 字符串是不可变的。
- 按字面意义级联字符串，如"this " "is " "string"会被自动转换为this is string。
- 字符串可以用 + 运算符连接在一起，用 * 运算符重复。
- Python 中的字符串有两种索引方式，从左往右以 0 开始，从右往左以 -1 开始。
- Python中的字符串不能改变（详见上一小点的引用）。
- Python 没有单独的字符类型，一个字符就是长度为 1 的字符串。
- 字符串的截取的语法格式如下：变量 **[头下标: 尾下标: 步长]**

```
word = '字符串'
sentence = "这是一个句子。"
paragraph = """这是一个段落，
可以由多行组成"""
```

```
#!/usr/bin/python3
 
str='W3Cschool'
 
print(str)                 # 输出字符串
print(str[0:-1])           # 输出第一个到倒数第二个的所有字符
print(str[0])              # 输出字符串第一个字符
print(str[2:5])            # 输出从第三个开始到第五个的字符
print(str[2:])             # 输出从第三个开始后的所有字符
print(str[1:5:2])          # 输出从第二个开始到第五个且每隔两个的字符
print(str * 2)             # 输出字符串两次
print(str + '你好')         # 连接字符串
 
print('------------------------------')
 
print('hello\nW3Cschool')      # 使用反斜杠(\)+n转义特殊字符
print(r'hello\nW3Cschool')     # 在字符串前面添加一个 r，表示原始字符串，不会发生转义
```

```
>>> print('\n')       # 输出空行
>>> print(r'\n')      # 输出 \n
>>>
\n
```

# 7 输入&等待用户输入

input函数可以用来接受输入，它可以传入一个字符串，当input函数调用的时候，会在控制台打印这个字符串（所以这个字符串通常被用来做输入的提示信息）。

>  input函数会读取输入内容直到读到回车，也就是说，内容输入完毕后要按回车键才能执行。

```
input("这是一个简单的input信息") # 这是一个简单的input样例，他输出input信息并接受一个字符串
x=input("请输入X的值：") # 这是一个常见的input样例，他输出提示信息，然后接受一个字符串并将值传递给一个变量X
print(x) # 打印变量，可以看到输入的x的值
print(type(x)) #查看这个变量的类型

x = int(input("请输入一个数值：")) # 配合强制类型转换，可以将字符串转变为int类型（字符串类型不能参与计算）
# 也可以分步写成：
#x=input("请输入一个数值：") # 接受一个字符串
#x=int(x)   #将x转换为int型

# 这里强制转换也可以转换为其他类型，详细的转换方法请参考基本数据类型的强制转换相关内容

print(x) # 打印变量，可以看到输入的x的值
print(type(x)) #查看这个变量的类型

input("\n\n按下 enter 键后退出。") 
# 其实这里并没有接受任何内容，input函数以enter作为结尾，所以只有输入回车后才会结束input函数
```

以上代码中 ，"\n\n"在结果输出前会输出两个新的空行。一旦用户按下 enter 键时，程序将退出。


# 8 同一行显示多条语句

Python 可以在同一行中使用多条语句，语句之间使用分号 (;) 分割，以下是一个简单的实例：

```
#!/usr/bin/python3
 
import sys; x = 'W3Cschool'; sys.stdout.write(x + '\n')
```

# 9 print 输出
print函数是python的基本输出函数，他可以将变量输出（或者说，打印）到控制台。在第一个python程序中，我们就用到了print函数：

```
#!/usr/bin/python3
print("Hello, World!") #"Hello,World!"是一个字符串变量
str = "Hello,World!"
print(str) #上一种helloworld的另一种写法
```

## 9.1 end 关键字
print 默认输出是换行的，如果要实现不换行需要在变量末尾加上 end=""：

```
#!/usr/bin/python3
 
x="a"
y="b"
# 换行输出
print( x )
print( y )
 
print('---------')
# 不换行输出
print( x, end=" " )
print( y, end=" " )
print()
```

# 10 import 与 from...import

+ 在 Python 用 import 或者 from...import 来导入相应的模块。
+ 将整个模块 (somemodule) 导入，格式为：​ `import somemodule`​
+ 从某个模块中导入某个函数,格式为：​ `from somemodule import somefunction`​
+ 从某个模块中导入多个函数,格式为：​ `from somemodule import firstfunc, secondfunc, thirdfunc`​
+ 将某个模块中的全部函数导入，格式为：​ `from somemodule import *`​

 **导入 sys 模块**
```
 import sys
print('================Python import mode==========================')
print ('命令行参数为:')
for i in sys.argv:
    print (i)
print ('\n python 路径为',sys.path)
```

 **导入 sys 模块的 argv,path 成员**
```
from sys import argv,path  #  导入特定的成员
 
print('================python from import===================================')
print('path:',path) # 因为已经导入path成员，所以此处引用时不需要加sys.path
```

