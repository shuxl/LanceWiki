
# 1 基本原理

LRU（Least Recently Used，最近最少使用）缓存淘汰算法是一种常用的页面置换算法。其核心思想是：如果数据最近被访问过，那么将来被访问的概率也更高；如果很久没有被访问，则被淘汰的概率更高。

当缓存空间已满时，LRU会淘汰最近最久未被访问的数据。

---

# 2 常见实现方式

## 2.1 双向链表 + 哈希表（Java常用设计）
- 哈希表用于O(1)时间内定位节点。
- 双向链表维护访问顺序，头部为最新访问，尾部为最久未访问。
- 新访问/更新节点时，将节点移动到链表头部。
- 淘汰时，移除链表尾部节点。

### 2.1.1 Java伪代码示例
```java
// 设计要点：哈希表+双向链表
class LRUCache {
    private class Node {
        int key, value;
        Node prev, next;
        Node(int k, int v) { key = k; value = v; }
    }
    private int capacity;
    private Map<Integer, Node> map;
    private Node head, tail;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        map = new HashMap<>();
        head = new Node(0, 0);
        tail = new Node(0, 0);
        head.next = tail;
        tail.prev = head;
    }
    public int get(int key) {
        if (!map.containsKey(key)) return -1;
        Node node = map.get(key);
        remove(node);
        insertToHead(node);
        return node.value;
    }
    public void put(int key, int value) {
        if (map.containsKey(key)) {
            Node node = map.get(key);
            node.value = value;
            remove(node);
            insertToHead(node);
        } else {
            if (map.size() == capacity) {
                Node lru = tail.prev;
                remove(lru);
                map.remove(lru.key);
            }
            Node node = new Node(key, value);
            map.put(key, node);
            insertToHead(node);
        }
    }
    private void remove(Node node) {
        node.prev.next = node.next;
        node.next.prev = node.prev;
    }
    private void insertToHead(Node node) {
        node.next = head.next;
        node.prev = head;
        head.next.prev = node;
        head.next = node;
    }
}
```

## 2.2 Python实现（使用OrderedDict）
Python的`collections.OrderedDict`可以方便地实现LRU缓存。

```python
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity: int):
        self.cache = OrderedDict()
        self.capacity = capacity

    def get(self, key: int) -> int:
        if key not in self.cache:
            return -1
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key: int, value: int) -> None:
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)
```

---

# 3 设计要点
- **O(1)时间复杂度**：通过哈希表+双向链表实现高效的插入、删除和查找。
- **线程安全**：多线程环境下需加锁保护。
- **容量管理**：合理设置缓存容量，防止内存溢出。

---

# 4 应用场景
- 操作系统页面置换
- 数据库缓存
- Web浏览器缓存
- CDN内容分发缓存
- 任何需要有限空间缓存、且数据访问有局部性原理的场景

---

# 5 与其他缓存淘汰算法对比
| 算法 | 原理 | 优点 | 缺点 |
| ---- | ---- | ---- | ---- |
| LRU | 淘汰最久未被访问的数据 | 简单高效，局部性好 | 维护链表有一定开销 |
| LFU | 淘汰访问频率最低的数据 | 适合热点数据稳定场景 | 实现复杂，频率统计有延迟 |
| FIFO | 先进先出，淘汰最早进入的数据 | 实现简单 | 不考虑数据访问频率和时间 |

---

# 6 参考资料
- [LRU缓存算法 - 维基百科](https://zh.wikipedia.org/wiki/%E6%9C%80%E8%BF%91%E6%9C%80%E5%B0%91%E4%BD%BF%E7%94%A8%E7%AE%97%E6%B3%95)
- [Java源码中的LinkedHashMap实现LRU](https://docs.oracle.com/javase/8/docs/api/java/util/LinkedHashMap.html)
- [LeetCode 146. LRU Cache](https://leetcode.cn/problems/lru-cache/)
