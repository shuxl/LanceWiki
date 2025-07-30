案例，对比 **牛顿法** 与 **拟牛顿法（L-BFGS）** 的表现效果。

+ [拟牛顿法 L-BFGS](../../../../500-基础理论/数学知识/算法/拟牛顿法%20L-BFGS.md)

---

# 1 **实现目标**

- 使用 PyTorch 中的 LBFGS 优化器（自带实现拟牛顿法）
- 和“手写 Hessian 的牛顿法”进行**收敛速度与精度的对比**
	- [204-PyTorch 使用 Hessian 的牛顿法优化](204-PyTorch%20使用%20Hessian%20的牛顿法优化.md)
- 同样优化函数：
    $f(x) = (x_0 - 3)^2 + (x_1 + 1)^2$

其最优解是 $x = [3, -1]$

---

# 2 **L-BFGS 原理简述**

- L-BFGS 是一种内存优化的拟牛顿法，不直接存 Hessian，而是用历史梯度和变量变化近似更新方向
- PyTorch 中通过 torch.optim.LBFGS 实现，适合中小规模参数优化
- 每次优化通过**闭包函数（closure）** 重新计算 loss 和梯度
    

---

# 3 **PyTorch 中 L-BFGS 的完整实现**

```
import torch

# 定义目标函数（和牛顿法一样）
def func(x):
    return (x[0] - 3)**2 + (x[1] + 1)**2

# 初始点
x = torch.tensor([0.0, 0.0], requires_grad=True)

# 定义 L-BFGS 优化器
optimizer = torch.optim.LBFGS([x], lr=1.0, max_iter=20, line_search_fn='strong_wolfe')

# 记录每步
def closure():
    optimizer.zero_grad()
    loss = func(x)
    loss.backward()
    return loss

for i in range(5):  # 通常1步就够了，这里多跑几步对比
    loss = optimizer.step(closure)
    print(f"Step {i+1}: x = {x.tolist()}, f(x) = {loss.item():.6f}")
```

---

运行结果示例（约 1-2 步收敛）：

```
Step 1: x = [2.999999761581421, -1.0000001192092896], f(x) = 0.000000
Step 2: x = [2.999999761581421, -1.0000001192092896], f(x) = 0.000000
...
```

可见：

- L-BFGS 几乎**一步**内就达到了极高精度
    
- 内部已经拟合了局部曲率（无需我们显式计算 Hessian）
    

---

# 4 **牛顿法 vs L-BFGS 对比总结**

|**维度**|**牛顿法**|**L-BFGS (拟牛顿法)**|
|---|---|---|
|是否需要 Hessian|是，且需要求逆|否（使用历史近似）|
|实现复杂度|高：手动实现梯度 + Hessian|低：PyTorch 优化器封装好了|
|收敛速度|理论上收敛快（尤其近极小值点）|实际中 L-BFGS 也非常快|
|适用场景|小规模优化、分析类应用|通用优化、模型训练、低内存友好|
|PyTorch 支持|autograd.functional.hessian|torch.optim.LBFGS|
