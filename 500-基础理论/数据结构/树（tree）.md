
# 1 Trie（前缀树）

## 1.1 什么是前缀Trie
Trie树（又称前缀树、字典树）是一种用于高效存储和查找字符串集合的数据结构，尤其适合用于处理大量字符串的前缀匹配问题。Trie树的每个节点通常表示一个字符，从根节点到某一节点的路径可以唯一确定一个字符串的前缀。其核心思想是利用字符串的公共前缀来节省存储空间。

> 设计说明：Trie树适合用于需要频繁进行前缀查询、自动补全、词频统计等场景。相比哈希表，Trie树能更高效地支持前缀相关操作。

## 1.2 使用场景
- 字符串检索与前缀匹配（如搜索引擎的自动补全）
- 拼写检查与纠错
- 词频统计
- IP路由（最长前缀匹配）
- 词典实现

## 1.3 代码实现的例子
以Python为例，给出Trie树的基本实现：

```python
class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False  # 是否为单词结尾

class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True

    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end

    def startsWith(self, prefix):
        node = self.root
        for char in prefix:
            if char not in node.children:
                return False
            node = node.children[char]
        return True
```

> 设计注释：Trie树的每个节点用字典存储子节点，支持动态字符集。is_end用于标记单词结尾。

## 1.4 时间复杂度分析
- 插入操作：O(L)，L为单词长度
- 查询操作：O(L)
- 前缀查询：O(L)

Trie树的操作复杂度与字符串长度成正比，和集合中字符串的数量无关。

## 1.5 空间复杂度，以及优化方法（压缩）
Trie树的空间复杂度较高，最坏情况下为`O(N*L)`，N为单词数量，L为平均长度。主要空间消耗在节点的子节点指针上。

### 1.5.1 优化方法
- **压缩Trie（如Radix Tree/字典树压缩）**：将只有一个子节点的链路合并为一个节点，减少空间浪费。
- **使用数组或位图代替字典**：对于字符集较小的场景（如只包含小写字母），可用定长数组或位图优化空间和访问速度。
- **共享节点**：多个单词的公共前缀只存储一份，极大节省空间。

> 设计注释：实际应用中可根据字符集大小和数据量选择合适的节点结构和压缩策略。


# 2 二叉搜索树

## 2.1 二叉搜索树概念
二叉搜索树（Binary Search Tree，BST）是一种特殊的二叉树，其中每个节点的值大于其左子树中所有节点的值，小于其右子树中所有节点的值。这种性质使得二叉搜索树能够高效地支持查找、插入和删除操作。

> 设计说明：二叉搜索树的核心优势在于其有序性，使得查找操作的时间复杂度为O(h)，其中h为树的高度。但在最坏情况下（树退化为链表），时间复杂度会退化到O(n)。

## 2.2 基本操作

### 2.2.1 搜索操作
```python
def search(root, key):
    # 如果根节点为空或等于目标值，返回根节点
    if root is None or root.val == key:
        return root
    
    # 如果目标值小于根节点，在左子树中搜索
    if key < root.val:
        return search(root.left, key)
    
    # 如果目标值大于根节点，在右子树中搜索
    return search(root.right, key)
```

### 2.2.2 插入操作
```python
def insert(root, key):
    # 如果根节点为空，创建新节点
    if root is None:
        return TreeNode(key)
    
    # 递归插入到左子树或右子树
    if key < root.val:
        root.left = insert(root.left, key)
    elif key > root.val:
        root.right = insert(root.right, key)
    
    return root
```

### 2.2.3 删除操作
删除操作相对复杂，需要考虑三种情况：
1. **叶子节点**：直接删除
2. **只有一个子节点**：用子节点替换
3. **有两个子节点**：用中序遍历后继节点替换

```python
def delete(root, key):
    if root is None:
        return root
    
    # 递归查找要删除的节点
    if key < root.val:
        root.left = delete(root.left, key)
    elif key > root.val:
        root.right = delete(root.right, key)
    else:
        # 找到要删除的节点
        # 情况1：叶子节点或只有一个子节点
        if root.left is None:
            return root.right
        elif root.right is None:
            return root.left
        
        # 情况2：有两个子节点，找到中序遍历后继
        successor = find_min(root.right)
        root.val = successor.val
        root.right = delete(root.right, successor.val)
    
    return root

def find_min(node):
    current = node
    while current.left:
        current = current.left
    return current
```

