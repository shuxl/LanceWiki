# Langfuse v3 Docker 部署指南

## 概述

本项目提供了适用于 **Mac M1/M3 芯片**的 Langfuse v3 Docker 部署配置，使用最新版本以拥抱新特性。

**重要说明**：
- 本配置假设你**已有 PostgreSQL 和 Redis 服务**（不在 Docker 中）
- 包含 ClickHouse（OLAP 存储）和 MinIO（S3 兼容存储）的 Docker 容器
- 使用 ARM64 架构镜像，确保在 Mac M1/M3 上获得最佳性能

## 文件说明

- `docker-compose.yml`: Docker Compose 配置文件
- `env.example`: 环境变量配置模板
- `.env`: 实际环境变量配置（需要从 env.example 创建，**不要提交到 Git**）
- `setup.sh`: 环境初始化脚本（生成密钥、检查环境等）
- `start.sh`: 服务启动脚本
- `本地搭建注意要点.md`: 详细的注意事项文档

## 快速开始

### 1. 前置条件

- ✅ Docker Desktop 已安装并运行
- ✅ Docker Compose 已安装（新版本 Docker Desktop 已包含）
- ✅ 已有 PostgreSQL 数据库（本地或远程）
- ✅ 已有 Redis 服务（本地或远程）
- ✅ Mac M1/M3 芯片（本配置针对 ARM64 优化）

### 2. 初始化环境

#### 步骤1：进入 langfuse 目录

```bash
cd /Users/m684620/work/gitee/technologyStack/【1-develop】/400-开发工具/412-docker/langfuse
```

#### 步骤2：运行初始化脚本

```bash
# 赋予执行权限
chmod +x setup.sh start.sh

# 运行初始化脚本
./setup.sh
```

初始化脚本会自动：
- ✅ 检查 Docker 环境
- ✅ 检查端口占用
- ✅ 创建 .env 文件（如果不存在）
- ✅ 生成随机密钥（NEXTAUTH_SECRET、SALT、ENCRYPTION_KEY）
- ✅ 拉取 Docker 镜像

#### 步骤3：配置数据库和 Redis 连接

编辑 `.env` 文件，配置你的 PostgreSQL 和 Redis 连接：

```bash
# PostgreSQL 配置
# ⚠️ 重要：根据你的实际情况选择配置方式

# 方式1：如果 PostgreSQL 在 Docker 容器中，且在同一网络，使用容器名
# DATABASE_URL=postgresql://用户名:密码@容器名:5432/数据库名

# 方式2：如果 PostgreSQL 在 Docker 容器中，Mac 使用 host.docker.internal + 宿主机端口
# 注意：你的 PostgreSQL 宿主机端口是 5433，不是 5432
DATABASE_URL=postgresql://用户名:密码@host.docker.internal:5433/数据库名
DIRECT_URL=${DATABASE_URL}

# Redis 配置
# ⚠️ 重要：根据你的实际情况选择配置方式

# 方式1：如果 Redis 在 Docker 容器中，且在同一网络，使用容器名
# REDIS_CONNECTION_STRING=redis://容器名:6379/0

# 方式2：如果 Redis 在 Docker 容器中，Mac 使用 host.docker.internal
REDIS_CONNECTION_STRING=redis://host.docker.internal:6379/0
```

**重要提示**：
- ❌ **不要使用 `127.0.0.1`**：在 Docker 容器中，`127.0.0.1` 指向容器自身，无法访问其他容器
- ✅ **推荐使用 `host.docker.internal`**：Mac 上可以访问宿主机服务，配置简单
- ✅ **如果容器在同一网络**：可以使用容器名（性能更好）
- ⚠️ **注意端口**：PostgreSQL 的宿主机端口是 5433，容器内端口是 5432
- 确保数据库和 Redis 服务已启动并可访问

**详细配置说明请参考**：`Docker网络配置说明.md`

### 3. 启动服务

#### 方式1：使用启动脚本（推荐）

```bash
./start.sh
```

#### 方式2：使用 Docker Compose 命令

