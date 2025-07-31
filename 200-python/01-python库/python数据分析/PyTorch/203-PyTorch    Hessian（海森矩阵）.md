
# **一、基本概念：Hessian 是什么？**

设有一个**标量函数** $f(x_1, x_2, …, x_n)$，其梯度为一阶偏导数向量：

$\nabla f = \left[\frac{\partial f}{\partial x_1}, \frac{\partial f}{\partial x_2}, …, \frac{\partial f}{\partial x_n}\right]^T$

那么 **Hessian（海森矩阵）** 是梯度的雅可比矩阵，即所有二阶偏导数组成的矩阵：

$H(f) = \begin{bmatrix} \frac{\partial^2 f}{\partial x_1^2} & \frac{\partial^2 f}{\partial x_1 \partial x_2} & \cdots \\ \frac{\partial^2 f}{\partial x_2 \partial x_1} & \frac{\partial^2 f}{\partial x_2^2} & \cdots \\ \vdots & \vdots & \ddots \end{bmatrix}$

+ [202-PyTorch向量函数对向量变量的求导（Jacobian 雅可比矩阵）](202-PyTorch向量函数对向量变量的求导（Jacobian%20雅可比矩阵）.md)  

> 本质上是对输入变量的“**曲率**”建模，常用于：

- 牛顿法优化
- 梯度爆炸/消失分析
- 模型鲁棒性与 loss 地形可视化

---

# **二、PyTorch 中计算 Hessian 的方式**


使用 torch.autograd.functional.hessian

```
from torch.autograd.functional import hessian
```

---

# **三、Hessian 示例**

## **示例：函数** $f(x_1, x_2) = x_1^2 + x_1x_2 + x_2^2$

  

手动推导的二阶导数矩阵为：

$\begin{bmatrix} \frac{\partial^2 f}{\partial x_1^2} = 2 & \frac{\partial^2 f}{\partial x_1 \partial x_2} = 1 \\ \frac{\partial^2 f}{\partial x_2 \partial x_1} = 1 & \frac{\partial^2 f}{\partial x_2^2} = 2 \end{bmatrix}$

**PyTorch 实现：**

```
import torch
from torch.autograd.functional import hessian

def f(x):  # 输入是一个向量
    return x[0]**2 + x[0]*x[1] + x[1]**2

x = torch.tensor([1.0, 2.0], requires_grad=True)

H = hessian(f, x)

print(H)
```

输出：

```
tensor([[2., 1.],
        [1., 2.]])
```

---

# **四、Hessian 与梯度、Jacobian 的区别对比**

|**项目**|**梯度 (gradient)**|**Jacobian**|**Hessian**|
|---|---|---|---|
|函数类型|标量对向量|向量对向量|标量对向量的二阶导|
|输出形状|(n,)|(m, n)|(n, n)|
|表示|一阶导数|一阶偏导组成的矩阵|二阶偏导组成的矩阵|
|PyTorch|.backward() / grad()|autograd.functional.jacobian()|autograd.functional.hessian()|

---

# **五、Hessian 的应用场景（实用建议）**

|**场景**|**应用**|
|---|---|
|优化算法|牛顿法、拟牛顿法、BFGS|
|损失分析|loss 地形、收敛可视化|
|模型敏感性|对输入微扰的响应分析|
|训练稳定性|梯度爆炸/消失定位工具|

---

# **六、整体结构图谱**

```
Hessian（二阶导）
├── 定义：梯度对输入的 Jacobian
├── 表示：n×n 二阶偏导矩阵
├── PyTorch 接口
│   └── torch.autograd.functional.hessian(func, inputs)
├── 示例：f(x1, x2) = x1^2 + x1x2 + x2^2
├── 应用场景
│   ├── 牛顿法优化
│   ├── loss 地形分析
│   └── 模型稳定性分析
└── 与 Gradient / Jacobian 对比
```

---

扩展：
- 如何使用 Hessian 实现牛顿法求最小值
- [ ] 高阶导数在神经网络中的实战应用（如 gradient penalty、double backward）
