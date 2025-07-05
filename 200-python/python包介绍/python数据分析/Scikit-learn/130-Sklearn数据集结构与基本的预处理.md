1. 掌握如何加载、查看和理解 sklearn 数据集
2. 学会基本的数据探索与清洗
3. 学会使用 sklearn 的预处理模块对数据做标准化、编码等操作
# 1 Sklearn 数据集结构

以 `load_iris()` 为例，sklearn 的内置数据集是一个类似字典的 `Bunch` 对象，常包含以下字段：

```python
{
  data: 特征值数组（numpy.ndarray）,
  target: 标签值数组,
  feature_names: 特征名,
  target_names: 类别名,
  DESCR: 描述,
}
```

---

# 2 数据探索实战

```python
from sklearn.datasets import load_iris
import pandas as pd

# 加载数据
iris = load_iris()

# 转为 DataFrame 便于查看
df = pd.DataFrame(iris.data, columns=iris.feature_names)
df['target'] = iris.target

# 查看前几行
print(df.head())

# 统计每类数量
print(df['target'].value_counts())

# 显示每个特征的统计描述
print(df.describe())
```

---

# 3 预处理基础

机器学习模型要求输入数据是**数值型、无缺失、分布良好**的，因此通常需要以下几步预处理：

## 3.1 特征标准化（StandardScaler）

> 把所有特征缩放到标准正态分布（均值0、方差1）

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
X_scaled = scaler.fit_transform(iris.data)
print(X_scaled[:5])  # 查看前5条处理后的结果
```

---

## 3.2 标签编码（LabelEncoder）

> 把分类字符串转为整数，例如："setosa" -> 0

（Iris 数据是数值标签，不需转换）

如果你有分类文本数据：

```python
from sklearn.preprocessing import LabelEncoder

labels = ['cat', 'dog', 'dog', 'cat']
encoder = LabelEncoder()
encoded = encoder.fit_transform(labels)
print(encoded)  # 输出：[0 1 1 0]
```

---

## 3.3 划分训练集与测试集（train_test_split）

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.2, random_state=42
)

print("训练集大小：", X_train.shape)
print("测试集大小：", X_test.shape)
```

---

# 4 使用pandas的describe()方法查看数据
``` python
# 创建DataFrame，使用鸢尾花数据集的特征名称

feature_names = ['sepal_length', 'sepal_width', 'petal_length', 'petal_width']

X_train_df = pd.DataFrame(X_train, columns=feature_names)

# 显示数据统计描述

print("\n2. 数据统计描述 (describe()):")

print(X_train_df.describe())
```

```
2. 数据统计描述 (describe()):
       sepal_length  sepal_width  petal_length  petal_width
count    120.000000   120.000000    120.000000   120.000000
mean       5.809167     3.061667      3.726667     1.183333
std        0.823805     0.449123      1.752345     0.752289
min        4.300000     2.000000      1.000000     0.100000
25%        5.100000     2.800000      1.500000     0.300000
50%        5.750000     3.000000      4.250000     1.300000
75%        6.400000     3.400000      5.100000     1.800000
max        7.700000     4.400000      6.700000     2.500000
```


