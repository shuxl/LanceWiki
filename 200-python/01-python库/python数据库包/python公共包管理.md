# Python公共包管理

## Python公共包管理概念或介绍

在企业级Python开发中，封装公共组件并供业务项目依赖使用，是提高代码复用性和维护效率的重要手段。本文档面向熟悉Java Maven公共模块管理的开发者，讲解如何在Python中实现类似的公共组件封装和管理机制。

### 本文重点

1. **Java Maven vs Python包管理对比**：理解两种语言在公共组件管理上的差异和对应关系
2. **Python包封装方式**：使用`setup.py`和`pyproject.toml`封装公共组件
3. **私有仓库搭建**：使用`devpi`、`pypiserver`等工具搭建企业内部私有PyPI仓库
4. **企业级实践方案**：公共组件封装、版本管理、依赖管理的完整流程
5. **实际案例**：MyBatis封装、日志工具封装、公共Utils封装的具体实现
6. **底层原理**：Python包结构、打包机制、分发流程的深入讲解

---

## Java Maven vs Python包管理对比

### Maven公共模块管理方式

在Java Maven项目中，公共组件的管理通常采用以下方式：

**1. 公共模块项目结构：**
```
company-common/
├── pom.xml                    # Maven配置文件
├── src/
│   └── main/
│       └── java/
│           └── com/company/
│               ├── common/    # 公共工具类
│               ├── db/         # 数据库封装（如MyBatis配置）
│               └── log/        # 日志工具封装
└── README.md
```

**2. 业务项目依赖：**
```xml
<!-- 业务项目的pom.xml -->
<dependency>
    <groupId>com.company</groupId>
    <artifactId>company-common</artifactId>
    <version>1.0.0</version>
</dependency>
```

**3. 中央仓库管理：**
- 公共模块打包后上传到Maven私有仓库（如Nexus、Artifactory）
- 业务项目通过仓库地址自动下载依赖
- 支持版本管理和依赖传递

### Python包管理对应关系

| Maven概念 | Python对应 | 说明 |
|-----------|-----------|------|
| `pom.xml` | `setup.py` / `pyproject.toml` | 包配置文件，定义包信息和依赖 |
| Maven私有仓库 | 私有PyPI仓库（devpi/pypiserver） | 企业内部包仓库 |
| `mvn install` | `pip install -e .` / `pip install .` | 本地安装包 |
| `mvn deploy` | `twine upload` / `pip install` | 发布包到仓库 |
| 依赖传递 | `install_requires` / `dependencies` | 自动处理传递依赖 |
| 版本管理 | `version`字段 | 语义化版本控制 |

### Python包管理的优势与挑战

**优势：**
- 包结构简单，易于理解
- 支持多种打包格式（wheel、sdist）
- 丰富的包管理工具生态

**挑战：**
- 缺少统一的构建工具（类似Maven）
- 私有仓库搭建相对复杂
- 依赖解析能力弱于Maven

---

## Python包封装方式

### 方式一：使用setup.py（传统方式）

`setup.py`是Python传统的包配置文件，使用`setuptools`库进行打包。

#### 1. 公共包项目结构

```
company-common/
├── setup.py                   # 包配置文件
├── README.md
├── requirements.txt           # 依赖声明
├── company_common/            # 包目录（与包名一致）
│   ├── __init__.py
│   ├── utils/                 # 工具类模块
│   │   ├── __init__.py
│   │   └── string_utils.py
│   ├── db/                    # 数据库封装模块
│   │   ├── __init__.py
│   │   └── mybatis_wrapper.py
│   └── log/                   # 日志工具模块
│       ├── __init__.py
│       └── logger_config.py
└── tests/                     # 测试目录
    └── test_utils.py
```

#### 2. setup.py配置示例

