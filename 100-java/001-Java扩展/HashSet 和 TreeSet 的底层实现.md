# 1. 底层实现原理
- **HashSet**：底层基于 HashMap 实现，所有元素都作为 HashMap 的 key，value 是一个固定对象（如 PRESENT）。
- **TreeSet**：底层基于红黑树（Red-Black Tree）实现，元素有序，排序方式为自然顺序或自定义 Comparator。

---

# 2. 数据结构与核心原理
- **HashSet**：
  - 元素存储在 HashMap 的 key 部分，依赖 hashCode 和 equals 判断唯一性。
  - 插入、删除、查找的平均时间复杂度为 O(1)。
  - 元素无序，允许一个 null 元素。
- **TreeSet**：
  - 元素存储在红黑树结构中，依赖 compareTo 或 Comparator 判断顺序和唯一性。
  - 插入、删除、查找的时间复杂度为 O(log n)。
  - 元素有序，不允许 null 元素。

---

# 3. 源码关注点
- HashSet 的 add/remove/contains 方法实际调用 HashMap 的相关方法。
- TreeSet 的 add/remove/contains 方法实际调用 TreeMap 的相关方法。
- 红黑树的平衡调整、节点旋转等细节可参考 TreeMap 源码。
- JDK8 之后，HashMap 链表长度大于8会转为红黑树，HashSet 性能更稳定。

---

# 4. 面试易错点与陷阱
- HashSet 判断元素唯一性依赖 hashCode 和 equals，TreeSet 依赖 compareTo/Comparator。
- TreeSet 存储自定义对象时，必须实现 Comparable 或提供 Comparator，否则运行时抛异常。
- HashSet 允许一个 null 元素，TreeSet 不允许 null。
- HashSet 元素无序，TreeSet 元素有序。
- Hash 冲突严重时，HashSet 性能会退化为 O(n)。
- TreeSet 的排序和唯一性是同一套 compare 规则，compareTo=0 视为重复元素。

> **面试提醒：**
> - HashSet 和 TreeSet 的底层实现、唯一性判断机制、性能差异是高频考点。
> - TreeSet 的排序和唯一性是同一套 compare 规则，容易混淆。

---

# 5. 适用场景与开发建议
- 需要元素唯一且无序：优先用 HashSet，性能更优。
- 需要元素唯一且有序：用 TreeSet，适合需要排序的场景。
- 自定义对象做 Set 元素时，注意实现 hashCode/equals 或 Comparable/Comparator。
- 数据量大、频繁查找时优先考虑 HashSet。

---

> **总结：**
> - HashSet 适合无序、性能优先的唯一性集合
> - TreeSet 适合有序、可排序的唯一性集合
> - 面试时要结合底层原理和实际场景分析选择



