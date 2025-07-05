Python 的 `typing` 模块是一个用于支持静态类型提示的标准库（从 Python 3.5 开始引入），它通过类型注解提升代码的可读性、可维护性，并帮助静态类型检查工具（如 `mypy`）发现潜在错误。以下是其核心功能和使用场景的详细介绍：

---

# 1 一、核心功能
1. **类型注解（Type Annotations）**  
   通过在变量、函数参数和返回值处标注类型信息，明确数据类型预期。例如：  
   ```python
   def greet(name: str) -> str:
       return f"Hello, {name}"
   ```
   这里 `name: str` 表示参数应为字符串，`-> str` 表示返回值类型为字符串。

2. **复合类型支持**  
   - **容器类型**：如 `List[int]` 表示整数列表，`Dict[str, int]` 表示键为字符串、值为整数的字典。
   - **联合类型**：`Union[int, str]` 表示值可以是整数或字符串，Python 3.10+ 后可用 `int | str` 简化。
   - **可选类型**：`Optional[str]` 等价于 `Union[str, None]`，表示值可以是字符串或 `None`。

3. **泛型（Generics）**  
   使用 `TypeVar` 和 `Generic` 创建通用类型，适用于多类型场景。例如：  
   ```python
   from typing import TypeVar, List, Generic
   T = TypeVar('T')
   class Stack(Generic[T]):
       def __init__(self) -> None:
           self.items: List[T] = []
   ```
   这里 `Stack[int]` 表示一个存储整数的栈。

4. **函数与回调类型**  
   `Callable[[int, int], int]` 表示接收两个整数参数并返回整数的函数。

5. **高级类型工具**  
   - **`Literal`**：限定变量为特定字面值，如 `Literal["read", "write"]`。
   - **`TypedDict`**：定义字典键值类型（Python 3.8+），例如：  
     ```python
     class User(TypedDict):
         name: str
         age: int
     ```
     表示字典必须包含 `name`（字符串）和 `age`（整数）键。
   - **`Protocol`**：定义接口协议，检查对象是否实现特定方法（类似抽象类）。

---

# 2 二、常用类型与语法
| 类型/工具         | 说明                                             | 示例                                  |
| ------------- | ---------------------------------------------- | ----------------------------------- |
| **基本类型**      | `int`, `str`, `bool` 等基础类型无需导入，直接使用            | `age: int = 30`                     |
| **容器类型**      | `List`, `Tuple`, `Dict`, `Set` 等需从 `typing` 导入 | `nums: List[int] = [1, 2, 3]`       |
| **Any**       | 任意类型（禁用类型检查）                                   | `data: Any = load_json()`           |
| **TypeAlias** | 定义类型别名                                         | `UserId = int`                      |
| **NewType**   | 创建自定义类型（如 `UserId = NewType('UserId', int)`）   | `user_id: UserId = UserId(1001)`    |
| **Iterable**  | 可迭代对象                                          | `def process(items: Iterable[str])` |

---

# 3 三、使用示例
1. **联合类型与可选类型**  
   ```python
   from typing import Union, Optional
   def parse_input(data: Union[int, str]) -> Optional[float]:
       try:
           return float(data)
       except ValueError:
           return None
   ```

2. **泛型函数**  
   ```python
   from typing import TypeVar
   T = TypeVar('T')
   def first_element(items: list[T]) -> T:
       return items[0]
   ```

3. **回调函数**  
   ```python
   from typing import Callable
   def on_event(callback: Callable[[int, str], None]) -> None:
       callback(100, "success")
   ```

---

# 4 四、注意事项
1. **动态类型特性保留**：类型注解不会影响运行时行为，Python 仍是动态类型语言。
2. **静态检查工具依赖**：需配合 `mypy` 或 IDE（如 PyCharm）进行类型检查。
3. **版本兼容性**：部分功能需 Python 3.8+（如 `Literal`）或 3.10+（如 `|` 替代 `Union`）。

---

# 5 五、总结
`typing` 模块通过类型注解为 Python 代码提供了静态类型检查的可能，特别适用于大型项目协作和复杂代码维护。合理使用类型提示可以显著提升代码质量，而结合 `mypy` 等工具能进一步规避潜在错误。