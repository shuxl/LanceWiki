# 1 **NumPy 阶段二 函数与操作清单**

  

## 1.1 **一、数组间的算术运算（逐元素）**

|**运算符**|**含义**|**示例**|**说明**|
|---|---|---|---|
|+|加法|a + b|数组逐元素相加|
|-|减法|a - b|数组逐元素相减|
|*|乘法|a * b|数组逐元素相乘|
|/|除法|a / b|数组逐元素相除|
|**|幂运算|a ** 2|对每个元素平方|

---

## 1.2 **二、通用函数（Universal Functions / ufunc）**

| **函数**     | **示例**                     | **说明**       |
| ---------- | -------------------------- | ------------ |
| np.sqrt(x) | np.sqrt([1, 4, 9])         | 平方根          |
| np.exp(x)  | np.exp([1, 2, 3])          | 自然指数函数 $e^x$ |
| np.log(x)  | np.log([1, np.e, np.e**2]) | 自然对数函数       |
| np.sin(x)  | np.sin(np.pi / 2)          | 正弦函数（以弧度为单位） |
| np.abs(x)  | `np.abs([-1, -3])`         | 绝对值          |

> 注：所有 ufunc 都支持数组作为输入，并对数组中每个元素进行操作

---

## 1.3 **三、广播机制（Broadcasting）**

+ [112-Numpy广播机制的应用场景](112-Numpy广播机制的应用场景.md)

**没有单独的函数，但需掌握广播规则：**

| **场景**   | **示例**                                                                | **说明**                  |
| -------- | --------------------------------------------------------------------- | ----------------------- |
| 形状不同自动扩展 | `a = np.array([[1], [2], [3]])   b = np.array([10, 20, 30])    a + b` | a 为 3x1，b 为 1x3，广播为 3x3 |

**广播规则简述：**
1. 从后往前对比维度
2. 两个维度相等，或其中一个是 1，则匹配成功
3. 否则报错

```
广播结果:
 [[11 21 31]
 [12 22 32]
 [13 23 33]]
```


另一例子帮助理解
```
import numpy as np

A = np.array([[1, 2, 3],
              [4, 5, 6]])       # 形状 (2, 3)

b = np.array([10, 20, 30])      # 形状 (3, )

C = A + b   # 广播为 A 每一行都加 b
```
相当于
```
[1+10, 2+20, 3+30]
[4+10, 5+20, 6+30]
```


---

## 1.4 **四、逻辑运算与布尔索引**

|**表达式**|**示例**|**说明**|
|---|---|---|
|a > x|a[a > 5]|筛选大于某值的元素|
|a == x|a[a == 3]|筛选等于某值的元素|
|(cond1) & (cond2)|a[(a > 3) & (a < 7)]|多个条件组合（注意用括号）|
|~(cond)|a[~(a > 5)]|取反（例如筛选小于等于5）|

---

## 1.5 **五、可选进阶（了解即可）**

|**函数**|**示例**|**说明**|
|---|---|---|
|np.maximum(a, b)|np.maximum([1, 2], [2, 1])|逐元素取较大值|
|np.minimum(a, b)|np.minimum([1, 2], [2, 1])|逐元素取较小值|
|np.clip(a, min, max)|np.clip(a, 0, 10)|限定区间范围|
