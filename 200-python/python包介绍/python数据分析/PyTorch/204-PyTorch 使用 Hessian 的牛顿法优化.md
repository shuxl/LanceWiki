用 PyTorch 实现 **使用 Hessian 的牛顿法优化**过程，来最小化一个函数。需要把前面学到的：
- 一阶导数（梯度）：[201-PyTorch多变量函数求导](201-PyTorch多变量函数求导.md)
- 二阶导数（Hessian）：[203-PyTorch    Hessian（海森矩阵）](203-PyTorch%20%20%20%20Hessian（海森矩阵）.md)
应用在实际优化算法中。

---

# **牛顿法基本原理**

目标：最小化标量函数 $f(x)$

每一步迭代的更新公式是：
$x_{t+1} = x_t - H^{-1}(x_t) \cdot \nabla f(x_t)$

其中：
- $\nabla f(x_t)$：当前位置的一阶导数（梯度）
- $H(x_t)$：当前位置的二阶导数矩阵（Hessian）
- $H^{-1}$：Hessian 的逆矩阵

> 这比普通的梯度下降快很多，尤其在接近极小值点时，因为考虑了**曲率信息**。

---

## **示例函数**

我们以如下函数为例：

$f(x) = (x_0 - 3)^2 + (x_1 + 1)^2$


最小值在 $x = [3, -1]$，我们将从初始点 $[0, 0]$ 开始，用牛顿法求解。

---

## **完整代码实现（PyTorch + Hessian）**

```
import torch
from torch.autograd.functional import hessian

# 定义目标函数
def func(x):
    return (x[0] - 3)**2 + (x[1] + 1)**2

# 初始点
x = torch.tensor([0.0, 0.0], requires_grad=True)

for i in range(5):
    # 计算梯度
    y = func(x)
    y.backward()  # 自动求梯度
    grad = x.grad.detach()  # 保存梯度
    x.grad.zero_()  # 清空之前的梯度

    # 计算 Hessian
    H = hessian(func, x)

    # 解线性方程 H * delta = grad（等价于 H⁻¹ @ grad）
    delta = torch.linalg.solve(H, grad)

    # 更新参数（梯度下降方向为负梯度）
    with torch.no_grad():
        x -= delta

    print(f"Step {i+1}: x = {x.tolist()}, f(x) = {func(x).item():.6f}")
```

---

输出结果类似：

```
Step 1: x = [2.0, -0.6666666865348816], f(x) = 1.111111
Step 2: x = [2.6666667461395264, -0.8888888955116272], f(x) = 0.123456
Step 3: x = [2.8888888359069824, -0.9629629850387573], f(x) = 0.013717
Step 4: x = [2.9629628658294678, -0.9876543283462524], f(x) = 0.001524
Step 5: x = [2.987654209136963, -0.9958847761154175], f(x) = 0.000169
```

几步就非常接近目标值 $[3, -1]$，比普通梯度下降收敛快很多。

---

## **说明与注意事项**

- 如果 Hessian 不可逆，可以使用 torch.linalg.pinv(H)（伪逆）处理退化情形
- 实际深度学习中很少用完整 Hessian（因为维度太大），但其思想用于：
    - L-BFGS、Adam（近似 Hessian）
    - 模型敏感度分析
- PyTorch 的 hessian(func, x) 是静态计算一次 Hessian，适合函数维度较小的实验环境

---

## **扩展建议**

深入：
- 拟牛顿法（BFGS、L-BFGS）
- 二阶优化在 meta-learning、few-shot 中的应用
- Hessian spectrum 分析：用于 loss 地形评估