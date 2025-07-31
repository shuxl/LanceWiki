从基础概念到高级应用、源码理解，最终能灵活使用它进行科学计算、数据处理和机器学习中的数值运算。

下面是一套**从浅到深的 NumPy 学习路径**，分为五个阶段，每一阶段配有重点知识点、推荐练习和学习建议：

---

# 1 阶段一：基础入门（理解 NumPy 的本质）

**目标：理解 NumPy 的作用、掌握基本数组操作。**

**重点内容：**

- NumPy 安装与导入
    
- `ndarray` 对象介绍
    
- 创建数组（`array`、`zeros`、`ones`、`arange`、`linspace`、`eye`）
    
- 数组属性：`shape`、`dtype`、`ndim`、`size`、`itemsize`
    
- 简单的索引与切片
    

**练习建议：**

- 用 `arange` 创建一个从 0 到 20 的数组，每隔 2 个数
    
- 创建一个 3x3 的单位矩阵
    
- 提取一个二维数组中某一列或某几行的数据
    

---

# 2 阶段二：数组运算与广播机制（向量化思维）

**目标：理解数组之间的运算逻辑和广播规则，掌握常见的数学操作。**

**重点内容：**

- 数组加减乘除、指数、开方等运算
    
- 广播机制（Broadcasting）
    
- 通用函数（`np.add`、`np.sqrt`、`np.exp` 等）
    
- 逻辑运算与布尔索引
    
- 条件筛选（如 `a[a > 5]`）
    

**练习建议：**

- 生成一个数组，找出所有大于平均值的元素
    
- 实现两个不同形状数组的广播加法
    
- 用布尔索引过滤出偶数元素
    

---

# 3 阶段三：高级操作（变形、拼接、拆分）

**目标：学会构造、重组、连接、拆分数组。**

**重点内容：**

- 数组变形：`reshape`、`flatten`、`ravel`
    
- 数组拼接：`hstack`、`vstack`、`concatenate`
    
- 数组拆分：`split`、`hsplit`、`vsplit`
    
- 转置与轴变换：`T`、`transpose`、`swapaxes`
    

**练习建议：**

- 将一维数组 reshape 成 3x4 矩阵，再恢复为一维
    
- 拼接两个二维数组形成一个新数组
    
- 对数组按列拆分为多个子数组
    

---

# 4 阶段四：科学计算与实用函数

**目标：使用 NumPy 处理实际问题中的数值计算任务。**

**重点内容：**

- 统计运算：`mean`、`sum`、`min`、`max`、`argmax`、`std`
    
- 随机模块：`np.random.rand`、`randn`、`choice`、`seed`
    
- 线性代数：`dot`、`matmul`、`inv`、`eig`、`solve`
    
- 聚合函数与 `axis` 参数控制方向
    
- 向量化与性能比较
    

**练习建议：**

- 模拟投掷骰子 1000 次并统计各个点数的出现次数
    
- 用 `np.dot` 实现矩阵乘法
    
- 求解线性方程组 Ax = b
    

---

# 5 阶段五：性能优化与源码深入（可选高级进阶）

**目标：理解 NumPy 内部机制，提升性能和掌握与其他库的配合使用。**

**重点内容：**
- 内存布局与 `copy`/`view`
    
- `np.where`、`np.select`、`np.vectorize` 的应用
    
- 与 pandas、matplotlib、scikit-learn 协同使用
    
- NumPy C API、ufunc 实现机制（可选阅读源码）
    
- Cython/Numba 加速
    

**练习建议：**

- 用 NumPy 向量化实现 sigmoid 函数并绘图
    
- 对比循环 vs 向量化实现的耗时差异
    
- 尝试用 `np.where` 实现一个简单分类器
    

---

# 6 学习资源推荐

- 官方文档：[https://numpy.org/doc/stable/](https://numpy.org/doc/stable/)
- 图书推荐：
    - 《Python 数据科学手册》（Jake VanderPlas）
    - 《利用Python进行数据分析》（Wes McKinney）
