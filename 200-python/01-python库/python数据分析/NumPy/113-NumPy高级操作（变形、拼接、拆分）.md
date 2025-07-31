
# 1 **一、数组变形（Reshape）**

|**函数/属性**|**示例**|**说明**|
|---|---|---|
|reshape()|a.reshape(3, 4)|改变数组形状，不改变数据本身|
|reshape(-1, n)|a.reshape(-1, 2)|自动推导另一个维度|
|flatten()|a.flatten()|展平为一维数组（**返回新副本**）|
|ravel()|a.ravel()|展平为一维数组（**返回视图，共享内存**）|

---

# 2 **二、数组转置（Transpose）**

|**函数/属性**|**示例**|**说明**|
|---|---|---|
|.T|a.T|快捷方式，二维数组转置|
|transpose()|np.transpose(a)|通用转置，支持多维数组|
|transpose((axes))|np.transpose(a, (0, 2, 1))|多维数组的轴重排|

---

# 3 **三、数组拼接（Concatenate & Stack）**

|**函数**|**示例**|**说明**|
|---|---|---|
|concatenate()|np.concatenate((a, b), axis=0)|沿指定轴拼接数组（需要形状匹配）|
|hstack()|np.hstack((a, b))|横向拼接（axis=1）|
|vstack()|np.vstack((a, b))|纵向拼接（axis=0）|
|stack()|np.stack((a, b), axis=0)|增加新维度后拼接|
|dstack()|np.dstack((a, b))|深度方向拼接（axis=2），用于图像处理（RGB等）|

---

# 4 **四、数组拆分（Split）**

|**函数**|**示例**|**说明**|
|---|---|---|
|split()|np.split(a, 2, axis=1)|沿指定轴拆分为相等份数|
|hsplit()|np.hsplit(a, 2)|横向拆分（等价于 axis=1）|
|vsplit()|np.vsplit(a, 2)|纵向拆分（等价于 axis=0）|

---

# 5 **五、常用属性（辅助）**

|**属性**|**示例**|**说明**|
|---|---|---|
|shape|a.shape|获取/设置数组形状|
|ndim|a.ndim|数组的维度数|

