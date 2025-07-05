1. 掌握 sklearn 中使用模型训练和预测的基本流程
2. 学会使用逻辑回归完成分类任务
3. 学会使用常见的评估指标（准确率、混淆矩阵）

关联知识
+ [141-sklearn 机器学习 逻辑回归](141-sklearn%20机器学习%20逻辑回归.md)

---

# 1 机器学习基本流程回顾（在 sklearn 中如何实现）

| 步骤    | sklearn 中实现方式                             |
| ----- | ----------------------------------------- |
| 加载数据  | `sklearn.datasets`                        |
| 数据预处理 | `StandardScaler` 等                        |
| 划分数据  | `train_test_split`                        |
| 选择模型  | `sklearn.linear_model.LogisticRegression` |
| 模型训练  | `.fit(X_train, y_train)`                  |
| 模型预测  | `.predict(X_test)`                        |
| 模型评估  | `accuracy_score`、`confusion_matrix`       |

---

# 2 逻辑回归分类实战

我们用经典的鸢尾花数据（iris）来做演示，目标是预测花的类别（共 3 类）。

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix
import pandas as pd

1. 加载数据
iris = load_iris()
X = iris.data
y = iris.target

2. 划分数据
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

3. 数据标准化
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

4. 训练模型
clf = LogisticRegression(max_iter=200)
clf.fit(X_train, y_train)

5. 预测
y_pred = clf.predict(X_test)

6. 评估模型
acc = accuracy_score(y_test, y_pred)
print("Accuracy 准确率：", acc)

print("混淆矩阵：")
print(confusion_matrix(y_test, y_pred))
```

## 2.1 random_state 
是随机数种子。train_test_split(X, y, test_size=0.2, random_state=42)
+ 这里会涉及到伪随机算法 #算法/伪随机
+ [142-Python 中的 伪随机算法](142-Python%20中的%20伪随机算法.md)
## 2.2 数据标准化步骤理解
python 实现逻辑 #数学/标准化 
``` python
# 计算训练集 X_train 的均值和标准差，并应用标准化变换（Z-score）
X_train = scaler.fit_transform(X_train)
# 使用训练集 X_train 的均值和标准差对测试集 X_test 进行相同的变换（不再重新计算）
X_test = scaler.transform(X_test)
```
+ **关键区别：是否“重新拟合（fit）”**
	- fit_transform(X_train)
	    👉 **计算 + 变换**
	    用于训练集，得到训练集的 μ（均值） 和 σ（标准差）：
	    z = \frac{x - \mu_{\text{train}}}{\sigma_{\text{train}}}
	- transform(X_test)
	    👉 **只变换，不重新计算**
	    用在测试集上，使用的是训练集 μ 和 σ，不是测试集自己的。
+ 为什么不能对 X_test 使用 fit_transform()？
	+ 如果写成`X_test = scaler.fit_transform(X_test)`
		+ 那就会 **用测试集自己的均值和标准差进行标准化**，这在机器学习中会导致“数据泄漏（data leakage）”。
		+ **数据泄漏问题：** 模型在测试集上“看到了”未来信息（即测试集的统计特性），从而使评估结果不真实、不可靠。

---

# 3 逻辑回归简介

| 项目  | 内容                     |
| --- | ---------------------- |
| 类型  | 监督学习 - 分类              |
| 目标  | 预测离散标签，如 0/1 或 多类别     |
| 本质  | 使用 sigmoid 函数拟合概率，判定类别 |
| 优点  | 简单、可解释、速度快             |
| 限制  | 对特征要求线性可分、对离群值敏感       |


---

# 4 评估指标解释

- **准确率 accuracy**：预测对的数量 / 总样本数
- **混淆矩阵 confusion matrix**：细化看错/看对了哪些类别
    - 对于多分类问题，混淆矩阵是一个 `n x n` 的方阵（n = 类别数）
    - 主对角线表示预测正确的样本数
    - 非对角线的数值越少越好

