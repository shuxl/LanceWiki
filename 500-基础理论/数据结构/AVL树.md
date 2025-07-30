

# 1 AVL树概念或介绍

**重点内容：**
- AVL树是一种自平衡的二叉搜索树
- 通过平衡因子（左子树高度 - 右子树高度）来维护平衡
- 平衡因子的绝对值不超过1
- 插入和删除操作后需要进行旋转调整
- 时间复杂度：查找、插入、删除均为O(log n)

AVL树（Adelson-Velsky and Landis Tree）是由G. M. Adelson-Velsky和E. M. Landis在1962年发明的自平衡二叉搜索树。它是最早被发明的自平衡二叉搜索树之一。

## 1.1 基本特性

1. **二叉搜索树性质**：左子树的所有节点值小于根节点，右子树的所有节点值大于根节点
2. **平衡性质**：对于树中的每个节点，其左子树和右子树的高度差不超过1
3. **平衡因子**：定义为左子树高度减去右子树高度，取值范围为{-1, 0, 1}

# 2 平衡因子

平衡因子是AVL树的核心概念，用于判断树是否平衡：

```
平衡因子 = 左子树高度 - 右子树高度
```

- 平衡因子 = 0：左右子树高度相等
- 平衡因子 = 1：左子树比右子树高1
- 平衡因子 = -1：右子树比左子树高1
- 平衡因子 = 2 或 -2：树不平衡，需要旋转调整

# 3 旋转操作

AVL树通过四种旋转操作来维护平衡：

## 3.1 左旋（Left Rotation）

当节点的右子树过高时使用左旋：

```
    A                    B
     \                  / \
      B      →         A   C
       \
        C
```

## 3.2 右旋（Right Rotation）

当节点的左子树过高时使用右旋：

```
      A                B
     /                / \
    B      →         C   A
   /
  C
```

## 3.3 左右旋（Left-Right Rotation）

先对左子节点左旋，再对根节点右旋：

```
    A                A                C
   /                /                / \
  B      →         C      →         B   A
   \              /
    C            B
```

## 3.4 右左旋（Right-Left Rotation）

先对右子节点右旋，再对根节点左旋：

```
  A                A                C
   \                \                / \
    B      →         C      →       A   B
   /                  \
  C                    B
```

# 4 插入操作

插入新节点后，需要从插入位置向上检查每个祖先节点的平衡因子：

1. **插入节点**：按照二叉搜索树的规则插入
2. **更新高度**：从插入位置向上更新所有祖先节点的高度
3. **检查平衡**：计算每个节点的平衡因子
4. **旋转调整**：如果发现不平衡（平衡因子为2或-2），执行相应的旋转操作

## 4.1 插入算法步骤

```python
def insert(self, key):
    # 1. 标准BST插入
    node = self._insert_bst(key)
    
    # 2. 从插入位置向上检查平衡
    current = node
    while current is not None:
        # 更新高度
        self._update_height(current)
        
        # 计算平衡因子
        balance = self._get_balance(current)
        
        # 检查是否需要旋转
        if balance > 1:  # 左子树过高
            if key < current.left.key:  # LL情况
                self._right_rotate(current)
            else:  # LR情况
                self._left_rotate(current.left)
                self._right_rotate(current)
        elif balance < -1:  # 右子树过高
            if key > current.right.key:  # RR情况
                self._left_rotate(current)
            else:  # RL情况
                self._right_rotate(current.right)
                self._left_rotate(current)
        
        current = current.parent
```

# 5 删除操作

删除操作比插入更复杂，因为删除一个节点可能影响多个祖先节点的平衡：

1. **删除节点**：按照二叉搜索树的规则删除
2. **更新高度**：从删除位置向上更新所有祖先节点的高度
3. **检查平衡**：计算每个节点的平衡因子
4. **旋转调整**：如果发现不平衡，执行相应的旋转操作

## 5.1 删除的三种情况

1. **叶子节点**：直接删除
2. **只有一个子节点**：用子节点替换
3. **有两个子节点**：找到后继节点替换，然后删除后继节点

# 6 时间复杂度分析

- **查找**：O(log n) - 树的高度为log n
- **插入**：O(log n) - 需要查找插入位置 + 可能的旋转操作
- **删除**：O(log n) - 需要查找删除位置 + 可能的多次旋转
- **空间复杂度**：O(n) - 存储n个节点

# 7 与红黑树的比较

| 特性 | AVL树 | 红黑树 |
|------|-------|--------|
| 平衡要求 | 严格平衡 | 近似平衡 |
| 查找性能 | 更好 | 稍差 |
| 插入/删除 | 需要更多旋转 | 旋转较少 |
| 实现复杂度 | 较简单 | 较复杂 |
| 应用场景 | 查找密集型 | 插入/删除密集型 |

# 8 实现示例

## 8.1 Python实现

```python
class AVLNode:
    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None
        self.height = 1
        self.parent = None

class AVLTree:
    def __init__(self):
        self.root = None
    
    def _height(self, node):
        if node is None:
            return 0
        return node.height
    
    def _get_balance(self, node):
        if node is None:
            return 0
        return self._height(node.left) - self._height(node.right)
    
    def _update_height(self, node):
        if node is None:
            return
        node.height = max(self._height(node.left), self._height(node.right)) + 1
    
    def _left_rotate(self, x):
        y = x.right
        T2 = y.left
        
        # 执行旋转
        y.left = x
        x.right = T2
        
        # 更新父指针
        if T2:
            T2.parent = x
        y.parent = x.parent
        x.parent = y
        
        # 更新高度
        self._update_height(x)
        self._update_height(y)
        
        return y
    
    def _right_rotate(self, y):
        x = y.left
        T2 = x.right
        
        # 执行旋转
        x.right = y
        y.left = T2
        
        # 更新父指针
        if T2:
            T2.parent = y
        x.parent = y.parent
        y.parent = x
        
        # 更新高度
        self._update_height(y)
        self._update_height(x)
        
        return x
```

# 9 AVL树关联的其它知识

## 9.1 相关数据结构

- **[红黑树](红黑树.md)**：另一种自平衡二叉搜索树
- **[二叉搜索树](树（tree）.md)**：AVL树的基础结构
- **[B树](B树.md)**：多路平衡搜索树
- **[哈希表](哈希表.md)**：基于哈希的查找结构

## 9.2 应用场景

1. **数据库索引**：某些数据库使用AVL树作为索引结构
2. **内存中的有序集合**：需要频繁查找的场景
3. **编译器符号表**：需要快速查找标识符
4. **游戏开发**：空间分割和碰撞检测

## 9.3 算法思想

- **分治思想**：AVL树的查找操作体现了分治思想
- **自平衡机制**：通过旋转操作维护树的平衡
- **高度平衡**：确保树的高度保持在O(log n)级别

## 9.4 扩展知识

- **Splay树**：另一种自调整的二叉搜索树
- **Treap**：结合了二叉搜索树和堆的性质
- **跳表**：基于链表的概率性平衡数据结构
- **树状数组**：用于区间查询和更新的数据结构
