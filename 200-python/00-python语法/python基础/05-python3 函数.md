# 1 函数的定义
```
def  函数名（参数列表）：
    函数体

```
例子
```
>>> def hello() :
  print("Hello World!")

 
>>> hello()
Hello World!
>>> 

```

# 2 关键字参数
函数也可以使用 kwarg = value 的关键字参数形式被调用。例如，以下函数:

``` python
def parrot(voltage, state='a stiff', action='voom', type='Norwegian Blue'):
    print("-- This parrot wouldn't", action, end=' ')
    print("if you put", voltage, "volts through it.")
    print("-- Lovely plumage, the", type)
    print("-- It's", state, "!")

```
可以以下几种方式被调用:
```
parrot(1000)                                          # 1 positional argument
parrot(voltage=1000)                                  # 1 keyword argument
parrot(voltage=1000000, action='VOOOOOM')             # 2 keyword arguments
parrot(action='VOOOOOM', voltage=1000000)             # 2 keyword arguments
parrot('a million', 'bereft of life', 'jump')         # 3 positional arguments
parrot('a thousand', state='pushing up the daisies')  # 1 positional, 1 keyword

```
以下为错误调用方法：
```
parrot()                     # required argument missing
parrot(voltage=5.0, 'dead')  # non-keyword argument after a keyword argument
parrot(110, voltage=220)     # duplicate value for the same argument
parrot(actor='John Cleese')  # unknown keyword argument

```

# 3 可变参数列表
最后，一个较不常用的功能是可以让函数调用可变个数的参数。

这些参数被包装进一个元组(查看元组和序列)。

在这些可变个数的参数之前，可以有零到多个普通的参数:

``` python
def arithmetic_mean(*args):
    if len(args) == 0:
        return 0
    else:
        sum = 0
        for x in args:
            sum += x
        return sum/len(args)


print(arithmetic_mean(45,32,89,78))
print(arithmetic_mean(8989.8,78787.78,3453,78778.73))
print(arithmetic_mean(45,32))
print(arithmetic_mean(45))
print(arithmetic_mean())
```