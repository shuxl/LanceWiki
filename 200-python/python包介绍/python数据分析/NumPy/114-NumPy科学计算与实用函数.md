
# 1 **一、聚合计算（Aggregation）**

| **函数名**      | **功能** | **示例**             | **备注**  |
| ------------ | ------ | ------------------ | ------- |
| np.sum(a)    | 求和     | np.sum(a)          | 可加 axis |
| np.mean(a)   | 平均值    | np.mean(a, axis=0) |         |
| np.std(a)    | 标准差    | np.std(a)          |         |
| np.var(a)    | 方差     | np.var(a)          |         |
| np.min(a)    | 最小值    | np.min(a)          |         |
| np.max(a)    | 最大值    | np.max(a)          |         |
| np.argmin(a) | 最小值索引  | np.argmin(a)       | 返回扁平索引  |
| np.argmax(a) | 最大值索引  | np.argmax(a)       |         |

---

# 2 **二、逻辑判断与布尔运算**

|**函数名**|**功能**|**示例**|**说明**|
|---|---|---|---|
|np.any(a)|是否有 True|np.any(a > 0)|任意为真则为 True|
|np.all(a)|是否全为 True|np.all(a > 0)||
|np.count_nonzero(a)|非零元素计数|np.count_nonzero(a)|常用于统计|

---

# 3 **三、排序相关函数**

|**函数名**|**功能**|**示例**|**说明**|
|---|---|---|---|
|np.sort(a)|返回排序后的新数组|np.sort(a)|原数组不变|
|np.argsort(a)|返回排序索引|np.argsort(a)|可用于重排原数组|
|np.sort(a, axis=0)|指定维度排序|np.sort(a, axis=1)|多维数组排序|

---

# 4 **四、唯一值与去重分析**

|**函数名**|**功能**|**示例**|**说明**|
|---|---|---|---|
|np.unique(a)|获取唯一元素|np.unique(a)|默认升序排序|
|np.unique(a, return_counts=True)|唯一元素及出现次数|uniq, count = np.unique(a, return_counts=True)|返回频数统计|

---

# 5 **五、数学函数（支持广播）**

| **函数名**              | **功能** | **示例**                  |
| -------------------- | ------ | ----------------------- |
| np.abs(x)            | 绝对值    | np.abs([-3, 4])         |
| np.sqrt(x)           | 开方     | np.sqrt([1, 4, 9])      |
| np.exp(x)            | $e^x$  | np.exp([1, 2])          |
| np.log(x)            | 自然对数   | np.log([1, np.e])       |
| np.log10(x)          | 常用对数   | np.log10([1, 10])       |
| np.power(x, y)       | 幂运算    | np.power(2, 3)          |
| np.clip(x, min, max) | 限定区间   | np.clip([1, 20], 0, 10) |

---

# 6 **六、基础线性代数函数（来自np.linalg）**

|**函数名**|**功能**|**示例**|
|---|---|---|
|np.dot(a, b)|点积（矩阵乘法）|np.dot(a, b)|
|a @ b|点积简写|a @ b|
|np.linalg.inv(a)|矩阵求逆|np.linalg.inv(a)|
|np.linalg.det(a)|矩阵行列式|np.linalg.det(a)|
|np.linalg.eig(a)|特征值与特征向量|np.linalg.eig(a)|
