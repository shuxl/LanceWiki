### **一、核心原理与机制**

#### **1. 动态计算图（Dynamic Computational Graph）**

- **定义**：PyTorch 使用动态计算图（Define-by-Run），即每次前向传播时，根据实际执行过程动态构建计算图。
- **意义**：
    - 更灵活，便于调试（如 Python 的控制流 if/while 可参与图构建）
    - 每次调用 .backward() 都基于最新图结构

---

#### **2.requires_grad=True的意义**

- **作用**：标记该 Tensor 是否需要被 autograd 追踪。
- **影响**：
    - 若为 True，则所有对该张量的操作都会记录到计算图中。
    - 反向传播时，会自动计算该变量对 loss 的梯度。

```
x = torch.tensor(2.0, requires_grad=True)
```

---

#### **3..backward()自动反向传播**

- **功能**：对目标张量进行反向传播，自动计算出各个节点的梯度。
- **说明**：
    - 只能对标量调用（或传入 gradient= 参数）
    - 通常用于 loss 值

```
y.backward()  # 假设 y 是一个标量
```

---

#### **4. .grad属性获取梯度**

- .grad 是变量存储其对应梯度的位置
- 注意：只对 requires_grad=True 的张量有效
- .grad 的值在 .backward() 后才会被赋值

```
print(x.grad)  # 查看 x 对于 loss 的梯度
```

---

#### **5.torch.no_grad()与.detach()的使用场景**

- **torch.no_grad()**
    - 上下文管理器
    - 作用：禁止计算图构建，常用于推理阶段，节省内存和计算

```
with torch.no_grad():
    y = model(x)
```

- **.detach()**
    - 方法：返回一个不带梯度的新张量，切断与原图的连接

```
x_detached = x.detach()
```

---

### **二、示例与实战练习**
  
#### **1. 手动实现一个标量函数并用 PyTorch 求导**

```
import torch

# 定义变量
x = torch.tensor(3.0, requires_grad=True)

# 定义函数 y = x^2 + 2x + 1
y = x**2 + 2 * x + 1

# 自动反向传播
y.backward()

# 打印梯度 dy/dx
print(x.grad)  # 结果应该是 dy/dx = 2x + 2 = 2*3 + 2 = 8
```

---

#### **2. 梯度下降法（最小化一个简单函数）**

目标：最小化函数 f(x) = (x - 5)^2，初始 x = 0

```
x = torch.tensor(0.0, requires_grad=True)

lr = 0.1  # 学习率

for i in range(20):
    y = (x - 5)**2
    y.backward()
    with torch.no_grad():  # 更新参数时不需要计算梯度
        x -= lr * x.grad   # 梯度下降
        x.grad.zero_()     # 清零梯度

    print(f"Step {i+1}, x = {x.item():.4f}, y = {y.item():.4f}")
```

输出结果应逐步接近 x=5，y=0。

---

## **整体知识图谱总结**

```
Autograd 自动求导
├── 动态计算图
│   └── 运行时构建，灵活控制流
├── requires_grad
│   └── 标记变量是否参与梯度计算
├── 反向传播
│   ├── backward()
│   └── grad 属性
├── 阻断计算图
│   ├── torch.no_grad()
│   └── .detach()
└── 实战案例
    ├── 标量函数求导
    └── 梯度下降最小化函数
```

进阶内容：
- 多变量函数求导:
	- [201-PyTorch多变量函数求导](201-PyTorch多变量函数求导.md)
	- [202-PyTorch向量函数对向量变量的求导（Jacobian 雅可比矩阵）](202-PyTorch向量函数对向量变量的求导（Jacobian%20雅可比矩阵）.md)
- 中间变量的 .grad_fn 查看计算图结构
- 高阶导数（使用 create_graph=True）
- 对模型参数进行反向传播