```bash
# 启动服务（后台运行）
docker compose up -d

# 或者前台运行（查看实时日志）
docker compose up
```

### 4. 验证服务状态

```bash
# 查看所有容器状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f langfuse-web

# 检查健康状态
curl http://localhost:3000/api/public/health
```

### 5. 访问服务

- **Langfuse Web UI**: http://localhost:3000
- **MinIO 控制台**: http://localhost:9001
  - 默认用户名：`minioadmin`
  - 默认密码：`minioadmin`（可在 .env 中修改）
- **MinIO S3 API**: http://localhost:9002（如果从宿主机访问）
  - 注意：容器内服务使用 `http://minio:9000`，宿主机访问使用 `9002` 端口

## 服务说明

### 包含的服务

1. **langfuse-web**: Langfuse Web 界面和 API 服务
   - 端口：3000
   - 功能：提供 Web UI 和 REST API

2. **langfuse-worker**: Langfuse 后台工作进程
   - 功能：处理异步任务、事件队列处理

3. **clickhouse**: ClickHouse 数据库（OLAP 存储）
   - 端口：8123 (HTTP), 9000 (Native)
   - 功能：存储 traces、observations 等分析数据

4. **minio**: MinIO 对象存储（S3 兼容）
   - 端口：9002 (S3 API，宿主机), 9001 (控制台)
   - 容器内端口：9000 (S3 API)
   - 功能：存储事件和媒体文件
   - 注意：宿主机端口使用 9002 避免与 ClickHouse 的 9000 端口冲突

### 外部服务（需要你提供）

- **PostgreSQL**: 主数据库（存储用户、项目、配置等）
- **Redis**: 缓存和队列服务

## 环境变量配置

### 必填环境变量

在 `.env` 文件中配置以下变量：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `DATABASE_URL` | PostgreSQL 连接字符串 | `postgresql://user:pass@host.docker.internal:5432/langfuse` |
| `REDIS_CONNECTION_STRING` | Redis 连接字符串 | `redis://host.docker.internal:6379/0` |
| `NEXTAUTH_SECRET` | NextAuth 会话密钥 | 由 setup.sh 自动生成 |
| `SALT` | API key 哈希盐值 | 由 setup.sh 自动生成 |
| `ENCRYPTION_KEY` | 敏感数据加密密钥 | 由 setup.sh 自动生成 |

### 可选环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `NEXTAUTH_URL` | 前端访问地址 | `http://localhost:3000` |
| `LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES` | 启用实验性功能 | `true` |
| `TELEMETRY_ENABLED` | 遥测数据收集 | `false` |
| `NODE_OPTIONS` | Node.js 内存限制 | `--max-old-space-size=4096` |

完整的环境变量说明请参考 `env.example` 文件。

## 常用命令

### 服务管理

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看服务状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f langfuse-web
docker compose logs -f langfuse-worker
docker compose logs -f clickhouse
docker compose logs -f minio
```

### 数据管理

```bash
# 备份 ClickHouse 数据
docker compose exec clickhouse clickhouse-client --query "BACKUP DATABASE default TO Disk('backups', 'backup.tar')"

# 备份 MinIO 数据
docker compose exec minio mc mirror /data /backup

# 清理所有数据（⚠️ 危险操作）
docker compose down -v
```

### 更新服务

```bash
# 拉取最新镜像
docker compose pull

# 重新创建容器（保留数据）
docker compose up -d --force-recreate

# 查看更新日志
docker compose logs -f
```

## 故障排除

### 1. 服务启动失败

**问题**：容器启动后立即退出

**排查步骤**：
```bash
# 查看容器状态
docker compose ps -a

# 查看详细日志
docker compose logs langfuse-web

