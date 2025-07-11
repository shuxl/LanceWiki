#python/pandas
# 1 Series和DataFrame基本操作
- 熟练掌握访问 Series 和 DataFrame 中的数据
- 理解 .loc\[\]、.iloc\[\] 的用法和区别
- 学会常用的切片和条件筛选技巧

| **操作** | **方法**                                 |
| ------ | -------------------------------------- |
| 取列     | df\[\"列名\"\], df\[\[\"列1\", \"列2\"\]\] |
| 取行     | df.loc[标签], df.iloc[位置]                |
| 取单元格   | df.loc[标签, 列名]                         |
| 条件筛选   | df[df["列"] > 值]                        |
| 多条件筛选  | & 和 `                                  |
| 赋值（单个） | df.loc[行, 列] = 值                       |
| 赋值（整列） | df["新列"] = 值                           |

---

## 1.1 访问Series中的数据
### 1.1.1 通过标签访问（推荐）

```
import pandas as pd

s = pd.Series([100, 200, 300], index=["apple", "banana", "cherry"])
print(s["banana"])  # 输出：200
```

### 1.1.2 通过位置访问（不推荐，除非 index 是数字）

```
print(s[1])  # 输出：200
```

### 1.1.3 切片

```
print(s["apple":"cherry"])  # 包含结束值 cherry
```

---

## 1.2 访问DataFrame的列

```
df = pd.DataFrame({
    "name": ["Tom", "Lucy", "Anna"],
    "age": [25, 30, 28],
    "city": ["Beijing", "London", "New York"]
})

df["name"]        # 获取一列 Series
df[["name", "age"]]  # 获取多列，返回新的 DataFrame
```

---

## 1.3 访问DataFrame的行（重点！）
### 1.3.1 使用.loc\[\]—— 按“标签”取行

```
df.loc[0]         # 第一行，返回一个 Series
```

你也可以指定多个行：

```
df.loc[[0, 2]]
```

### 1.3.2 使用.iloc[]—— 按“位置”取行

```
df.iloc[1]        # 第二行
df.iloc[0:2]      # 前两行（不含结尾）
```

---

## 1.4 访问“单个单元格”

```
df.loc[1, "name"]      # 标签访问
df.iloc[1, 0]          # 位置访问
```

---

## 1.5 条件筛选（非常常用！）
### 1.5.1 筛选年龄 > 26 的人

```
df[df["age"] > 26]
```

### 1.5.2 组合多个条件

```
df[(df["age"] > 26) & (df["city"] == "London")]
```

注意：逻辑与 &、逻辑或 |，每个条件都要用括号包裹！

---

## 1.6 赋值操作（修改数据）

```
df.loc[0, "age"] = 26         # 修改 age
df["country"] = "China"       # 所有行赋相同值
df["salary"] = [5000, 6000, 7000]  # 新列赋不同值
```


# 2 pandas 文件读写

- 掌握如何读取和写入常见文件格式：CSV、Excel、JSON
- 理解常用参数：编码、分隔符、索引列、列选择等
- 避免常见数据格式陷阱（如字段中含分隔符）

---

## 2.1 读取文件

### 2.1.1 CSV 文件

- 使用 pd.read_csv("文件路径")
- 常用参数：
    - sep：分隔符，默认 ,，可设为 "\t" 读取 TSV
    - encoding：避免中文乱码，常用 "utf-8" 或 "gbk"
    - index_col：指定哪一列作为索引列
    - usecols：读取指定列
    - nrows：只读取前几行

### 2.1.2 Excel 文件

- 使用 pd.read_excel("路径", sheet_name="...")
- 需要安装依赖：openpyxl（用于 .xlsx）

### 2.1.3 JSON 文件

- 使用 pd.read_json("路径")
- 通常 JSON 需为列表形式，每行一个对象

---

## 2.2 写出文件
### 2.2.1 CSV 写出
- 使用 to_csv("路径", index=False, encoding="utf-8")
- index=False 表示不写出行索引（更干净）
- 若中文乱码可用 gbk 编码
  
### 2.2.2 Excel 写出
- 使用 to_excel("路径", index=False)
- 自动处理 sheet 名和格式

### 2.2.3 JSON 写出

- 使用 to_json("路径", orient="records", force_ascii=False)
    - orient="records"：每行一个对象（推荐）
    - force_ascii=False：避免中文变成 \uXXXX


# 3 数据清洗与缺失值处理（技巧）

- 学会识别和处理缺失值（如 NaN）
- 掌握常见的数据清洗操作
- 熟悉列/行的添加、删除、重命名与类型转换等方法

| **清洗任务** | **pandas 方法**          |
| -------- | ---------------------- |
| 判断缺失值    | isnull(), notnull()    |
| 删除缺失行/列  | dropna()               |
| 填充缺失值    | fillna()               |
| 删除列/行    | drop()                 |
| 改列名      | rename()               |
| 改类型      | astype()、to_datetime() |

---

## 3.1 识别缺失值

pandas 中的缺失值通常表示为：NaN（Not a Number）

### 3.1.1 常用方法：

|**方法**|**功能**|
|---|---|
|df.isnull()|判断是否为缺失值，返回布尔 DataFrame|
|df.notnull()|判断是否非缺失值|
|df.isnull().sum()|每列中缺失值的数量|

---

## 3.2 处理缺失值

|**方法**|**功能**|
|---|---|
|df.dropna()|删除含有缺失值的行|
|df.dropna(axis=1)|删除含有缺失值的列|
|df.fillna(0)|用 0 替换所有缺失值|
|df.fillna(method="ffill")|用前一个非缺失值填充（向前填充）|
|df.fillna(method="bfill")|向后填充|

你也可以用某列的**平均值、中位数、众数**来填补缺失值（进阶用法）。

---

## 3.3 删除数据

|**方法**|**功能**|
|---|---|
|df.drop("列名", axis=1)|删除指定列|
|df.drop(行号或标签, axis=0)|删除指定行|
|inplace=True|表示**直接修改原对象**，不返回副本|

---

## 3.4 重命名列名或索引

|**方法**|**功能**|
|---|---|
|df.rename(columns={"原名": "新名"})|修改列名|
|df.columns = [...]|直接设置所有列名|

---

## 3.5 数据类型转换

|**方法**|**功能**|
|---|---|
|df["列"].astype("int")|转换为整数|
|df["列"].astype("str")|转换为字符串|
|pd.to_datetime(df["列"])|转换为时间格式|

---

## 3.6 典型数据清洗流程

1. **检查缺失值**：df.isnull().sum()
2. **决定处理方式**：
    - 删除：dropna()
    - 填充：fillna()（0、前值、均值等）
3. **列重命名**：rename()
4. **数据类型标准化**：astype() / to_datetime()
5. **删除无用列**：drop()

---

# 4 pandas 的数据选择、逻辑判断与过滤

## 4.1 Day 5 学习目标

- 熟练使用布尔索引进行条件过滤
- 理解 .loc\[\] 和 .iloc\[\] 的高级用法
- 学会组合多个筛选条件
- 掌握筛选行和列的各种方式

---

## 4.2 按列值筛选（布尔索引）

```
df[df["score"] > 80]
```

这会返回所有 "score" 大于 80 的行。

也可以存为变量 filtered_df = ... 以供后续使用。

---

## 4.3 组合多个条件

| **条件类型** | **写法**             | **注意**    |
| -------- | ------------------ | --------- |
| 与（and）   | (cond1) & (cond2)  | 每个条件必须加括号 |
| 或（or）    | (cond1) \| (cond2) | 使用 `      |
| 非（not）   | ~(cond)            | 用 ~ 取反    |

示例：找出年龄 > 25 且城市为 “Beijing” 的人

```
df[(df["age"] > 25) & (df["city"] == "Beijing")]
```

---

## 4.4 使用.loc\[\] 和.iloc\[\]的组合访问

### 4.4.1 .loc\[行标签, 列标签\]（常用）

```
df.loc[df["score"] > 60, ["name", "score"]]
```

选出 **分数大于 60** 的人的 **姓名和分数**。
### 4.4.2 .iloc\[行号, 列号\]（按位置）

```
df.iloc[0:3, 1:3]  # 前三行、第2~3列
```

---

## 4.5 筛选特定值：isin() / str.contains()

### 4.5.1 查找是否属于某个集合

```
df[df["city"].isin(["Beijing", "Shanghai"])]
```

### 4.5.2 查找文本中是否包含某关键词（模糊搜索）

```
df[df["name"].str.contains("Li")]
```

> 🔍 .str 是专门用于处理字符串列的子模块。

---

## 4.6 选择列的方法对比

| **方法**                              | **说明**          |
| ----------------------------------- | --------------- |
| df\["col"\]                         | 获取单列（Series）    |
| df\[\[\"col1\", \"col2\"\]\]        | 获取多列（DataFrame） |
| df.loc\[:, \[\"col1\", \"col2\"\]\] | 获取指定列           |
| df.iloc\[:, \[0, 2\]\]              | 按位置选择列          |

---

## 4.7 小结速查表

| **任务**   | **方法**                   |
| -------- | ------------------------ |
| 筛选条件     | df\[ df\[\"列\"\] \> 值 ]  |
| 多条件组合    | (cond1) & (cond2)        |
| 条件 + 指定列 | df.loc[条件, ["列1", "列2"]] |
| 判断是否属于集合 | .isin([...])             |
| 字符串模糊匹配  | .str.contains("关键字")     |
| 使用标签选行列  | .loc[行条件, 列名列表]          |
| 使用位置选行列  | .iloc[行范围, 列范围]          |


# 5 数据分组（groupby）、聚合（aggregation）与统计分析(核心)

- 理解 groupby 的原理和用法
- 掌握常用聚合函数（如 sum(), mean(), count() 等）
- 学会对分组结果进行多维度聚合和自定义聚合
- 了解如何对分组结果进行排序和筛选

---

## 5.1 groupby基础

- groupby 把 DataFrame 按某列（或多列）分组，返回一个“分组对象”
- 你可以对每个组单独执行聚合操作

---

## 5.2 常用聚合函数

|**函数**|**说明**|
|---|---|
|sum()|求和|
|mean()|计算平均值|
|count()|计数，非空值数量|
|max() / min()|最大值 / 最小值|
|median()|中位数|
|std() / var()|标准差 / 方差|

---

## 5.3 单列分组聚合
例如：
- 按“城市”分组，统计每个城市的平均分
---
## 5.4 多列分组聚合
- 可以用多列作为分组键，比如按“城市”和“性别”同时分组

---

## 5.5 自定义聚合函数
- 使用 .agg() 可以传入一个函数或多个函数，对不同列做不同聚合

---

## 5.6 分组后排序和筛选
- 对聚合结果排序，找出最大/最小的组
- 利用 filter() 过滤满足条件的组

---

## 5.7 Day 6 小结

|**功能**|**方法示例**|
|---|---|
|分组|df.groupby("列名")|
|聚合|.sum(), .mean(), .count(), .agg()|
|多列分组|df.groupby(["列1", "列2"])|
|多聚合|.agg({"列1": "sum", "列2": "mean"})|
|过滤分组|.filter(lambda x: x["列"].sum() > 100)|
|排序聚合结果|.sort_values()|
