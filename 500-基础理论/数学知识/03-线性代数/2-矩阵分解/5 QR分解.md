# QR分解

## 重点内容

本文档介绍QR分解的核心概念，包括：
- QR分解的定义和性质
- QR分解的算法实现
- QR分解的应用
- QR分解的数值稳定性

## 1. QR分解的定义

### 1.1 基本定义

**定义**：对于m×n矩阵 $A$，存在分解：
$$A = QR$$

其中：
- $Q$ 是m×m正交矩阵（$Q^TQ = I$）
- $R$ 是m×n上三角矩阵

### 1.2 分解的存在性

**定理**：任何m×n矩阵都可以进行QR分解。

**证明**：可以通过Gram-Schmidt正交化过程构造。

### 1.3 分解的唯一性

**定理**：如果 $A$ 的列向量线性无关，且 $R$ 的对角元素为正，则QR分解是唯一的。

**证明**：假设 $A = Q_1R_1 = Q_2R_2$，则 $Q_2^TQ_1 = R_2R_1^{-1}$。左边是正交矩阵，右边是上三角矩阵，因此都等于单位矩阵。

## 2. QR分解的算法

### 2.1 Gram-Schmidt正交化

**基本思想**：将矩阵 $A$ 的列向量正交化，得到正交矩阵 $Q$。

**算法步骤**：
1. 设 $A = [\mathbf{a}_1, \mathbf{a}_2, \ldots, \mathbf{a}_n]$
2. 对于 $i = 1, 2, \ldots, n$：
   - $\mathbf{q}_i = \mathbf{a}_i - \sum_{j=1}^{i-1} \text{proj}_{\mathbf{q}_j}\mathbf{a}_i$
   - $\mathbf{q}_i = \frac{\mathbf{q}_i}{\|\mathbf{q}_i\|}$（归一化）
3. $Q = [\mathbf{q}_1, \mathbf{q}_2, \ldots, \mathbf{q}_n]$
4. $R_{ij} = \mathbf{q}_i^T\mathbf{a}_j$（$i \leq j$）

### 2.2 Householder变换

**基本思想**：使用Householder反射将矩阵化为上三角形式。

**Householder矩阵**：
$$H = I - 2\frac{\mathbf{v}\mathbf{v}^T}{\|\mathbf{v}\|^2}$$

其中 $\mathbf{v}$ 是反射向量。

**算法步骤**：
1. 对于 $k = 1, 2, \ldots, \min(m-1, n)$：
   - 构造Householder矩阵 $H_k$ 将第k列的下三角部分化为零
   - $A = H_kA$
2. $Q = H_1^TH_2^T \cdots H_{min(m-1,n)}^T$
3. $R$ 是最终的上三角矩阵

### 2.3 Givens旋转

**基本思想**：使用Givens旋转逐步将矩阵化为上三角形式。

**Givens矩阵**：
$$G(i,j,\theta) = \begin{pmatrix} 
I_{i-1} & 0 & 0 & 0 \\
0 & \cos\theta & 0 & -\sin\theta \\
0 & 0 & I_{j-i-1} & 0 \\
0 & \sin\theta & 0 & \cos\theta
\end{pmatrix}$$

**算法步骤**：
1. 对于每个非零元素 $a_{ij}$（$i > j$）：
   - 构造Givens旋转 $G(i,j,\theta)$ 将 $a_{ij}$ 化为零
   - $A = G(i,j,\theta)A$
2. $Q$ 是所有Givens旋转的乘积
3. $R$ 是最终的上三角矩阵

## 3. QR分解的性质

### 3.1 基本性质

**性质**：
- $Q$ 是正交矩阵：$Q^TQ = QQ^T = I$
- $R$ 是上三角矩阵
- 如果 $A$ 是方阵且非奇异，则 $R$ 也是非奇异的

### 3.2 数值稳定性

**优势**：QR分解比LU分解更数值稳定。

**原因**：正交变换保持向量的长度和角度，不会放大误差。

### 3.3 计算复杂度

**时间复杂度**：
- Gram-Schmidt：$O(mn^2)$
- Householder：$O(mn^2)$
- Givens：$O(mn^2)$

