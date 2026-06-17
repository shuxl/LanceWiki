# Docker 网络配置说明

## 你的当前环境

根据检查，你的 Docker 环境中有：
- **Redis 容器**：`redis`，端口 6379，网络：`redis_app-network`
- **PostgreSQL 容器**：`postgres-pgvector-17`，宿主机端口 5433，容器内端口 5432，网络：`bridge`

## 配置方案

### ⚠️ 重要：为什么 `127.0.0.1` 不对？

在 Docker 容器中，`127.0.0.1` 指向**容器自身**，不会指向宿主机或其他容器。因此：
- ❌ `redis://127.0.0.1:6379/0` - **错误**，容器内无法访问
- ❌ `postgresql://user:pass@127.0.0.1:5432/db` - **错误**，容器内无法访问

### ✅ 方案1：使用容器名（推荐，如果容器在同一网络）

如果 Redis 和 PostgreSQL 容器与 Langfuse 在同一个 Docker 网络中，可以直接使用容器名：

```bash
# .env 文件配置
DATABASE_URL=postgresql://用户名:密码@postgres-pgvector-17:5432/数据库名
DIRECT_URL=${DATABASE_URL}

REDIS_CONNECTION_STRING=redis://redis:6379/0
```

**优点**：
- 性能最好（容器间直接通信）
- 不依赖宿主机网络

**缺点**：
- 需要确保容器在同一网络中

### ✅ 方案2：使用 host.docker.internal（Mac 推荐）

Mac 上的 Docker Desktop 支持 `host.docker.internal` 访问宿主机服务：

```bash
# .env 文件配置
# 注意：PostgreSQL 的宿主机端口是 5433，不是 5432
DATABASE_URL=postgresql://用户名:密码@host.docker.internal:5433/数据库名
DIRECT_URL=${DATABASE_URL}

REDIS_CONNECTION_STRING=redis://host.docker.internal:6379/0
```

**优点**：
- 配置简单，不需要修改网络
- 适用于容器在不同网络的情况
- Mac 上原生支持

**缺点**：
- 需要通过宿主机网络转发，性能略低

### ✅ 方案3：配置外部网络连接（高级）

如果需要最佳性能和隔离性，可以配置 Langfuse 连接到外部容器的网络：

#### 步骤1：修改 docker-compose.yml

取消注释网络配置部分：

```yaml
networks:
  default:
    name: langfuse-network
    driver: bridge
  external_redis:
    name: redis_app-network
    external: true
  external_postgres:
    name: bridge
    external: true
```

然后在服务中添加网络配置：

```yaml
langfuse-web:
  # ... 其他配置 ...
  networks:
    - default
    - external_redis
    - external_postgres
```

#### 步骤2：使用容器名连接

```bash
# .env 文件配置
DATABASE_URL=postgresql://用户名:密码@postgres-pgvector-17:5432/数据库名
DIRECT_URL=${DATABASE_URL}

REDIS_CONNECTION_STRING=redis://redis:6379/0
```

**优点**：
- 性能最好
- 网络隔离清晰

**缺点**：
- 配置较复杂
- 需要修改 docker-compose.yml

## 推荐配置（针对你的环境）

基于你的实际情况，**推荐使用方案2（host.docker.internal）**，因为：
1. 配置最简单
2. 不需要修改 docker-compose.yml
3. Mac 上原生支持
4. 性能足够本地开发使用

### 具体配置

在你的 `.env` 文件中：

```bash
# PostgreSQL 配置
# 注意：你的 PostgreSQL 宿主机端口是 5433，不是 5432
DATABASE_URL=postgresql://你的用户名:你的密码@host.docker.internal:5433/你的数据库名
DIRECT_URL=${DATABASE_URL}

# Redis 配置
REDIS_CONNECTION_STRING=redis://host.docker.internal:6379/0
```

**重要提示**：
- PostgreSQL 的端口是 **5433**（宿主机端口），不是 5432
- 确保你的 PostgreSQL 和 Redis 容器正在运行
- 确保数据库用户有远程连接权限

## 验证配置

配置完成后，可以通过以下方式验证：

```bash
# 1. 启动 Langfuse 服务
docker compose up -d

# 2. 查看日志，检查连接是否成功
docker compose logs -f langfuse-web

# 3. 如果看到连接错误，检查：
#    - 数据库/Redis 容器是否运行
#    - 端口是否正确
#    - 用户名密码是否正确
#    - 数据库是否存在
```

## 常见问题

### Q: 为什么连接失败？

A: 检查以下几点：
1. 容器是否在运行：`docker ps`
2. 端口是否正确（PostgreSQL 是 5433，不是 5432）
3. 用户名密码是否正确
4. 数据库是否存在
5. PostgreSQL 是否允许远程连接

### Q: 如何测试连接？

A: 可以在 Langfuse 容器内测试：

```bash
# 进入容器
docker compose exec langfuse-web sh

# 测试 Redis 连接（如果容器内有 redis-cli）
redis-cli -h host.docker.internal -p 6379 ping

# 测试 PostgreSQL 连接（如果容器内有 psql）
psql "postgresql://user:pass@host.docker.internal:5433/dbname" -c "SELECT 1"
```

### Q: 性能如何？

A: 
- 方案1（容器名）：性能最好，延迟最低
- 方案2（host.docker.internal）：性能良好，适合本地开发
- 方案3（外部网络）：性能最好，但配置复杂

对于本地开发，方案2的性能完全足够。
