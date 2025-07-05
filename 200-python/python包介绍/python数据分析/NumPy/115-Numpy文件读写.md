
# 1 **一、文件操作**

## 1.1 **1. 文本文件读写**

|**函数**|**用法**|**说明**|
|---|---|---|
|np.loadtxt(fname, delimiter=',')|读取纯文本文件（CSV/TXT）|通常用于规则结构的表格数据|
|np.savetxt(fname, array, delimiter=',', fmt='%.2f')|保存数组为文本|支持格式控制|
|np.genfromtxt(fname, delimiter=',', filling_values=0)|更强健的文本读取|可处理缺失值、带表头数据|

---

## 1.2 **2. 二进制文件读写（npy/npz）**

|**函数**|**用法**|**说明**|
|---|---|---|
|np.save('a.npy', arr)|保存单个数组为 .npy 文件|结构化存储|
|np.load('a.npy')|读取 .npy 文件|自动还原原数组结构|
|np.savez('file.npz', arr1=..., arr2=...)|保存多个数组|以键值对方式打包为 .npz|
|np.load('file.npz')['arr1']|读取 .npz 中指定数组|类似字典访问方式|

---

# 2 **二、随机数生成**

  

## 2.1 **1. 基本随机数**

|**函数**|**用法**|**说明**|
|---|---|---|
|np.random.rand(d0, d1, ...)|均匀分布 [0,1)|多维支持|
|np.random.randn(d0, d1, ...)|标准正态分布 N(0,1)||
|np.random.randint(low, high, size)|整数随机数|包含 low，不含 high|
|np.random.random(size)|等价于 rand|更通用接口|

---

## 2.2 **2. 抽样与洗牌**

|**函数**|**用法**|**说明**|
|---|---|---|
|np.random.choice(a, size, replace=False, p=None)|随机抽样|可指定是否放回、概率分布|
|np.random.shuffle(x)|原地打乱|修改原数组，适用于一维或打乱行顺序|
|np.random.permutation(x)|打乱副本|不修改原数组，返回新数组|

---

## 2.3 **3. 控制随机性**

|**函数**|**用法**|**说明**|
|---|---|---|
|np.random.seed(seed)|设置随机种子|保证结果可复现|

---

## 2.4 **4. 特定概率分布模拟**

|**函数**|**分布类型**|**示例**|
|---|---|---|
|np.random.normal(loc, scale, size)|正态分布 N(μ, σ²)|np.random.normal(0, 1, 100)|
|np.random.uniform(low, high, size)|均匀分布|np.random.uniform(0, 1, 10)|
|np.random.binomial(n, p, size)|二项分布|np.random.binomial(10, 0.5, 100)|
|np.random.poisson(lam, size)|泊松分布|np.random.poisson(3, 100)|

---

# 3 **文件操作**

- 使用 savetxt() 保存数组为 CSV，再用 loadtxt() 读回
    
- 使用 savez() 保存多个变量，再读回校验 shape 和内容
    
- 读取带空值的数据，使用 genfromtxt() 补全空值为 0
    

  

# 4 **随机数生成**

- 用 randint() 模拟抛骰子 100 次
    
- 用 choice() 抽样测试集
    
- 用 shuffle() 打乱样本顺序
    
- 用 seed() 确保实验可复现
