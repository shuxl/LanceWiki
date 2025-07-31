在“机器学习 逻辑回归 sklearn”中，**逻辑回归（Logistic Regression）** 是一种常用的**分类算法**，尽管名字中带有“回归”，它实际上用于**二分类**或**多分类问题**，而不是回归预测连续值。

---

# 1 逻辑回归的核心思想
#数学/回归 
逻辑回归的目标是：
	 根据输入特征 $x$，预测输出类别 $y \in \{0, 1\}$。

它使用的是 **线性模型 + Sigmoid 函数**：
## 1.1 线性部分：
$z = w^T x + b$
## 1.2 Sigmoid 函数（激活）：
$\sigma(z) = \frac{1}{1 + e^{-z}}$
输出值范围是 $(0, 1)$，可以被看作是样本属于类别 1 的概率。
## 1.3 预测规则：

	$\hat{y} = \begin{cases} 1, & \text{如果 } \sigma(z) \geq 0.5 \\ 0, & \text{否则} \end{cases}$
---
# 2 为什么叫“回归”？
因为它**拟合的是概率函数**，输出是一个连续值（概率），所以数学上是一个“回归问题”；但最终是为了做**分类**。

---

# 3 逻辑回归的损失函数

逻辑回归使用 **对数损失函数（Log Loss）** 或称 **交叉熵损失**：
$\mathcal{L}(y, \hat{y}) = - \left[ y \log(\hat{y}) + (1 - y) \log(1 - \hat{y}) \right]$
这个损失函数有两个作用：
- 惩罚错误的分类
- 使得模型输出更接近真实的类别概率

---

# 4 在 sklearn 中如何使用逻辑回归

```
from sklearn.linear_model import LogisticRegression
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split

加载数据（只用两类来做二分类示例）
X, y = load_iris(return_X_y=True)
X = X[y != 2]
y = y[y != 2]

划分训练集和测试集
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3)

建模
clf = LogisticRegression()
clf.fit(X_train, y_train)

预测
y_pred = clf.predict(X_test)
```

---

# 5 优缺点简述

**优点**：
- 简单易实现，运行快
- 输出概率，可解释性强
- 对小数据和线性可分问题效果好
**缺点**：
- 对异常值敏感
- 不能解决非线性问题（需要加多项式特征或用 kernel 方法）
- 精度不如复杂模型如 SVM、随机森林、神经网络等
