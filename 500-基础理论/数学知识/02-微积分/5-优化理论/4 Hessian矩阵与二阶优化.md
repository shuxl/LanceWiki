# Hessian矩阵与二阶优化

## 重点内容

- Hessian矩阵的定义和性质
- 二阶导数的几何意义
- 正定矩阵和负定矩阵
- 二阶优化算法
- 在机器学习中的应用

## Hessian矩阵的定义和性质

### 定义

对于多元函数 $f(x_1, x_2, \ldots, x_n)$，Hessian矩阵 $H$ 是一个 $n \times n$ 的矩阵：

$$H_{ij} = \frac{\partial^2 f}{\partial x_i \partial x_j}$$

### 性质

1. **对称性：** 如果函数 $f$ 的二阶偏导数连续，则 $H_{ij} = H_{ji}$
2. **连续性：** 如果函数 $f$ 的二阶偏导数连续，则Hessian矩阵是连续的
3. **线性性：** Hessian矩阵满足线性性质：$H(f + g) = H(f) + H(g)$

## 二阶导数的几何意义

### 局部曲率

Hessian矩阵描述了函数在一点的局部曲率：

- **正特征值：** 对应方向上的函数向上弯曲
- **负特征值：** 对应方向上的函数向下弯曲
- **零特征值：** 对应方向上函数是平的

### 局部近似

函数在点 $x_0$ 附近的二阶泰勒展开：

$$f(x) \approx f(x_0) + \nabla f(x_0)^T(x - x_0) + \frac{1}{2}(x - x_0)^T H(x_0)(x - x_0)$$

## 正定矩阵和负定矩阵

### 正定矩阵

**定义：** 对于所有非零向量 $v$，如果 $v^T H v > 0$，则称矩阵 $H$ 为正定矩阵。

**等价条件：**
1. 所有特征值都是正的
2. 所有主子式都是正的

### 负定矩阵

**定义：** 对于所有非零向量 $v$，如果 $v^T H v < 0$，则称矩阵 $H$ 为负定矩阵。

### 在优化中的意义

1. **局部最小值：** 如果 $H(x^*)$ 正定，则 $x^*$ 是局部最小值
2. **局部最大值：** 如果 $H(x^*)$ 负定，则 $x^*$ 是局部最大值
3. **鞍点：** 如果 $H(x^*)$ 既有正特征值又有负特征值，则 $x^*$ 是鞍点

## 二阶优化算法

### 牛顿法

牛顿法使用Hessian矩阵的逆来更新参数：

$$x_{k+1} = x_k - H^{-1}(x_k) \nabla f(x_k)$$

**优点：**
- 二次收敛速度
- 不需要调整学习率

**缺点：**
- 需要计算和存储Hessian矩阵
- 计算复杂度高
- 对初始点敏感

### 拟牛顿法

拟牛顿法通过近似Hessian矩阵来避免直接计算：

1. **BFGS算法：** 通过秩二更新近似Hessian逆矩阵
2. **L-BFGS：** 内存受限的BFGS算法

### 信赖域方法

信赖域方法在每次迭代中求解子问题：

$$\min_p \nabla f(x_k)^T p + \frac{1}{2} p^T H_k p$$
$$\text{subject to } \|p\| \leq \Delta_k$$

## 在机器学习中的应用

### 神经网络优化

#### 二阶方法在深度学习中的应用

1. **自然梯度下降：** 使用Fisher信息矩阵作为Hessian的近似
2. **K-FAC算法：** 对Fisher信息矩阵进行Kronecker分解
3. **Hessian-free优化：** 不显式计算Hessian矩阵，而是通过矩阵-向量乘积

### 代码示例

```python
import numpy as np
from scipy.optimize import minimize

def rosenbrock(x):
    """Rosenbrock函数"""
    return (1 - x[0])**2 + 100 * (x[1] - x[0]**2)**2

def rosenbrock_grad(x):
    """Rosenbrock函数的梯度"""
    grad = np.zeros(2)
    grad[0] = -2 * (1 - x[0]) - 400 * x[0] * (x[1] - x[0]**2)
    grad[1] = 200 * (x[1] - x[0]**2)
    return grad

def rosenbrock_hess(x):
    """Rosenbrock函数的Hessian矩阵"""
    hess = np.zeros((2, 2))
    hess[0, 0] = 2 - 400 * x[1] + 1200 * x[0]**2
    hess[0, 1] = -400 * x[0]
    hess[1, 0] = -400 * x[0]
    hess[1, 1] = 200
    return hess

# 使用牛顿法优化
x0 = np.array([-1.2, 1.0])
result = minimize(rosenbrock, x0, method='Newton-CG', 
                 jac=rosenbrock_grad, hess=rosenbrock_hess)
print("最优解:", result.x)
print("最优值:", result.fun)
```

### 逻辑回归中的二阶优化

```python
def logistic_loss(w, X, y):
    """逻辑回归损失函数"""
    z = X.dot(w)
    return np.mean(np.log(1 + np.exp(-y * z)))

def logistic_grad(w, X, y):
    """逻辑回归梯度"""
    z = X.dot(w)
    p = 1 / (1 + np.exp(-y * z))
    return -X.T.dot(y * (1 - p)) / len(y)

def logistic_hess(w, X, y):
    """逻辑回归Hessian矩阵"""
    z = X.dot(w)
    p = 1 / (1 + np.exp(-y * z))
    D = np.diag(p * (1 - p))
    return X.T.dot(D).dot(X) / len(y)
```

## Hessian矩阵的计算技巧

### 数值微分

当解析导数难以计算时，可以使用数值微分：

```python
def numerical_hessian(f, x, h=1e-5):
    """数值计算Hessian矩阵"""
    n = len(x)
    H = np.zeros((n, n))
    
    for i in range(n):
        for j in range(n):
            # 中心差分
            x_pp = x.copy()
            x_pm = x.copy()
            x_mp = x.copy()
            x_mm = x.copy()
            
            x_pp[i] += h
            x_pp[j] += h
            x_pm[i] += h
            x_pm[j] -= h
            x_mp[i] -= h
            x_mp[j] += h
            x_mm[i] -= h
            x_mm[j] -= h
            
            H[i, j] = (f(x_pp) - f(x_pm) - f(x_mp) + f(x_mm)) / (4 * h**2)
    
    return H
```

### 自动微分

现代深度学习框架使用自动微分来计算Hessian矩阵：

```python
import torch

def compute_hessian(f, x):
    """使用PyTorch计算Hessian矩阵"""
    x.requires_grad_(True)
    y = f(x)
    
    # 计算梯度
    grad = torch.autograd.grad(y, x, create_graph=True)[0]
    
    # 计算Hessian矩阵
    hessian = torch.zeros(len(x), len(x))
    for i in range(len(x)):
        hessian[i] = torch.autograd.grad(grad[i], x, retain_graph=True)[0]
    
    return hessian
```

## Hessian矩阵关联的其它知识

- [优化基础概念](1%20优化基础概念.md)
- [梯度下降法](2%20梯度下降法.md)
- [牛顿法与拟牛顿法](3%20牛顿法与拟牛顿法.md)
- [凸优化基础](5%20凸优化基础.md)
- [约束优化](6%20约束优化.md)
- [机器学习应用](../006-机器学习应用/README.md) 