# 检查环境变量
docker compose config
```

**常见原因**：
- 环境变量缺失或配置错误
- 数据库连接失败（检查 DATABASE_URL）
- Redis 连接失败（检查 REDIS_CONNECTION_STRING）
- 端口被占用

### 2. 数据库连接失败

**问题**：`Connection refused` 或 `Connection timeout`

**解决方案**：
- 检查 PostgreSQL 服务是否运行：`docker ps | grep postgres`
- 检查 DATABASE_URL 中的主机名是否正确
  - ❌ **不要使用 `127.0.0.1`**：在容器中无法访问其他容器
  - ✅ Mac 上使用 `host.docker.internal` 连接宿主机服务
  - ✅ 如果容器在同一网络，使用容器名（如 `postgres-pgvector-17`）
- ⚠️ **注意端口**：你的 PostgreSQL 宿主机端口是 **5433**，不是 5432
- 检查数据库防火墙设置
- 确认数据库用户有远程连接权限
- 验证连接：`docker compose exec langfuse-web sh -c "echo $DATABASE_URL"`

### 3. Redis 连接失败

**问题**：无法连接到 Redis

**解决方案**：
- 检查 Redis 服务是否运行：`docker ps | grep redis`
- 检查 REDIS_CONNECTION_STRING 配置
  - ❌ **不要使用 `127.0.0.1`**：在容器中无法访问其他容器
  - ✅ Mac 上使用 `host.docker.internal` 连接宿主机 Redis
  - ✅ 如果容器在同一网络，使用容器名（如 `redis`）
- 检查 Redis 是否允许外部连接（bind 配置）
- 验证连接：`docker compose exec langfuse-web sh -c "echo $REDIS_CONNECTION_STRING"`

### 4. 端口被占用

**问题**：端口 3000、8123、9000、9001 被占用

**常见情况**：
- **9000 端口冲突**：ClickHouse 使用 9000 作为 Native 接口，如果 MinIO 也使用 9000 会导致冲突
  - 已自动处理：MinIO 的宿主机端口已改为 9002，避免与 ClickHouse 冲突
  - 容器内服务仍使用 `http://minio:9000`（容器内端口保持 9000）

**解决方案**：
```bash
# 检查端口占用
lsof -i :3000
lsof -i :8123
lsof -i :9000
lsof -i :9001
lsof -i :9002

# 查看哪个容器占用了端口
docker ps --format "table {{.Names}}\t{{.Ports}}"

# 修改 docker-compose.yml 中的端口映射
# 例如：将 "3000:3000" 改为 "3001:3000"
# 注意：容器内端口（冒号后）通常不需要修改，只修改宿主机端口（冒号前）
```

### 5. Mac M1 性能问题

**问题**：服务运行缓慢

**解决方案**：
- 确保使用 ARM64 镜像（已配置 `platform: linux/arm64`）
- 增加 Docker Desktop 的内存分配（建议至少 8GB）
- 检查 Docker Desktop 是否使用 Apple Silicon 版本
- 减少其他运行中的应用释放资源

## 性能优化建议

### 资源配置

- **Langfuse Web**: 2 CPU + 4GB RAM（已配置）
- **Langfuse Worker**: 1 CPU + 2GB RAM（已配置）
- **ClickHouse**: 2 CPU + 4GB RAM（已配置）
- **MinIO**: 1 CPU + 2GB RAM（已配置）

### Mac M1 优化

- ✅ 使用 ARM64 架构镜像（已配置）
- ✅ 限制容器资源使用（避免占用过多系统资源）
- ✅ 优化 Node.js 内存配置（NODE_OPTIONS）

## 安全注意事项

1. **密钥管理**：
   - ⚠️ **绝对不要**将 `.env` 文件提交到版本控制系统
   - 使用强随机密钥（setup.sh 会自动生成）
   - 定期更新密钥（需要迁移数据）

2. **网络安全**：
   - 本地开发可以允许外部访问
   - 生产环境建议使用反向代理和 HTTPS
   - 限制数据库和 Redis 的访问权限

3. **数据安全**：
   - 敏感数据使用 ENCRYPTION_KEY 加密存储
   - 定期备份数据
   - 确保 ENCRYPTION_KEY 安全保管

## 版本信息

