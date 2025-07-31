matplotlib 是 Python 最常用的绘图库之一，特别适合用于科学计算、数据分析和可视化。它功能强大、灵活，并且可以与 NumPy、Pandas 等库无缝协作。

---

# 1 **一、matplotlib 的简介**

- matplotlib 是一个 **2D 绘图库**，由 John D. Hunter 开发。
    
- 默认提供类似 MATLAB 风格的绘图接口（pyplot）。
    
- 支持多种输出格式（PNG、PDF、SVG、JPG、EPS）以及交互式图形界面（Tkinter、Qt、GTK、WebAgg 等）。
    

---

# 2 **二、核心模块：matplotlib.pyplot**

最常用的接口是 pyplot，一般如下导入：

```
import matplotlib.pyplot as plt
```

这个模块提供了 MATLAB 风格的 API，例如：

```
import matplotlib.pyplot as plt

x = [1, 2, 3, 4]
y = [2, 4, 6, 8]

plt.plot(x, y)
plt.title("Simple Line Plot")
plt.xlabel("x-axis")
plt.ylabel("y-axis")
plt.grid(True)
plt.show()
```

---

# 3 **三、matplotlib 支持的图表类型**

1. 折线图（Line plot）：plt.plot()
    
2. 散点图（Scatter plot）：plt.scatter()
    
3. 条形图（Bar chart）：plt.bar(), plt.barh()
    
4. 直方图（Histogram）：plt.hist()
    
5. 饼图（Pie chart）：plt.pie()
    
6. 箱线图（Box plot）：plt.boxplot()
    
7. 极坐标图（Polar chart）：plt.polar()
    
8. 等高线图（Contour plot）：plt.contour()
    
9. 图像显示：plt.imshow()、plt.matshow()
    

---

# 4 **四、面向对象风格（推荐）**

更灵活的方式是使用 Figure 和 Axes：

```
fig, ax = plt.subplots()
ax.plot(x, y)
ax.set_title("Line Plot with OO Style")
ax.set_xlabel("x-axis")
ax.set_ylabel("y-axis")
plt.show()
```

---

# 5 **五、与其他库集成**

- **NumPy**：直接传入 NumPy 数组进行绘图
- **Pandas**：DataFrame 直接调用 .plot()，底层其实也是用的 matplotlib
- **Seaborn**：基于 matplotlib 封装的高级绘图库
    

---

# 6 **六、常用设置**

```
plt.figure(figsize=(10, 5))        # 图像大小
plt.xlim(0, 10)                    # x轴范围
plt.ylim(0, 20)                    # y轴范围
plt.legend(["line1", "line2"])    # 图例
plt.grid(True)                    # 网格
```

---

# 7 **七、保存图像**

```
plt.savefig("output.png", dpi=300)
```

---

# 8 **八、安装方式**

```
pip install matplotlib
```
