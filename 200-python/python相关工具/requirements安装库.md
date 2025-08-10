#python/requirements

在 Python 中，requirements.txt 既不是直接“执行”的脚本，也不是 Python 内置的特殊文件，它只是一个**纯文本文件**，里面列出了你的项目所依赖的第三方包及其版本。

# **1. 生成 requirements.txt**

  

requirements.txt 通常是通过 **pip** 命令从当前虚拟环境导出依赖来生成的，比如：

```
在当前虚拟环境中
pip freeze > requirements.txt
```

- pip freeze 会输出当前环境中已安装的所有包及版本，比如：
    

```
numpy==1.26.4
pandas==2.2.2
requests==2.32.3
```

- > 会将这个输出重定向保存到 requirements.txt 文件中。
    

  

另外，如果你只想导出自己项目用到的依赖，而不是整个环境的包（避免太多无关包），可以用：

```
pip install pipreqs
pipreqs . --encoding=utf-8 --force
```

pipreqs 会分析你的项目代码里的 import 语句，生成只包含相关依赖的 requirements.txt。

---

# **2. 执行 requirements.txt（安装依赖）**

  

requirements.txt 本身不能直接运行，你需要用 pip 让它生效：

```
pip install -r requirements.txt
```

解释：

- -r 表示从文件读取依赖列表。
    
- pip 会按文件中的行顺序逐个安装指定版本的包。
    

  

requirements.txt 支持一些扩展语法：

```
安装指定版本
requests==2.32.3

安装大于等于某版本
numpy>=1.26.0

从 Git 仓库安装
git+https://github.com/user/repo.git@branch
```

---

# **3. 项目中的典型流程**

  

一般一个 Python 项目会这样用：

1. 创建虚拟环境（如 python -m venv venv）
    
2. 开发时随用随装第三方库（pip install xxx）
    
3. 开发完成后导出依赖：
    

```
pip freeze > requirements.txt
```

3. 其他人拉取项目后，只需：
    

```
pip install -r requirements.txt
```

4. 就能在自己的环境里快速复现相同的依赖版本。
