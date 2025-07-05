# 1 默认的重载
在 Python 中，“重载”通常有两种含义：**函数重载（Function Overloading）和运算符重载（Operator Overloading）**。下面分别介绍这两个概念。

## 1.1 **一、函数重载（Function Overloading）**
在一些语言中（如 Java、C++），函数可以根据参数类型或数量进行重载。但在 Python 中，**不支持传统意义上的函数重载**，即你不能定义多个名字相同、参数不同的函数。
### 1.1.1 **Python 的做法：**
如果你多次定义同名函数，后面定义的会覆盖前面的。

```
def greet(name):
    print("Hello", name)

def greet(name, age):  # 会覆盖上面的 greet(name)
    print(f"Hello {name}, you are {age} years old")

greet("Alice", 25)  # 正常
# greet("Alice")  # 会报错：缺少参数
```

### 1.1.2 **如何实现类似重载的效果？**
可以用 **默认参数** 或 ***args / **kwargs** 实现多种调用方式：

```
def greet(name, age=None):
    if age:
        print(f"Hello {name}, you are {age} years old")
    else:
        print(f"Hello {name}")

greet("Alice")
greet("Bob", 30)
```

也可以使用 functools.singledispatch 进行基于类型的重载：

```
from functools import singledispatch

@singledispatch
def fun(arg):
    print("默认实现")

@fun.register
def _(arg: int):
    print("处理 int 类型")

@fun.register
def _(arg: str):
    print("处理 str 类型")

fun(10)     # 输出：处理 int 类型
fun("hi")   # 输出：处理 str 类型
fun(3.14)   # 输出：默认实现
```

  
## 1.2 **二、运算符重载（Operator Overloading）**
Python 允许你通过实现特殊方法（双下方法，如 __add__、__eq__）来定义自定义类的运算符行为。
### 1.2.1 **示例：**

```
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __add__(self, other):
        return Point(self.x + other.x, self.y + other.y)

    def __str__(self):
        return f"({self.x}, {self.y})"

p1 = Point(1, 2)
p2 = Point(3, 4)
p3 = p1 + p2
print(p3)  # 输出: (4, 6)
```

### 1.2.2 **常见的运算符重载方法：**

| **运算符** | **方法名**       |
| ------- | ------------- |
| +       | \_\_add__     |
| -       | \_\_sub__     |
| *       | \_\_mul__     |
| /       | \_\_truediv__ |
| ==      | \_\_eq__      |
| <       | \_\_lt__      |
| >       | \_\_gt__      |
| str()   | \_\_str__     |
# 2 与typing中的@overload区别
你提到的 @overload 是 Python 中 **类型提示（type hinting）** 相关的一种“静态重载”，它和我们上面提到的重载方式 **既有关联，又有明显不同**。

## 2.1 **✅ 相同点：**
- 它们的目标都是为了**支持多种调用方式**。
- 都是为了让**一个函数在不同参数下表现不同的行为**。
- 都可被认为是“函数重载”的一种表现形式。
## 2.2 **❌ 不同点（关键）：**

|**对比点**|@overload|@singledispatch **/** *args **实现的“重载”**|
|---|---|---|
|是否影响运行时行为|❌ 不会，**只是类型提示**|✅ 会影响运行结果|
|目的|给编辑器/IDE/类型检查器（如 mypy）看|给 Python 解释器看|
|需要 from typing import overload 吗|✅ 是 typing 的一部分|❌ 不需要|
|是否能定义多个实现|❌ 只能有一个真正的函数体|✅ 每个类型都有独立的实现|
|使用场景|主要用于 **静态类型检查**|主要用于 **动态行为控制**|

## 2.3 **举个 @overload的例子：**

```
from typing import overload, Union

@overload
def greet(name: str) -> str:
    ...

@overload
def greet(name: str, age: int) -> str:
    ...

def greet(name: str, age: Union[int, None] = None) -> str:
    if age is None:
        return f"Hello {name}"
    return f"Hello {name}, you are {age} years old"

# 实际上只有一个函数体，前两个只是类型提示
```

这段代码：
- @overload 的两个定义只是为了告诉类型检查器 greet() 有多种合法的调用方式。
- 真正执行的函数是 **最后那个 greet()**。

你可以使用 mypy 或一些智能 IDE（如 PyCharm、VS Code）来验证它的提示效果。
## 2.4 **总结一句话：**

> @overload 是**为了类型提示**而设计的“重载”，而 @singledispatch 或 *args 则是**为了实现多种行为**的运行时重载。
