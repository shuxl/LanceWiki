lbfgs 是优化算法的一种，全称是 **Limited-memory Broyden–Fletcher–Goldfarb–Shanno algorithm**。它属于 **拟牛顿法（Quasi-Newton methods）**，是一种用于**无约束优化问题**（比如机器学习中的模型训练）的高效算法，特别适用于 **大规模参数优化问题**。

+ 知识
	+ [x] [Hessian 矩阵（海森矩阵）](Hessian%20矩阵（海森矩阵）.md)
	+ [ ] 加速梯度下降
	+ [ ] 梯度和变量的变化量

---

# 1 **一、LBFGS的背景**

LBFGS 是从 **BFGS 算法**演化来的：
- BFGS 是一种经典的拟牛顿方法，通过近似 Hessian 矩阵（即目标函数的二阶导数）来加速梯度下降。
- 然而 BFGS 要维护一个 $n \times n$ 的矩阵（$n$ 是参数数量），在高维问题中会耗费大量内存。
- L-BFGS 就是 “**Limited-memory** BFGS”，它不显式存储完整的 Hessian 近似矩阵，而是只保留若干历史信息（如梯度和变量的变化量），**显著降低了内存使用**。

---

# 2 **二、LBFGS 的特点**

| **特点**   | **说明**                          |
| -------- | ------------------------------- |
| **类型**   | 一阶优化算法（只用到梯度）                   |
| **内存优化** | 不保存完整Hessian矩阵，仅保存最近m步（一般 m=10） |
| **收敛速度** | 通常比标准梯度下降快，尤其在凸优化问题中表现良好        |
| **常用于**  | 逻辑回归、神经网络训练、L-BFGS-SGD等         |

---

# 3 **三、使用场景举例**

在 Python 的 scikit-learn 中，训练逻辑回归时默认使用 lbfgs：
```
from sklearn.linear_model import LogisticRegression
clf = LogisticRegression(solver='lbfgs', max_iter=1000)
clf.fit(X_train, y_train)
```
- solver='lbfgs' 指定使用 L-BFGS 优化算法。
- 适合中小数据集，支持 L2 正则，收敛稳定。

---

# 4 **四、LBFGS 的优化过程简要描述**
每一轮迭代：
1. 计算当前点的梯度 $\nabla f(x_k)$；
2. 利用历史的变量变化 $s_k = x_{k+1} - x_k$ 和梯度变化 $y_k = \nabla f(x_{k+1}) - \nabla f(x_k)$；
3. 构造一个方向（模拟Hessian反矩阵作用于梯度）；
4. 使用线搜索（line search）找到合适的步长；
5. 更新参数 $x$。

---

# 5 **五、优缺点总结**  
**优点：**
- 高效、内存占用低；
- 收敛速度快于普通梯度下降；
- 可以处理中等规模的参数（几千维甚至上万维）。
**缺点：**
- 对超参数（如步长）较敏感；
- 不适合极大规模数据（此时常用 SGD）；
- 实现复杂，不适合手动实现（通常用现成库）。
