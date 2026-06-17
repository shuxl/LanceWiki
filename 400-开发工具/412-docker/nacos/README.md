# Nacos Docker 部署指南

## 概述

本项目提供了适用于Mac M1/M3芯片的Nacos Docker部署配置，使用最简单的单机模式，确保稳定运行。

## 文件说明

- `docker-compose.yml`: Docker Compose配置文件
- `nacos.env`: 环境变量配置文件（可选）
- `README.md`: 使用说明文档

## 快速开始

### 1. 启动Nacos（单机模式）

#### 步骤1：进入nacos目录
```bash
cd /Users/m684620/work/gitee/technologyStack/【1-develop】/400-开发工具/412-docker/nacos
```

#### 步骤2：检查Docker环境
```bash
# 检查Docker是否安装和运行
docker --version
docker compose --version

# 如果提示 "command not found"，请先安装Docker
# 安装命令：brew install --cask docker

# 检查Docker服务状态
docker info
```

#### 步骤3：启动Nacos服务
```bash
# 启动Nacos服务（后台运行）
docker compose up -d nacos

# 或者前台运行（查看实时日志）
docker compose up nacos
```

#### 步骤4：验证服务状态
```bash
# 查看服务状态
docker compose ps

# 查看容器运行状态
docker ps

# 查看Nacos启动日志
docker compose logs -f nacos

# 查看实时日志（如果后台运行）
docker logs -f nacos-server
```

#### 步骤5：等待服务完全启动
```bash
# 等待约30-60秒，然后检查健康状态
curl -f http://localhost:8848/nacos/v1/console/health

# 如果出现 "Connection reset by peer" 错误，说明服务启动失败
# 请查看详细日志进行故障排除

# 或者检查端口是否监听
lsof -i :8848
```

### 2. 访问Nacos控制台

- **控制台地址**: http://localhost:8848/nacos
- **默认用户名**: nacos
- **默认密码**: nacos

### 3. 停止服务

```bash
# 停止服务
docker compose down

# 停止并删除数据卷
docker compose down -v

# 强制停止并删除容器
docker compose down --remove-orphans
```

## 完整安装流程

### 一键安装脚本

如果您希望一键完成所有步骤，可以执行以下命令：

```bash
# 1. 进入nacos目录
cd /Users/m684620/work/gitee/technologyStack/【1-develop】/400-开发工具/412-docker/nacos

# 2. 检查Docker环境
echo "检查Docker环境..."
docker --version && docker compose --version

# 3. 停止可能存在的旧容器
echo "清理旧容器..."
docker compose down --remove-orphans 2>/dev/null || true

# 4. 启动Nacos
echo "启动Nacos服务..."
docker compose up -d nacos

# 5. 等待服务启动
echo "等待服务启动（约60秒）..."
sleep 60

# 6. 检查服务状态
echo "检查服务状态..."
docker compose ps

# 7. 检查健康状态
echo "检查健康状态..."
curl -f http://localhost:8848/nacos/v1/console/health && echo "✅ Nacos启动成功！" || echo "❌ Nacos启动失败，请查看日志"

# 8. 显示访问信息
echo ""
echo "🎉 Nacos安装完成！"
echo "📱 控制台地址: http://localhost:8848/nacos"
echo "👤 用户名: nacos"
echo "🔑 密码: nacos"
echo ""
echo "📋 查看日志命令: docker compose logs -f nacos"
echo "🛑 停止服务命令: docker compose down"
```

## 配置说明

### 端口配置

- `8848`: Nacos控制台端口
- `9848`: Nacos客户端gRPC请求服务端端口
- `9849`: Nacos客户端gRPC请求服务端端口（用于服务端间通信）

### 数据存储

- **开发环境**: 使用内置数据库（默认配置）
- **生产环境**: 建议使用MySQL数据库

## 目录结构

```
nacos/
├── docker-compose.yml    # Docker Compose配置
├── nacos.env            # 环境变量配置（可选）
├── logs/                # 日志目录（自动创建）
├── data/                # 数据目录（自动创建）
└── README.md            # 使用说明文档
```

## 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 重启服务
docker compose restart nacos

# 查看服务状态
docker compose ps

# 查看服务日志
docker compose logs -f nacos
```

### 数据备份

```bash
# 备份数据目录
tar -czf nacos-backup-$(date +%Y%m%d).tar.gz data/

