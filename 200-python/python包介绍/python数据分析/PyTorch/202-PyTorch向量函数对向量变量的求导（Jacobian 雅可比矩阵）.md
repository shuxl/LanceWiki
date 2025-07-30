
# **一、基本概念：Jacobian（雅可比矩阵）**

设有向量函数：
$\mathbf{y} = f(\mathbf{x}) = \begin{bmatrix} y_1(x_1, x_2, …, x_n) \\ y_2(x_1, x_2, …, x_n) \\ \vdots \\ y_m(x_1, x_2, …, x_n) \end{bmatrix} \quad \mathbf{x} = \begin{bmatrix} x_1 \\ x_2 \\ \vdots \\ x_n \end{bmatrix}$

那么 Jacobian 是一个 $m \times n$ 的矩阵：
$J = \frac{\partial \mathbf{y}}{\partial \mathbf{x}} = \begin{bmatrix} \frac{\partial y_1}{\partial x_1} & \frac{\partial y_1}{\partial x_2} & \cdots & \frac{\partial y_1}{\partial x_n} \\ \frac{\partial y_2}{\partial x_1} & \frac{\partial y_2}{\partial x_2} & \cdots & \frac{\partial y_2}{\partial x_n} \\ \vdots & \vdots & \ddots & \vdots \\ \frac{\partial y_m}{\partial x_1} & \frac{\partial y_m}{\partial x_2} & \cdots & \frac{\partial y_m}{\partial x_n} \end{bmatrix}$

每一行是一个标量函数对所有变量的偏导数。

---

# **二、在 PyTorch 中求 Jacobian（使用autograd.functional.jacobian）**

PyTorch 提供了一个函数专门用于计算 Jacobian 矩阵：
```
import torch
from torch.autograd.functional import jacobian
```
## **示例：二维向量函数对二维向量变量的 Jacobian**
定义：
$\mathbf{y} = \begin{bmatrix} x_1^2 + x_2 \\ x_1 \cdot \sin(x_2) \end{bmatrix}$

```
import torch
from torch.autograd.functional import jacobian

def func(x):
    return torch.tensor([
        x[0]**2 + x[1],
        x[0] * torch.sin(x[1])
    ])

x = torch.tensor([1.0, 2.0], requires_grad=True)
J = jacobian(func, x)

print(J)
```

结果：

```
tensor([[2.0000, 1.0000],     # dy1/dx1 = 2x1, dy1/dx2 = 1
        [0.9093, 0.5403]])    # dy2/dx1 = sin(x2), dy2/dx2 = x1*cos(x2)
```

---

# **三、与.backward()的区别**

|**方法**|**适用对象**|**是否返回整个 Jacobian**|**是否需要标量目标**|**使用场景**|
|---|---|---|---|---|
|.backward()|标量输出|否（只返回一阶梯度）|是|训练损失反传|
|torch.autograd.functional.jacobian()|向量输出|是|否|分析模型结构，调试中间梯度|

---

# **四、典型场景**

- 自定义损失函数中需要精确控制导数行为
- 分析神经网络某一层的输入输出变化（尤其是 transformer 或 meta learning）
- 求解高阶导数（通过多次 jacobian）
    

---

# **五、结构总结图**

```
向量函数求导（Jacobian）
├── 定义
│   └── m个函数对n个变量组成 m×n 矩阵
├── PyTorch 实现
│   ├── autograd.functional.jacobian(func, inputs)
│   └── 适用于向量输出
├── 与 .backward() 区别
│   ├── backward: 标量目标、训练主流方式
│   └── jacobian: 分析型、向量目标
└── 示例
    ├── y = [x1^2 + x2, x1 * sin(x2)]
    └── 输出 Jacobian 矩阵
```
