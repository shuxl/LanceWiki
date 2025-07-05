**Hessian 矩阵（海森矩阵）是一个用于描述一个多变量函数的二阶偏导数信息**的矩阵。它在优化、机器学习、数值分析等领域非常重要，特别是判断函数在某点的极值性质（极小值、极大值、鞍点）时非常有用。
+ 知识点：
	+ 二阶偏导数信息[^1]
	+ 微积分的知识

---

# 1 **一、Hessian 矩阵的定义**

设有一个实值函数：
$f(x_1, x_2, …, x_n)$

它的 Hessian 矩阵定义为：[^1]

$H(f) = \begin{bmatrix} \frac{\partial^2 f}{\partial x_1^2} & \frac{\partial^2 f}{\partial x_1 \partial x_2} & \cdots & \frac{\partial^2 f}{\partial x_1 \partial x_n} \\ \frac{\partial^2 f}{\partial x_2 \partial x_1} & \frac{\partial^2 f}{\partial x_2^2} & \cdots & \frac{\partial^2 f}{\partial x_2 \partial x_n} \\ \vdots & \vdots & \ddots & \vdots \\ \frac{\partial^2 f}{\partial x_n \partial x_1} & \frac{\partial^2 f}{\partial x_n \partial x_2} & \cdots & \frac{\partial^2 f}{\partial x_n^2} \end{bmatrix}$


这是一个 $n \times n$ 的对称矩阵（若函数在该点的二阶偏导是连续的，根据 Schwarz 定理）。

---

# 2 **二、通俗解释**

Hessian 是二阶导数在多维空间的推广：
- 一阶导数（梯度）告诉你“上坡”或“下坡”的方向；
- 二阶导数（Hessian）告诉你“坡的陡峭程度”和“弯曲方向”。

例如在二维平面中，Hessian 矩阵可以帮助我们判断函数在某点是凸的、凹的，还是“马鞍形”。

---

# 3 **三、举个例子**

考虑函数：
$f(x, y) = x^2 + xy + y^2$

求梯度：
$\nabla f = \left[\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}\right] = [2x + y, x + 2y]$

Hessian 矩阵为：

$H(f) = \begin{bmatrix} \frac{\partial^2 f}{\partial x^2} & \frac{\partial^2 f}{\partial x \partial y} \\ \frac{\partial^2 f}{\partial y \partial x} & \frac{\partial^2 f}{\partial y^2} \end{bmatrix} \begin{bmatrix} 2 & 1 \\ 1 & 2 \end{bmatrix}$

---

# 4 **四、Hessian 的作用**

1. **判断极值**（二阶导数判别法）：
    - 如果 Hessian 是正定矩阵 → 局部最小值；
    - 如果 Hessian 是负定矩阵 → 局部最大值；
    - 如果 Hessian 既有正又有负的特征值 → 鞍点；
    - 如果 Hessian 不定 → 无法判断。
    
2. **在优化算法中的作用**：
    - 二阶优化算法（如牛顿法、BFGS、LBFGS）中用 Hessian 或其近似值来计算参数更新步长，提升收敛速度。

---

# 5 **五、Hessian 与梯度的对比**

| **项目** | **梯度（Gradient）** | **Hessian**    |
| ------ | ---------------- | -------------- |
| 描述     | 一阶导数（方向）         | 二阶导数（曲率）       |
| 类型     | 向量（n 维）          | 矩阵（n × n）      |
| 用途     | 指示函数增加最快方向       | 判断函数的局部形状和极值性质 |

---

如果你感兴趣，我可以进一步讲解 Hessian 如何在牛顿法或拟牛顿法中被用来优化损失函数。

[^1]: 偏导数：[108-偏导数](../微积分/108-偏导数.md)
