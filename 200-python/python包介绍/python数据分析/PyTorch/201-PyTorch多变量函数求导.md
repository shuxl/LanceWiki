好的，以下是 **Autograd 自动求导的进阶内容：多变量函数求导** 的系统讲解，包括数学背景、PyTorch 实现和关键概念。

---

# **一、数学背景：多变量函数的梯度**


设函数

$y = f(x_1, x_2, \ldots, x_n)$

那么对每个变量 $x_i$ 的偏导数组成一个向量：

$\nabla f = \left[ \frac{\partial f}{\partial x_1}, \frac{\partial f}{\partial x_2}, \ldots, \frac{\partial f}{\partial x_n} \right]$

这就是 **梯度（gradient）**，是一个方向导数向量，代表函数上升最快的方向。

---

# **二、PyTorch 多变量自动求导示例**

## **示例 1：函数**  $y = x_1^2 + x_2^2 + x_1 x_2$

```
import torch

定义变量
x1 = torch.tensor(2.0, requires_grad=True)
x2 = torch.tensor(3.0, requires_grad=True)

定义函数
y = x1**2 + x2**2 + x1 * x2

反向传播
y.backward()

打印每个变量的梯度
print(f"dy/dx1 = {x1.grad}")  # 2*x1 + x2 = 2*2 + 3 = 7
print(f"dy/dx2 = {x2.grad}")  # 2*x2 + x1 = 2*3 + 2 = 8
```

---

## **示例 2：多个输入变量组成向量的情况**

  

PyTorch 也支持把多个变量组成一个张量 x = torch.tensor([x1, x2], requires_grad=True)，对整个张量求导。

```
x = torch.tensor([2.0, 3.0], requires_grad=True)

y = x[0]^2 + x[1]^2 + x[0]*x[1]
y = x[0]**2 + x[1]**2 + x[0]*x[1]
y.backward()

print(x.grad)  # tensor([7., 8.])
```

---

# **三、重点说明与注意事项**

## **1. 多变量的backward()默认返回标量梯度
- PyTorch 要求目标变量 y 是**标量**，否则需要提供 gradient=

## **2. 目标函数为向量时，需显式提供gradient**

- 如果 y 是向量，如：

```
y = x ** 2  # y 是向量 [x1^2, x2^2]
```

- 那么调用 .backward() 时需要传入与 y 同形状的 gradient：

```
y.backward(torch.tensor([1.0, 1.0]))  # 相当于对 y 所有元素求和后再反向传播
```

## **3. 多变量常用于：**
- 多个模型参数同时更新
- 多输入函数的优化问题（如机器学习损失函数）

---

# **四、多变量函数求导结构图**

```
多变量函数求导
├── 数学概念
│   └── 梯度向量：偏导数组成
├── PyTorch 实现
│   ├── 多个独立变量（x1, x2, ...）
│   └── 变量向量张量（x = [x1, x2]）
├── 注意事项
│   ├── y 必须是标量
│   ├── 向量输出时需指定 gradient
└── 实战例子
    └── y = x1^2 + x2^2 + x1*x2
```

---

是否需要我继续讲解「向量函数对向量变量」的求导（如雅可比矩阵）？这个在深度学习中如输出多维向量时很常见，比如多类别交叉熵、神经网络层的输出等。