**空间复杂度**：$O(mn)$

## 4. QR分解的应用

### 4.1 线性方程组的求解

**问题**：求解 $Ax = b$

**步骤**：
1. 计算QR分解：$A = QR$
2. 求解 $Q^Tb = y$
3. 求解 $Rx = y$（后向替换）

**优势**：比LU分解更稳定，特别是对于病态矩阵。

### 4.2 最小二乘问题

**问题**：$\min_x \|Ax - b\|^2$

**解**：
1. 计算QR分解：$A = QR$
2. 计算 $Q^Tb = \begin{pmatrix} c \\ d \end{pmatrix}$
3. 求解 $R_1x = c$，其中 $R_1$ 是 $R$ 的前n行

**优势**：QR分解是求解最小二乘问题的标准方法。

### 4.3 特征值计算

**QR算法**：用于计算矩阵的特征值。

**步骤**：
1. $A_0 = A$
2. 对于 $k = 1, 2, \ldots$：
   - 计算 $A_{k-1} = Q_kR_k$
   - $A_k = R_kQ_k$
3. $A_k$ 收敛到上三角矩阵，对角元素是特征值

### 4.4 奇异值分解

**关系**：SVD可以通过QR分解加速计算。

**方法**：
1. 计算 $A^TA$ 的QR分解
2. 对 $R$ 进行SVD分解
3. 组合得到 $A$ 的SVD分解

## 5. 特殊矩阵的QR分解

### 5.1 稀疏矩阵

**问题**：稀疏矩阵的QR分解可能产生填充。

**解决方案**：
- 重新排序减少填充
- 使用稀疏QR算法

### 5.2 带状矩阵

**优势**：带状矩阵的QR分解保持带状结构。

**应用**：在数值分析中广泛使用。

### 5.3 Toeplitz矩阵

**定义**：Toeplitz矩阵是常数对角线的矩阵。

**应用**：在信号处理中用于滤波器设计。

## 6. QR分解的扩展

### 6.1 经济QR分解

**定义**：对于m×n矩阵（m > n），经济QR分解为：
$$A = Q_1R_1$$

其中 $Q_1$ 是m×n矩阵，$R_1$ 是n×n上三角矩阵。

**优势**：节省存储空间和计算时间。

### 6.2 列主元QR分解

**定义**：在QR分解过程中选择列主元以提高数值稳定性。

**算法**：在每一步选择列中绝对值最大的元素作为主元。

### 6.3 加权QR分解

**定义**：考虑权重的QR分解：
$$\min_{Q,R} \|W(A - QR)\|_F$$

其中 $W$ 是权重矩阵。

**应用**：在加权最小二乘问题中使用。

## 7. 数值实现

### 7.1 Python实现

**使用NumPy**：
```python
import numpy as np
from scipy.linalg import qr

# 方法1：使用scipy
Q, R = qr(A)

# 方法2：手动实现Householder变换
def qr_decomposition_householder(A):
    m, n = A.shape
    Q = np.eye(m)
    R = A.copy()
    
    for j in range(min(m-1, n)):
        # 构造Householder矩阵
        x = R[j:, j]
        e1 = np.zeros_like(x)
        e1[0] = 1
        u = x - np.linalg.norm(x) * e1
        v = u / np.linalg.norm(u)
        
        # 应用Householder变换
        H = np.eye(m)
        H[j:, j:] -= 2 * np.outer(v, v)
        
        R = H @ R
        Q = Q @ H.T
    
    return Q, R
```

### 7.2 数值稳定性

**问题**：Gram-Schmidt正交化可能数值不稳定。

**解决方案**：
- 使用改进的Gram-Schmidt算法
- 使用Householder变换
- 使用Givens旋转

## QR分解关联的其它知识

- [LU分解](./4%20LU分解.md)
- [SVD分解](./3%20SVD分解.md)
- [特征值与特征向量](./1%20特征值与特征向量.md)
- [线性方程组求解](../4-应用/3%20多变量函数.md)
- [最小二乘问题](../4-应用/4%20机器学习中的线性代数.md)
- [线性代数知识](../线性代数知识.md) 