- **Langfuse 版本**: latest (v3)
- **ClickHouse 版本**: latest (≥24.3)
- **MinIO 版本**: latest
- **Docker Compose 版本**: 3.8+
- **支持平台**: Mac M1/M3 芯片（ARM64）

## 相关资源

- [Langfuse 官方文档](https://langfuse.com/docs)
- [Langfuse v3 发布说明](https://langfuse.com/changelog/2024-12-09-Langfuse-v3-stable-release)
- [Langfuse Docker Compose 部署指南](https://langfuse.com/self-hosting/docker-compose)
- [ClickHouse 官方文档](https://clickhouse.com/docs)
- [MinIO 官方文档](https://min.io/docs)

## 更新日志

### 2025-01-XX
- 初始版本
- 支持 Langfuse v3
- 针对 Mac M1/M3 优化
- 支持外部 PostgreSQL 和 Redis

## 常见问题

### Q: 为什么需要 ClickHouse？

A: Langfuse v3 使用 ClickHouse 作为 OLAP 存储，用于高效存储和查询大量的 traces、observations 等分析数据。这是 v3 的新架构特性。

### Q: 为什么需要 MinIO？

A: Langfuse v3 需要对象存储（S3 兼容）来存储事件和媒体文件。MinIO 是一个轻量级的 S3 兼容存储，适合本地开发使用。

### Q: 可以使用 AWS S3 代替 MinIO 吗？

A: 可以。修改 `.env` 文件中的 S3 相关配置，指向你的 AWS S3 端点即可。

### Q: 如何升级到新版本？

A: 运行 `docker compose pull` 拉取最新镜像，然后 `docker compose up -d --force-recreate` 重新创建容器。

### Q: 数据会丢失吗？

A: 不会。所有数据都存储在 Docker volumes 中，即使容器删除，数据也会保留。只有执行 `docker compose down -v` 才会删除数据。

### Q: 使用 OpenTelemetry 集成时出现超时错误？

A: 这是常见问题，通常是因为 OpenTelemetry OTLP Exporter 的默认超时时间过短。请参考：
- 📖 [OpenTelemetry集成配置指南.md](./OpenTelemetry集成配置指南.md) - 详细的配置说明和解决方案
- 主要解决方案：设置 `timeout=30.0` 或更长的时间
- 确保使用 `BatchSpanProcessor` 并配置适当的批处理参数

### Q: 出现 "Failed to upload JSON to S3" 错误？

A: 这表示 Langfuse 无法将数据上传到 MinIO（S3 存储）。常见原因是存储桶不存在。请参考：
- 📖 [MinIO存储桶配置排查指南.md](./MinIO存储桶配置排查指南.md) - 详细的排查步骤和解决方案
- 🚀 **快速修复**：运行 `./fix_minio_buckets.sh` 自动创建必需的存储桶
- ✅ **自动修复**：使用 `./start.sh` 启动服务时，会自动创建存储桶（推荐）
- 主要解决步骤：
  1. 检查 MinIO 服务是否正常运行
  2. 创建必需的存储桶：`langfuse-events`、`langfuse-media`、`langfuse-exports`
  3. 重启 Langfuse 服务

### Q: 在新电脑上部署时，MinIO 存储桶会自动创建吗？

A: 
- ✅ **如果使用 `./start.sh` 启动**：会自动创建存储桶（已改进）
- ⚠️ **如果使用 `docker compose up -d` 直接启动**：需要手动运行 `./fix_minio_buckets.sh`
- 📖 详细说明请参考：[docker-compose缺陷分析与改进.md](./docker-compose缺陷分析与改进.md)

## 支持

如有问题，请参考：
1. `本地搭建注意要点.md` 文档
2. `OpenTelemetry集成配置指南.md` - OpenTelemetry 集成和超时问题解决
3. `数据库连接排查指南.md` - 数据库连接问题排查
4. `Docker网络配置说明.md` - Docker 网络配置说明
5. [Langfuse 官方文档](https://langfuse.com/docs)
6. [GitHub Issues](https://github.com/langfuse/langfuse/issues)
