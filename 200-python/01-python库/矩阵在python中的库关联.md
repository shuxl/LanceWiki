#python/库
#数学/线性代数/矩阵-python



# 1 通用数值计算库（矩阵运算基础）

## 1.1 ① `numpy`（最核心）

- 用途：矩阵创建、运算、转置、求逆、线性代数等
- 常用模块：
    - `np.array`, `np.dot`, `np.linalg.inv`, `np.matmul`, `np.linalg.eig`
- 特点：所有后续库（如 PyTorch、Pandas）都以 `numpy` 为基础
- 举例：
    ```python
    import numpy as np
    A = np.array([[1, 2], [3, 4]])
    B = np.array([[5], [6]])
    result = np.dot(A, B)
    ```

## 1.2 ② `scipy.linalg`

- 用途：比 `numpy.linalg` 更丰富的线性代数操作
- 支持：LU 分解、QR 分解、SVD、广义逆等
- 举例：
    ```python
    from scipy.linalg import svd
    U, S, VT = svd(A)
    ```
    

---

# 2 科学计算与AI框架（矩阵=核心）

## 2.1 ③ `pytorch`（矩阵就是张量）
- 用途：深度学习，自动求导，神经网络的核心计算单位就是矩阵/张量
- 常用类：
    - `torch.Tensor`, `torch.matmul`, `torch.mm`, `torch.nn.Linear`
- 特点：
    - 计算图支持
    - GPU 加速（CUDA）
- 举例：
    ```python
    import torch
    A = torch.tensor([[1., 2.], [3., 4.]])
    B = torch.tensor([[5.], [6.]])
    C = torch.matmul(A, B)
    ```
    

## 2.2 ④ `tensorflow`

- 用途：同 PyTorch，矩阵/张量是基本单位
- 适合：图计算、神经网络
    

---

# 3 数据分析与预处理

## 3.1 ⑤ `pandas`

- 用途：虽然主用的是 `DataFrame`，但底层本质是 `numpy` 矩阵
- 行为上接近 SQL 表结构，但很多运算（如 `.dot()`、`.cov()`）会涉及矩阵
- 举例：
    ```python
    import pandas as pd
    df = pd.DataFrame([[1, 2], [3, 4]])
    result = df.dot([5, 6])
    ```

## 3.2 ⑥ `statsmodels`

- 用途：用于统计建模与线性回归
- 底层大量线性代数计算（使用 `numpy`, `scipy`）

---

# 4 机器学习/降维/矩阵分解相关

## 4.1 ⑦ `sklearn`（scikit-learn）
- 用途：机器学习中的 PCA、SVM、线性回归、聚类等，大量使用矩阵
- 底层：调用了 `numpy`, `scipy`
- 举例：PCA 使用矩阵协方差与特征值分解
    

## 4.2 ⑧ `cvxpy`（凸优化）

- 用途：数学规划与矩阵约束求解
- 特点：变量、约束、目标函数均为矩阵形式

---

# 5 数学可视化与教学辅助

## 5.1 ⑨ `matplotlib` + `numpy`
- 绘制矩阵图像、热力图、向量场
- 用于教学、调试矩阵行为

---

# 6 总结对比表（重点推荐）

|库名|主要用途|是否以矩阵为核心|特别适合场景|
|---|---|---|---|
|`numpy`|基础数值计算|✅|所有矩阵操作基础|
|`scipy.linalg`|高阶线性代数|✅|求逆、分解、奇异值处理|
|`pytorch`|深度学习|✅（张量）|AI 训练与推理|
|`tensorflow`|深度学习|✅（张量）|图计算优化|
|`pandas`|数据处理，底层用矩阵|⚠️|表格数据预处理|
|`sklearn`|机器学习（用矩阵）|✅|PCA、分类器、回归等|
|`statsmodels`|回归与统计分析|✅|线性模型，OLS 回归|