```python
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="company-common",              # 包名（pip install时使用）
    version="1.0.0",                    # 版本号
    author="Company Team",
    author_email="team@company.com",
    description="公司公共组件库",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/company/company-common",
    packages=find_packages(),           # 自动发现所有包
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.9",
    install_requires=requirements,      # 依赖声明（类似Maven的dependencies）
    extras_require={                    # 可选依赖（类似Maven的profiles）
        "dev": [
            "pytest>=7.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
        ],
    },
    include_package_data=True,          # 包含非Python文件
    package_data={                      # 指定包含的文件
        "company_common": ["config/*.json", "templates/*.html"],
    },
)
```

#### 3. 打包和安装

```bash
# 1. 构建源码包和wheel包
python setup.py sdist bdist_wheel

# 2. 本地安装（开发模式，代码修改立即生效）
pip install -e .

# 3. 本地安装（普通模式）
pip install .

# 4. 从本地文件安装
pip install dist/company-common-1.0.0-py3-none-any.whl
```

### 方式二：使用pyproject.toml（现代方式，推荐）

`pyproject.toml`是PEP 518引入的现代Python项目配置文件，支持多种构建后端。

#### 1. pyproject.toml配置示例

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "company-common"
version = "1.0.0"
description = "公司公共组件库"
readme = "README.md"
requires-python = ">=3.9"
license = {text = "MIT"}
authors = [
    {name = "Company Team", email = "team@company.com"}
]
keywords = ["common", "utils", "database"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]

# 依赖声明（类似Maven的dependencies）
dependencies = [
    "sqlalchemy>=2.0.0,<3.0.0",
    "pymysql>=1.0.0",
    "loguru>=0.7.0",
    "python-dotenv>=1.0.0",
]

# 可选依赖（类似Maven的profiles）
[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=23.0.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
]

[project.urls]
Homepage = "https://github.com/company/company-common"
Documentation = "https://github.com/company/company-common/docs"
Repository = "https://github.com/company/company-common.git"

[tool.setuptools]
packages = ["company_common"]

[tool.setuptools.package-data]
company_common = ["config/*.json", "templates/*.html"]
```

#### 2. 使用pyproject.toml打包

```bash
# 1. 安装构建工具
pip install build

# 2. 构建包
python -m build

# 3. 安装（与setup.py相同）
pip install -e .  # 开发模式
pip install .     # 普通模式
```

### 两种方式的选择建议

| 特性 | setup.py | pyproject.toml |
|------|----------|----------------|
| Python版本要求 | 所有版本 | Python 3.7+ |
| 配置文件格式 | Python代码 | TOML格式 |
| 灵活性 | 高（可编程） | 中（声明式） |
| 标准化 | 传统方式 | PEP 518标准 |
| 推荐场景 | 复杂构建需求 | 新项目（推荐） |

**推荐使用`pyproject.toml`**，因为：
- 符合Python现代标准（PEP 518）
- 配置文件更简洁易读
- 支持多种构建后端（setuptools、poetry、flit等）

---

## 私有仓库搭建

### 方案一：使用devpi（推荐）

`devpi`是一个功能强大的PyPI服务器和打包/测试/发布工具。

#### 1. 安装devpi

```bash
pip install devpi-server devpi-client
```

#### 2. 启动devpi服务器

```bash
# 初始化devpi服务器
devpi-server --init

# 启动服务器（默认端口3141）
devpi-server --start

# 后台运行
devpi-server --start --daemon
```

#### 3. 配置客户端

```bash
# 配置devpi客户端指向服务器
devpi use http://localhost:3141

# 创建用户（首次使用）
devpi user -c admin password=admin123

# 登录
devpi login admin --password=admin123

# 创建索引（类似Maven的repository）
devpi index -c dev bases=root/pypi
```

#### 4. 上传包到私有仓库

```bash
# 1. 切换到dev索引
devpi use admin/dev

# 2. 构建包
python -m build

