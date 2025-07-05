

# 1 PyTorch张量数学计算详解

PyTorch的张量（`torch.Tensor`）支持丰富的数学运算，包括基本运算、矩阵乘法、广播机制等。以下是核心知识点及示例：

---

## 1.1 ​**基本运算符**​（逐元素操作）

运算符 `+`, `-`, `*`, `/` 或函数 `torch.add()`, `torch.sub()`, `torch.mul()`, `torch.div()` 执行逐元素计算。  
​**示例**​：

```
import torch

a = torch.tensor([1, 2, 3])
b = torch.tensor([4, 5, 6])

加法
print(a + b)        # tensor([5, 7, 9])
print(torch.add(a, b))  # 等效

减法
print(a - b)        # tensor([-3, -3, -3])

乘法（逐元素）
print(a * b)        # tensor([ 4, 10, 18])

除法（逐元素）
print(b / a)        # tensor([4., 2.5, 2.])
```

+ [221-基本运算符（逐元素操作） 对张量的纬度是否有要求？](221-基本运算符（逐元素操作）%20对张量的纬度是否有要求？.md)

---

## 1.2 ​**矩阵乘法**​

- ​`@` 或 `torch.matmul()`**​：标准矩阵乘法（支持高维张量）。
- *`torch.mm()`**​：仅限二维矩阵乘法。

​**示例**​：

```
x = torch.tensor([[1, 2], [3, 4]])
y = torch.tensor([[5, 6], [7, 8]])

矩阵乘法
print(x @ y)        # tensor([[19, 22], [43, 50]])
print(torch.matmul(x, y))  # 等效

二维矩阵专用
print(torch.mm(x, y))     # 同上结果
```

+ [120-矩阵乘法（包括高维张量）](../../../../700-人工智能/数学知识/线性代数/120-矩阵乘法（包括高维张量）.md)
---

## 1.3 ​**广播机制**​（Broadcasting）

当张量形状不同时，PyTorch自动扩展较小张量的维度以匹配较大张量，无需显式复制数据。  
​**规则**​：

1. 从尾部维度对齐，逐个维度比较。
2. 维度兼容条件：相等、其中一个为1、或其中一个不存在。

​**示例**​：

```
A = torch.tensor([[1, 2], [3, 4]])  # 2x2
B = torch.tensor([10, 20])          # 2

B自动广播为 [[10, 20], [10, 20]]
print(A + B)  # tensor([[11, 22], [13, 24]])

C = torch.tensor([[5], [10]])     # 2x1
C广播为 [[5, 5], [10, 10]]
print(A * C)  # tensor([[ 5, 10], [30, 40]])
```

​**广播失败案例**​：

```
D = torch.tensor([1, 2, 3])  # (3,)
E = torch.tensor([[4, 5], [6, 7]])  # (2,2)
print(D + E)  # 报错: 尾部维度 3 != 2
```

---

## 1.4 ​**常用数学函数**​

PyTorch提供大量数学函数，均支持逐元素操作：

```
t = torch.tensor([1.0, 2.0, 3.0])

print(torch.sqrt(t))   # 平方根 → [1.00, 1.41, 1.73]
print(torch.exp(t))    # 指数 → [2.72, 7.39, 20.09]
print(torch.log(t))    # 自然对数 → [0.00, 0.69, 1.10]
print(torch.sin(t))    # 正弦
```

---

## 1.5 ​**维度规约计算**​

沿特定维度求和/平均等：

```
M = torch.arange(6).reshape(2, 3)  # [[0,1,2], [3,4,5]]

全局求和
print(torch.sum(M))    # 15

按行求和（压缩行）
print(torch.sum(M, dim=0))   # tensor([3, 5, 7]) 

按列求和（压缩列）
print(torch.sum(M, dim=1))   # tensor([3, 12])

保持维度不压缩
print(torch.sum(M, dim=1, keepdim=True)) # [[3], [12]]
```

---

## 1.6 ​**梯度支持（Autograd）​**​

张量计算可自动跟踪梯度：

```
x = torch.tensor(2.0, requires_grad=True)
y = x**2 + 3*x + 1
y.backward()          # 自动微分
print(x.grad)         # dy/dx = 2*x + 3 = 7.0
```

---

# 2 总结

|​**操作类型**​|​**方法/运算符**​|特点|
|---|---|---|
|逐元素运算|`+`, `-`, `*`, `/`|形状相同|
|矩阵乘法|`@`, `torch.matmul()`, `torch.mm()`|支持高维广播|
|广播机制|自动触发|按维度对齐规则扩展张量|
|数学函数|`torch.sqrt()`, `exp()`, `sin()` 等|逐元素计算|
|规约操作|`sum()`, `mean()`, `max()`|可指定维度与梯度传播|

通过熟练掌握这些操作，可高效实现神经网络中的数值计算与梯度优化。