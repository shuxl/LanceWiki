# 1 类定义
语法格式如下：
``` python
class ClassName:
    <statement-1>
    .
    .
    .
    <statement-N>
```
类实例化后，可以使用其属性，实际上，创建一个类之后，可以通过类名访问其属性。

# 2 类对象
类对象支持两种操作：属性引用和实例化。
属性引用使用和 Python 中所有的属性引用一样的标准语法：**obj.name**。
类对象创建后，类命名空间中所有的命名都是有效属性名。所以如果类定义是这样:
``` python
#!/usr/bin/python3

class MyClass:
    """一个简单的类实例"""
    i = 12345
    def f(self):
        return 'hello world'

# 实例化类
x = MyClass()

# 访问类的属性和方法
print("MyClass 类的属性 i 为：", x.i)
print("MyClass 类的方法 f 输出为：", x.f())
```

实例化类：
```
# 实例化类
x = MyClass()
# 访问类的属性和方法
```
以上创建了一个新的类实例并将该对象赋给局部变量 x。[12.01-Python3 空对象](12.01-Python3%20空对象.md)

执行以上程序输出结果为：
```
MyClass 类的属性 i 为： 12345
MyClass 类的方法 f 输出为： hello world
```

很多类都倾向于将对象创建为有初始状态的。因此类可能会定义一个名为 \_\_init\_\_() 的特殊方法（构造方法），像下面这样：
```
def __init__(self):
    self.data = []
```

类定义了 \_\_init\_\_() 方法的话，类的实例化操作会自动调用 \_\_init\_\_() 方法。所以在下例中，可以这样创建一个新的实例:

# 3 初始化类
很多类都倾向于将对象创建为有初始状态的。因此类可能会定义一个名为 \_\_init\_\_() 的特殊方法（构造方法），像下面这样：
```
def __init__(self):
    self.data = []
```

类定义了 \_\_init\_\_() 方法的话，类的实例化操作会自动调用 \_\_init\_\_() 方法。所以在下例中，可以这样创建一个新的实例:
```
x = MyClass()
```

当然， \_\_init\_\_() 方法可以有参数，参数通过 \_\_init\_\_() 传递到类的实例化操作上。例如:
```
>>> class Complex:
...     def __init__(self, realpart, imagpart):
...         self.r = realpart
...         self.i = imagpart
...
>>> x = Complex(3.0, -4.5)
>>> x.r, x.i
(3.0, -4.5)
```

# 4 类的方法
在类的内部，使用 def 关键字可以为类定义一个方法，与一般函数定义不同，类方法必须包含参数 self，且为第一个参数:
```
#!/usr/bin/python3

#类定义
class people:
    #定义基本属性
    name = ''
    age = 0
    #定义私有属性,私有属性在类外部无法直接进行访问
    __weight = 0
    #定义构造方法
    def __init__(self,n,a,w):
        self.name = n
        self.age = a
        self.__weight = w
    def speak(self):
        print("%s 说: 我 %d 岁。" %(self.name,self.age))

# 实例化类
p = people('W3Cschool',10,30)
p.speak()
```

执行以上程序输出结果为：
```
W3Cschool 说: 我 10 岁。
```

# 5 继承
```
class DerivedClassName(BaseClassName1, BaseClassName2):
    <statement-1>
    .
    .
    .
    <statement-N>
```
需要注意圆括号中基类的顺序，若是基类中有相同的方法名，而在子类使用时未指定，Python 从左至右搜索 即方法在子类中未找到时，从左到右查找基类中是否包含方法。

BaseClassName（示例中的基类名）必须与派生类定义在一个作用域内。除了类，还可以用表达式，基类定义在另一个模块中时这一点非常有用:
```
class DerivedClassName(modname.BaseClassName):
```

```
#!/usr/bin/python3

#类定义
class people:
    #定义基本属性
    name = ''
    age = 0
    #定义私有属性,私有属性在类外部无法直接进行访问
    __weight = 0
    #定义构造方法
    def __init__(self,n,a,w):
        self.name = n
        self.age = a
        self.__weight = w
    def speak(self):
        print("%s 说: 我 %d 岁。" %(self.name,self.age))

#单继承示例
class student(people):
    grade = ''
    def __init__(self,n,a,w,g):
        #调用父类的构函
        people.__init__(self,n,a,w)
        self.grade = g
    #覆写父类的方法
    def speak(self):
        print("%s 说: 我 %d 岁了，我在读 %d 年级"%(self.name,self.age,self.grade))



s = student('ken',10,60,3)
s.speak()
```

```
ken 说: 我 10 岁了，我在读 3 年级
```

# 6 方法重写
如果你的父类方法的功能不能满足你的需求，你可以在子类重写你父类的方法，实例如下：
```
#!/usr/bin/python3

class Parent:        # 定义父类
   def myMethod(self):
      print ('调用父类方法')

class Child(Parent): # 定义子类
   def myMethod(self):
      print ('调用子类方法')

c = Child()          # 子类实例
c.myMethod()         # 子类调用重写方法
```

```
调用子类方法
```

# 7 类属性与方法
### 7.1.1 类的私有属性
**__private_attrs**：两个下划线开头，声明该属性为私有，不能在类地外部被使用或直接访问。在类内部的方法中使用时 **self.__private_attrs**。
### 7.1.2 类的方法
在类地内部，使用 def 关键字可以为类定义一个方法，与一般函数定义不同，类方法必须包含参数 self, 且为第一个参数

### 7.1.3 类的私有方法
**__private_method**：两个下划线开头，声明该方法为私有方法，不能在类地外部调用。在类的内部调用 **slef.__private_methods**。

实例如下：
```
#!/usr/bin/python3

class JustCounter:
    __secretCount = 0  # 私有变量
    publicCount = 0    # 公开变量

    def count(self):
        self.__secretCount += 1
        self.publicCount += 1
        print (self.__secretCount)

counter = JustCounter()
counter.count()
counter.count()
print (counter.publicCount)
print (counter.__secretCount)  # 报错，实例不能访问私有变量
```

执行以上程序输出结果为：
```
1
2
2
Traceback (most recent call last):
  File "test.py", line 16, in <module>
    print (counter.__secretCount)  # 报错，实例不能访问私有变量
AttributeError: 'JustCounter' object has no attribute '__secretCount'
```

### 7.1.4 类的专有方法

- **__init__ :** 构造函数，在生成对象时调用
- **__del__ :** 析构函数，释放对象时使用
- **__repr__ :** 打印，转换
- **__setitem__ :** 按照索引赋值
- **__getitem__:** 按照索引获取值
- **__len__:** 获得长度
- **__cmp__:** 比较运算
- **__call__:** 函数调用
- **__add__:** 加运算
- **__sub__:** 减运算
- **__mul__:** 乘运算
- **__div__:** 除运算
- **__mod__:** 求余运算
- **__pow__:** 乘方