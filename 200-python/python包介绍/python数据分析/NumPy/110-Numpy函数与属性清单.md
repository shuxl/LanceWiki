下面是**阶段一**中涉及到的所有 Python / NumPy 函数、属性和用法汇总，你可以整理成笔记或文档。

---

# 1 **NumPy  函数与属性清单**

## 1.1 **一、模块导入**

- import numpy as np
---

## 1.2 **二、创建数组函数**

|**函数/方式**|**说明**|
|---|---|
|np.array(object)|从 Python 列表或元组创建数组|
|np.zeros(shape)|创建全 0 数组|
|np.ones(shape)|创建全 1 数组|
|np.arange(start, stop, step)|创建等差数组（不含 stop）|
|np.linspace(start, stop, num)|创建线性等分数组（含 stop）|
|np.eye(N)|创建 N×N 单位矩阵（对角为 1，其余为 0）|

---

## 1.3 **三、数组属性**

|**属性**|**说明**|
|---|---|
|ndarray.ndim|数组的维度数（几维）|
|ndarray.shape|数组的形状（各维度大小组成的元组）|
|ndarray.size|元素总数|
|ndarray.itemsize|单个元素占用的字节数|
|ndarray.dtype|元素的数据类型|

---

## 1.4 **四、索引与切片**

|**用法**|**说明**|
|---|---|
|a[i]|一维数组索引第 i 个元素|
|a[i:j]|一维数组切片，左闭右开|
|a[i] = x|修改指定位置的值|
|a[i, j]|二维数组第 i 行第 j 列元素|
|a[i, :]|第 i 行的所有列|
|a[:, j]|所有行的第 j 列|

---

## 1.5 **五、常见用途举例函数**

|**函数/方法**|**示例用法**|**说明**|
|---|---|---|
|reshape|a.reshape(3, 3)|改变数组形状|
|flatten|a.flatten()|展平成一维数组（返回新数组）|
|ravel|a.ravel()|展平成一维（返回视图）|
|astype|a.astype(np.float32)|转换元素数据类型|
