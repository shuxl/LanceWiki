Scikit-learn（常缩写为 sklearn）是 Python 中最常用、功能最全的 **机器学习库之一**，建立在 NumPy、SciPy 和 matplotlib 基础上。它提供了丰富的算法和工具，适用于数据挖掘、数据分析、以及构建机器学习模型。

---

# 1 一句话总结

> Scikit-learn 是一个简单易用、功能强大的 Python 机器学习库，涵盖从数据预处理、特征选择、建模到评估的完整流程。

---

# 2 安装

```
pip install scikit-learn
```

---

# 3 核心功能模块

| **模块**                  | **功能说明**              |
| ----------------------- | --------------------- |
| sklearn.datasets        | 提供一些经典数据集（如鸢尾花、波士顿房价） |
| sklearn.preprocessing   | 数据预处理（如标准化、归一化、编码）    |
| sklearn.model_selection | 数据集切分、交叉验证、网格搜索等      |
| sklearn.linear_model    | 线性模型，如线性回归、逻辑回归       |
| sklearn.tree            | 决策树、随机森林等             |
| sklearn.svm             | 支持向量机                 |
| sklearn.cluster         | 无监督学习（如K均值）           |
| sklearn.metrics         | 评估指标，如准确率、召回率、F1分数    |
| sklearn.pipeline        | 构建机器学习流水线             |

---

# 4 示例：一个典型的监督学习流程

```
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

加载数据
iris = load_iris()
X, y = iris.data, iris.target

划分训练集和测试集
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

数据标准化
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

模型训练
clf = RandomForestClassifier()
clf.fit(X_train, y_train)

模型预测与评估
y_pred = clf.predict(X_test)
print("Accuracy:", accuracy_score(y_test, y_pred))
```

---

# 5 支持的学习类型

|**类型**|**支持的算法示例**|
|---|---|
|**监督学习**|线性回归、逻辑回归、SVM、KNN、决策树、随机森林|
|**无监督学习**|KMeans、DBSCAN、主成分分析（PCA）|
|**模型选择与调参**|GridSearchCV、RandomizedSearchCV、交叉验证|
|**特征选择与降维**|SelectKBest、PCA、L1正则|

---

# 6 优点总结
- 简单易用，API 风格统一
- 文档齐全、社区活跃
- 和 NumPy/Pandas 等配合良好
- 可与 TensorFlow、PyTorch 搭配使用作预处理或轻量建模