# 恢复数据
tar -xzf nacos-backup-20240101.tar.gz
```

## 故障排除

### 0. 常见启动问题

#### 问题：Docker未安装或未找到命令
```bash
# 检查Docker是否安装
docker --version

# 如果提示 "command not found: docker"，说明Docker未安装
```

**解决方案1：安装Docker Desktop（推荐）**
```bash
# 方法1：通过Homebrew安装（推荐）
brew install --cask docker

# 方法2：手动下载安装
# 访问 https://www.docker.com/products/docker-desktop/
# 下载适用于Mac的Docker Desktop安装包
```

#### 问题：docker-compose命令未找到
```bash
# 检查docker-compose是否可用
docker-compose --version

# 如果提示 "command not found: docker-compose"，尝试以下解决方案
```

**解决方案1：使用docker compose（新版本）**
```bash
# Docker新版本使用 docker compose 而不是 docker-compose
docker compose --version

# 如果这个命令可用，请使用以下命令启动Nacos：
docker compose up -d nacos
```

**解决方案2：安装docker-compose**
```bash
# 通过Homebrew安装docker-compose
brew install docker-compose

# 或者通过pip安装
pip install docker-compose
```

#### 问题：Docker未启动
```bash
# 检查Docker是否运行
docker info

# 如果Docker未启动，请启动Docker Desktop应用
# 或者通过命令行启动
open -a Docker
```

#### 问题：端口被占用
```bash
# 检查8848端口是否被占用
lsof -i :8848

# 如果被占用，杀死占用进程
sudo kill -9 $(lsof -t -i:8848)

# 或者修改docker-compose.yml中的端口映射
```

#### 问题：权限不足
```bash
# 确保当前用户有Docker权限
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker
```

### 1. Nacos启动失败问题

**错误信息**: `curl: (56) Recv failure: Connection reset by peer`

**诊断步骤**:
```bash
# 1. 查看容器状态
docker ps -a

# 2. 查看详细启动日志
docker logs nacos-server

# 3. 查看实时日志
docker logs -f nacos-server

# 4. 检查端口占用
lsof -i :8848
```

**常见原因和解决方案**:

#### 原因1：端口被占用
```bash
# 检查端口占用
lsof -i :8848

# 如果被占用，杀死进程
sudo kill -9 $(lsof -t -i:8848)

# 或者修改端口映射
# 编辑docker-compose.yml，将8848改为其他端口
```

#### 原因2：内存不足
```bash
# 检查系统内存
free -h  # Linux
vm_stat  # macOS

# 如果内存不足，调整JVM参数
# 编辑docker-compose.yml中的JVM参数
```

#### 原因3：Docker资源不足
```bash
# 检查Docker资源
docker system df
docker system prune -f

# 重启Docker Desktop
```

#### 原因4：数据库配置问题
```bash
# 错误信息：UnknownHostException: ${MYSQL_SERVICE_HOST}
# 原因：Nacos尝试连接外部MySQL数据库，但配置错误

# 解决方案：强制使用内置数据库
# 1. 停止容器
docker compose down

# 2. 清理所有数据（确保重新初始化）
docker compose down -v

# 3. 重新启动（已修复配置）
docker compose up -d nacos

# 4. 如果仍有问题，使用以下命令强制重建
docker system prune -f
docker compose up -d --force-recreate nacos
```

#### 原因5：配置文件问题
```bash
# 完全重新创建容器
docker compose down -v
docker compose up -d nacos
```

### 2. JVM警告信息

**警告**: `UseCMSCompactAtFullCollection is deprecated`

**说明**: 这是JVM垃圾收集器的废弃警告，不影响Nacos正常运行，可以忽略。

### 3. 权限问题

确保Docker有足够的权限访问目录：

```bash
# 设置目录权限
chmod -R 755 logs data
```

## 生产环境建议

1. **使用外部数据库**: 生产环境建议使用MySQL等外部数据库
2. **集群部署**: 生产环境建议使用集群模式部署
3. **安全配置**: 修改默认的认证token和密码
4. **监控告警**: 配置监控和告警机制
5. **数据备份**: 定期备份配置数据

## 版本信息

- **Nacos版本**: v2.3.0
- **Docker Compose版本**: 3.8+
- **支持平台**: Mac M1/M3芯片（兼容x86_64）

## 相关链接

- [Nacos官方文档](https://nacos.io/zh-cn/docs/quick-start.html)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [Nacos Docker部署指南](https://nacos.io/zh-cn/docs/deployment.html)