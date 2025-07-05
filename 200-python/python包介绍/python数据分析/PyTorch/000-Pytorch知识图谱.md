下面是一个 PyTorch 核心知识图谱的简要版，涵盖从基础到进阶的学习路径，方便你对 PyTorch 进行系统性学习。你可以基于这些模块逐步深入。

+ [100-PyTorch介绍](100-PyTorch介绍.md)
+ [110-PyTorch不同学习方向的知识图谱](110-PyTorch不同学习方向的知识图谱.md)
+ [200-PyTorch通用基础知识](200-PyTorch通用基础知识.md)

---


# 1 **一、基础部分（理解 PyTorch 的基本用法）**

- **Tensor 张量操作**
    
    - 创建张量：torch.tensor, torch.zeros, torch.ones, torch.rand
        
    - 张量属性：shape、dtype、device
        
    - 张量操作：索引、切片、广播、转置、维度变换（view, reshape）
        
    - 数学操作：加减乘除、矩阵乘法、聚合操作（mean、sum）
        
    - 与 NumPy 的交互
        
    
- **自动求导机制（Autograd）**
    
    - requires_grad、backward()、grad
        
    - 动态计算图机制（Dynamic Computational Graph）
        
    - torch.no_grad()、detach() 的使用
        
    
- **模型构建模块（torch.nn）**
    
    - nn.Module 的继承与定义
        
    - 常用层：nn.Linear、nn.Conv2d、nn.ReLU、nn.BatchNorm、nn.Dropout
        
    - 模型参数管理：model.parameters()、state_dict()
        
    

  

# 2 **二、中级部分（训练与优化）**

- **损失函数（torch.nn.functional / nn）**
    
    - 回归问题：MSELoss
        
    - 分类问题：CrossEntropyLoss、NLLLoss
        
    - 自定义损失函数
        
    
- **优化器（torch.optim）**
    
    - 常用优化器：SGD、Adam、RMSprop
        
    - 参数更新：optimizer.step()、optimizer.zero_grad()
        
    
- **训练与验证流程**
    
    - for epoch in range(...)
        
    - 模型训练/评估模式切换：model.train()、model.eval()
        
    - 梯度清零与更新
        
    - 可视化 loss 和 accuracy（如使用 matplotlib）
        
    

  

# 3 **三、数据处理（torch.utils.data）**

- **数据集与数据加载**
    
    - Dataset、DataLoader
        
    - 内置数据集（如 MNIST、CIFAR）
        
    - 自定义数据集与变换
        
    - transforms：数据增强、归一化
        
    

  

# 4 **四、进阶部分（工程化与性能）**

- **模型保存与加载**
    
    - torch.save() / torch.load() / load_state_dict()
        
    
- **GPU 加速与多卡训练**
    
    - .to(device)、.cuda()、.cpu()
        
    - DataParallel、DistributedDataParallel
        
    
- **性能优化**
    
    - Mixed Precision（torch.cuda.amp）
        
    - Dataloader 多线程 num_workers
        
    - JIT 编译与 TorchScript
        
    

  

# 5 **五、常见模型与应用**

- **图像分类**
    
- **自然语言处理（NLP）**
    
- **时间序列预测 / RNN / LSTM**
    
- **Transformer / BERT 等高级模型（结合 HuggingFace 使用）**
    

---

2 **学习建议**

  

你可以按照如下顺序逐步深入：

1. **入门训练任务：** 用 MNIST 手写数字识别做完整的训练流程。
    
2. **逐步优化：** 添加验证集、Early Stopping、模型保存、绘图。
    
3. **看源码理解：** 如 nn.Linear、backward 内部逻辑。
    
4. **工程实践：** 尝试 PyTorch Lightning、FastAI 等封装库。
    