## 2.3 时间复杂度分析
- **搜索**：O(h)，其中h为树的高度
- **插入**：O(h)
- **删除**：O(h)

在平衡的二叉搜索树中，h ≈ log₂(n)，因此操作时间复杂度为O(log n)。但在最坏情况下（树退化为链表），h = n，时间复杂度退化到O(n)。

## 2.4 优缺点
**优点**：
- 查找、插入、删除操作相对简单
- 支持范围查询
- 中序遍历可以得到有序序列

**缺点**：
- 不平衡时性能退化严重
- 需要额外的平衡机制（如AVL树、红黑树）

---

# 3 AVL树
- [AVL树](AVL树.md)
## 3.1 AVL树概念
AVL树是一种自平衡的二叉搜索树，由Adelson-Velsky和Landis在1962年提出。AVL树通过维护每个节点的平衡因子（左子树高度减去右子树高度）来保持树的平衡，确保树的高度始终保持在O(log n)级别。

> 设计说明：AVL树通过严格的平衡条件（平衡因子绝对值不超过1）来保证树的高度平衡，这使得所有操作的时间复杂度都能稳定在O(log n)。

## 3.2 核心性质
- 每个节点的平衡因子（balance factor）的绝对值不超过1
- 平衡因子 = 左子树高度 - 右子树高度
- 插入或删除节点后，通过旋转操作重新平衡树

## 3.3 旋转操作
AVL树通过四种旋转操作来维持平衡：
1. **左旋（Left Rotation）**
2. **右旋（Right Rotation）**
3. **左右旋（Left-Right Rotation）**
4. **右左旋（Right-Left Rotation）**

## 3.4 时间复杂度
- **搜索**：O(log n)
- **插入**：O(log n)
- **删除**：O(log n)

## 3.5 优缺点
**优点**：
- 严格的平衡保证，查询性能稳定
- 所有操作时间复杂度都是O(log n)

**缺点**：
- 插入和删除操作需要更多的旋转
- 实现相对复杂
- 在某些场景下可能过度平衡

---

# 4 红黑树
- [红黑树](红黑树.md)

## 4.1 红黑树概念
红黑树是一种自平衡的二叉搜索树，通过在每个节点上增加一个存储位来表示节点的颜色（红色或黑色）来保持树的平衡。红黑树是AVL树的一种改进，在保持良好性能的同时，减少了平衡操作的复杂度。

> 设计说明：红黑树通过五个性质来保证树的近似平衡，相比AVL树的严格平衡，红黑树在插入和删除时需要的旋转操作更少，因此在实际应用中更为高效。

## 4.2 五个核心性质
1. 每个节点要么是红色，要么是黑色
2. 根节点是黑色
3. 每个叶子节点（NIL）是黑色
4. 红色节点的子节点必须是黑色（不能有两个连续的红色节点）
5. 从任一节点到其所有后代叶子节点的路径上，均包含相同数目的黑色节点

## 4.3 平衡策略
红黑树通过以下操作来维持平衡：
- **变色**：改变节点的颜色
- **左旋**：以某个节点为支点进行左旋转
- **右旋**：以某个节点为支点进行右旋转

## 4.4 时间复杂度
- **搜索**：O(log n)
- **插入**：O(log n)
- **删除**：O(log n)

## 4.5 与AVL树的比较
| 特性 | AVL树 | 红黑树 |
|------|-------|--------|
| 平衡严格程度 | 严格平衡 | 近似平衡 |
| 插入/删除旋转次数 | 较多 | 较少 |
| 查询性能 | 略好 | 略差 |
| 实现复杂度 | 较高 | 中等 |

## 4.6 应用场景
- Java中的TreeMap和TreeSet
- C++中的std::map和std::set
- Linux内核中的调度器
- 数据库索引结构

> 设计注释：红黑树在实际应用中更为广泛，因为它在保持良好性能的同时，减少了维护成本。对于需要频繁插入删除的场景，红黑树是更好的选择。


# 5 深度、广度优先搜索

# 6 参考知识
- [杨波-树相关视频-Trie](https://www.bilibili.com/video/BV1wsCJY6ESK?spm_id_from=333.788.videopod.sections&vd_source=dc9fbc83caec08fa4ea393d6bb5174b5)