# 3. 上传包
devpi upload dist/*

# 或者使用twine上传
pip install twine
twine upload --repository devpi dist/*
```

#### 5. 业务项目安装私有包

```bash
# 方式1：临时指定索引
pip install -i http://localhost:3141/admin/dev/+simple/ company-common

# 方式2：配置pip.conf（推荐）
# Linux/Mac: ~/.pip/pip.conf
# Windows: %APPDATA%\pip\pip.ini
[global]
index-url = http://localhost:3141/admin/dev/+simple/
trusted-host = localhost

# 然后正常安装
pip install company-common
```

### 方案二：使用pypiserver（轻量级）

`pypiserver`是一个轻量级的PyPI服务器实现。

#### 1. 安装pypiserver

```bash
pip install pypiserver passlib
```

#### 2. 创建包存储目录

```bash
mkdir ~/packages
```

#### 3. 启动服务器

```bash
# 无认证模式（仅用于内网）
pypi-server run -p 8080 ~/packages

# 带认证模式
pypi-server run -p 8080 -P .htpasswd ~/packages
```

#### 4. 上传包

```bash
# 使用twine上传
twine upload --repository-url http://localhost:8080 dist/*

# 或直接复制文件
cp dist/*.whl ~/packages/
```

#### 5. 业务项目安装

```bash
pip install -i http://localhost:8080/simple/ company-common
```

### 方案三：使用Nexus Repository（企业级）

如果企业已有Nexus Repository（用于Maven），可以直接使用它托管Python包。

#### 1. 配置Nexus

- 在Nexus中创建`pypi (hosted)`类型的仓库
- 配置访问权限和认证

#### 2. 上传包

```bash
twine upload --repository-url http://nexus.company.com/repository/pypi-hosted/ \
    --username admin --password admin123 \
    dist/*
```

#### 3. 业务项目安装

```bash
pip install -i http://nexus.company.com/repository/pypi-hosted/simple/ company-common
```

### 私有仓库方案对比

| 特性 | devpi | pypiserver | Nexus |
|------|-------|------------|-------|
| 功能丰富度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 部署复杂度 | 中 | 低 | 中 |
| 性能 | 高 | 中 | 高 |
| 认证授权 | 完善 | 基础 | 完善 |
| 适用场景 | 中小团队 | 小团队 | 大型企业 |
| 与Maven集成 | 否 | 否 | 是（统一仓库） |

---

## 企业级实践方案

### 完整工作流程

#### 1. 公共组件开发流程

```
开发阶段 → 测试阶段 → 版本发布 → 仓库上传 → 业务项目使用
```

**详细步骤：**

```bash
# 1. 创建公共包项目
mkdir company-common && cd company-common
git init

# 2. 创建项目结构
mkdir -p company_common/{utils,db,log}
touch company_common/__init__.py
touch setup.py  # 或 pyproject.toml

# 3. 开发功能代码
# ... 编写代码 ...

# 4. 本地测试安装
pip install -e .

# 5. 运行测试
pytest

# 6. 更新版本号（setup.py或pyproject.toml）
# version = "1.0.1"

# 7. 构建包
python -m build

# 8. 上传到私有仓库
devpi upload dist/*

# 9. 打Git标签
git tag v1.0.1
git push origin v1.0.1
```

#### 2. 业务项目使用流程

```bash
# 1. 配置私有仓库地址（pip.conf或requirements.txt）
# 方式1：全局配置
# ~/.pip/pip.conf
[global]
index-url = http://devpi.company.com/admin/dev/+simple/

# 方式2：项目requirements.txt
--index-url http://devpi.company.com/admin/dev/+simple/
company-common>=1.0.0

# 2. 安装公共包
pip install -r requirements.txt

# 3. 在代码中使用
from company_common.utils import string_utils
from company_common.db import mybatis_wrapper
from company_common.log import logger_config
```

### 版本管理策略

#### 语义化版本控制（Semantic Versioning）

```
主版本号.次版本号.修订号
MAJOR.MINOR.PATCH

1.0.0 → 1.0.1  # 修订号：bug修复，向后兼容
1.0.1 → 1.1.0  # 次版本号：新功能，向后兼容
1.1.0 → 2.0.0  # 主版本号：不兼容的API修改
```

#### 版本依赖策略

```python
# setup.py 或 pyproject.toml
install_requires=[
    # 精确版本（生产环境推荐）
    "company-common==1.0.0",
    
    # 兼容版本范围（开发环境）
    "company-common>=1.0.0,<2.0.0",
    
    # 最低版本
    "company-common>=1.0.0",
]
```

### 多环境管理

#### 开发环境配置

```bash
# requirements-dev.txt
-r requirements.txt
company-common>=1.0.0  # 允许使用最新版本进行测试
```

#### 生产环境配置

```bash
# requirements.txt
company-common==1.0.0  # 锁定版本，确保稳定性
```

---

## 实际案例

### 案例一：MyBatis封装（数据库访问层封装）

#### 1. 项目结构

```
company-common/
├── pyproject.toml
├── company_common/
│   ├── __init__.py
│   └── db/
│       ├── __init__.py
│       ├── mybatis_wrapper.py
│       └── connection_pool.py
└── tests/
    └── test_db.py
```

#### 2. 封装代码示例

```python
# company_common/db/mybatis_wrapper.py
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager
import logging

logger = logging.getLogger(__name__)

class MyBatisWrapper:
    """类似MyBatis的数据库访问封装"""
    
    def __init__(self, database_url: str, pool_size: int = 5):
        """
        初始化数据库连接
        
        Args:
            database_url: 数据库连接URL
            pool_size: 连接池大小
        """
        self.engine = create_engine(
            database_url,
            pool_size=pool_size,
            pool_pre_ping=True,
            echo=False
        )
        self.SessionLocal = sessionmaker(bind=self.engine)
    
    @contextmanager
    def get_session(self):
        """获取数据库会话（上下文管理器）"""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            session.close()
    
    def execute_query(self, sql: str, params: dict = None):
        """
        执行查询SQL
        
        Args:
            sql: SQL语句
            params: 参数字典
        
        Returns:
            查询结果列表
        """
        with self.get_session() as session:
            result = session.execute(text(sql), params or {})
            return [dict(row) for row in result]
    
    def execute_update(self, sql: str, params: dict = None):
        """
        执行更新SQL
        
        Args:
            sql: SQL语句
            params: 参数字典
        
        Returns:
            影响行数
        """
        with self.get_session() as session:
            result = session.execute(text(sql), params or {})
            return result.rowcount
```

#### 3. 使用示例

```python
# 业务项目中使用
from company_common.db import MyBatisWrapper

# 初始化（通常在配置文件中）
db = MyBatisWrapper(
    database_url="mysql+pymysql://user:password@localhost/dbname",
    pool_size=10
)

# 执行查询
users = db.execute_query(
    "SELECT * FROM users WHERE age > :age",
    params={"age": 18}
)

# 执行更新
affected = db.execute_update(
    "UPDATE users SET status = :status WHERE id = :id",
    params={"status": "active", "id": 1}
)
```

### 案例二：日志工具封装

#### 1. 封装代码示例

```python
# company_common/log/logger_config.py
import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

def setup_logger(
    name: str,
    log_file: str = None,
    level: int = logging.INFO,
    format_string: str = None,
    max_bytes: int = 10 * 1024 * 1024,  # 10MB
    backup_count: int = 5
) -> logging.Logger:
    """
    配置日志记录器
    
    Args:
        name: 日志记录器名称
        log_file: 日志文件路径（可选）
        level: 日志级别
        format_string: 日志格式字符串
        max_bytes: 单个日志文件最大字节数
        backup_count: 保留的备份文件数量
    
    Returns:
        配置好的日志记录器
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # 避免重复添加handler
    if logger.handlers:
        return logger
    
    # 默认格式
    if format_string is None:
        format_string = (
            '%(asctime)s - %(name)s - %(levelname)s - '
            '%(filename)s:%(lineno)d - %(message)s'
        )
    
    formatter = logging.Formatter(format_string)
    
    # 控制台handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # 文件handler（如果指定了日志文件）
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setLevel(level)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    return logger

# 便捷函数
def get_logger(name: str = None) -> logging.Logger:
    """获取默认配置的日志记录器"""
    if name is None:
        name = __name__
    return setup_logger(name)
```

#### 2. 使用示例

```python
# 业务项目中使用
from company_common.log import get_logger, setup_logger

# 方式1：使用默认配置
logger = get_logger("myapp")
logger.info("Application started")

# 方式2：自定义配置
logger = setup_logger(
    name="myapp",
    log_file="logs/myapp.log",
    level=logging.DEBUG
)
logger.debug("Debug message")
logger.error("Error occurred")
```

### 案例三：公共Utils封装

#### 1. 工具类示例

```python
# company_common/utils/string_utils.py
import re
from typing import List, Optional

class StringUtils:
    """字符串工具类"""
    
    @staticmethod
    def camel_to_snake(name: str) -> str:
        """驼峰命名转蛇形命名"""
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    
    @staticmethod
    def snake_to_camel(name: str) -> str:
        """蛇形命名转驼峰命名"""
        components = name.split('_')
        return components[0] + ''.join(x.capitalize() for x in components[1:])
    
    @staticmethod
    def is_empty(value: Optional[str]) -> bool:
        """判断字符串是否为空"""
        return value is None or value.strip() == ""
    
    @staticmethod
    def truncate(text: str, max_length: int, suffix: str = "...") -> str:
        """截断字符串"""
        if len(text) <= max_length:
            return text
        return text[:max_length - len(suffix)] + suffix

# company_common/utils/date_utils.py
from datetime import datetime, timedelta
from typing import Optional

class DateUtils:
    """日期工具类"""
    
    @staticmethod
    def format_datetime(dt: datetime, fmt: str = "%Y-%m-%d %H:%M:%S") -> str:
        """格式化日期时间"""
        return dt.strftime(fmt)
    
    @staticmethod
    def parse_datetime(date_string: str, fmt: str = "%Y-%m-%d %H:%M:%S") -> Optional[datetime]:
        """解析日期时间字符串"""
        try:
            return datetime.strptime(date_string, fmt)
        except ValueError:
            return None
    
    @staticmethod
    def days_between(start: datetime, end: datetime) -> int:
        """计算两个日期之间的天数"""
        return (end - start).days
```

#### 2. 使用示例

```python
# 业务项目中使用
from company_common.utils import StringUtils, DateUtils

# 字符串工具
snake_name = StringUtils.camel_to_snake("UserName")  # "user_name"
camel_name = StringUtils.snake_to_camel("user_name")  # "userName"

# 日期工具
now = datetime.now()
formatted = DateUtils.format_datetime(now)  # "2024-01-01 12:00:00"
```

---

## 底层原理

### Python包结构原理

#### 1. 包的基本概念

Python包是一个包含`__init__.py`文件的目录，用于组织相关的模块。

```
package/
├── __init__.py          # 包初始化文件（可以是空文件）
├── module1.py           # 模块1
└── subpackage/          # 子包
    ├── __init__.py
    └── module2.py
```

#### 2. 包的导入机制

```python
# __init__.py的作用
# 1. 标识目录为Python包
# 2. 控制包的导入行为
# 3. 定义包的公共接口

# company_common/__init__.py示例
from .utils import StringUtils, DateUtils
from .db import MyBatisWrapper
from .log import get_logger

__version__ = "1.0.0"
__all__ = ["StringUtils", "DateUtils", "MyBatisWrapper", "get_logger"]
```

### 打包分发机制

#### 1. 打包格式

**sdist（Source Distribution）：**
- 格式：`.tar.gz`文件
- 包含源代码和`setup.py`
- 安装时需要编译

**wheel（Built Distribution）：**
- 格式：`.whl`文件
- 预编译的二进制格式
- 安装速度快，推荐使用

#### 2. 打包流程

```
源代码 → setuptools/build → 构建包 → 生成.whl/.tar.gz → 上传仓库
```

**关键步骤：**

```python
# setup.py/build过程
1. 读取setup.py或pyproject.toml配置
2. 收集包文件（packages参数）
3. 收集数据文件（package_data参数）
4. 解析依赖关系（install_requires）
5. 生成元数据（METADATA文件）
6. 打包成wheel或sdist格式
```

#### 3. 安装机制

```python
# pip install过程
1. 从仓库下载包文件（.whl或.tar.gz）
2. 解压到临时目录
3. 运行setup.py（如果是sdist）
4. 安装到site-packages目录
5. 记录安装信息到.egg-info或.dist-info
```

### 依赖解析机制

#### 1. 依赖声明

```python
# setup.py
install_requires=[
    "requests>=2.25.0",      # 最低版本
    "sqlalchemy>=2.0.0,<3.0.0",  # 版本范围
    "pymysql==1.1.0",        # 精确版本
]
```

#### 2. 依赖解析流程

```
业务项目依赖company-common
    ↓
company-common依赖requests>=2.25.0
    ↓
pip解析依赖树
    ↓
检查已安装版本
    ↓
解决版本冲突
    ↓
安装/更新依赖
```

#### 3. 依赖冲突解决

```bash
# 查看依赖树
pip install pipdeptree
pipdeptree

# 检查冲突
pip check

# 使用pip-tools解决冲突
pip install pip-tools
pip-compile requirements.txt  # 生成requirements-lock.txt
```

### 设计思想

#### 1. 单一职责原则

每个公共包应该专注于一个领域：
- `company-common-db`：数据库相关
- `company-common-log`：日志相关
- `company-common-utils`：工具类相关

#### 2. 依赖最小化

公共包应该尽量减少外部依赖，避免传递依赖过多：

```python
# 好的做法：只依赖必要的库
install_requires=["requests>=2.25.0"]

# 不好的做法：依赖过多
install_requires=["requests", "flask", "django", "pandas", "numpy", ...]
```

#### 3. 向后兼容

公共包的API变更应该保持向后兼容：

```python
# 版本1.0.0
def process_data(data: dict) -> dict:
    """处理数据"""
    pass

# 版本1.1.0（向后兼容）
def process_data(data: dict, options: dict = None) -> dict:
    """处理数据，新增options参数"""
    if options is None:
        options = {}
    # ... 原有逻辑 ...
    pass

# 版本2.0.0（不兼容，需要主版本号升级）
def process_data_v2(data: dict, options: dict) -> dict:
    """新API，options为必需参数"""
    pass
```

---

## Python公共包管理关联的其它知识

### 相关文档

- [Python企业项目开发规范](../02-python企业项目开发方式/企业项目开发规范.md)：企业级Python项目依赖管理规范
- [Python包管理](../000-python包.md)：Python包的基础概念
- [Conda环境管理](../python相关工具/conda.md)：conda环境管理

### 进阶主题

1. **Poetry项目管理**：现代化的Python项目管理工具，提供依赖解析、版本管理、构建发布等功能，类似Maven
2. **Docker容器化**：将Python包和依赖打包到Docker镜像中，实现完全一致的环境
3. **CI/CD集成**：在持续集成中自动构建、测试和发布公共包
4. **包版本策略**：语义化版本控制、版本分支管理、热修复流程
5. **依赖安全审计**：使用`safety`、`pip-audit`等工具检查依赖漏洞

### 工具推荐

| 工具 | 用途 | 适用场景 |
|------|------|----------|
| **setuptools** | 打包工具 | 传统Python项目 |
| **build** | 现代打包工具 | 使用pyproject.toml的项目 |
| **twine** | 包上传工具 | 上传到PyPI或私有仓库 |
| **devpi** | 私有仓库服务器 | 中小团队 |
| **pypiserver** | 轻量级仓库服务器 | 小团队 |
| **Nexus** | 企业级仓库 | 大型企业（统一Maven和Python） |
| **Poetry** | 项目管理工具 | 新项目（类似Maven） |

### 最佳实践总结

1. **使用pyproject.toml**：采用现代Python标准配置
2. **搭建私有仓库**：使用devpi或Nexus管理企业内部包
3. **版本管理规范**：遵循语义化版本控制
4. **依赖最小化**：公共包尽量减少外部依赖
5. **向后兼容**：API变更保持向后兼容，或升级主版本号
6. **文档完善**：提供清晰的README和使用示例
7. **自动化流程**：使用CI/CD自动构建和发布

