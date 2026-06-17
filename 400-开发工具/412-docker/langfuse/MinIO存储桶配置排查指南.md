# MinIO 存储桶配置排查指南

## 问题现象

在使用 OpenTelemetry 向 Langfuse 发送 traces 时，出现以下错误：

```
Failed to export span batch code: 500, reason: {"message":"Internal Server Error","error":"Failed to upload JSON to S3"}
```

**错误原因**：Langfuse 尝试将数据上传到 MinIO（S3 兼容存储）时失败。

## 问题分析

Langfuse 需要将 traces 数据上传到 S3 存储（MinIO），但可能因为以下原因失败：

1. **存储桶不存在**：MinIO 中缺少必需的存储桶
2. **MinIO 服务未正常运行**：容器未启动或健康检查失败
3. **网络连接问题**：langfuse-web 无法访问 minio 容器
4. **认证问题**：访问密钥或密码错误
5. **权限问题**：存储桶权限配置不正确

## 排查步骤

### 1. 检查 MinIO 服务状态

```bash
# 检查 MinIO 容器是否运行
docker compose ps minio

# 查看 MinIO 日志
docker compose logs minio

# 检查 MinIO 健康状态
docker inspect langfuse-minio --format='{{json .State.Health}}' | python3 -m json.tool
```

**预期结果**：容器状态应为 `Up` 或 `Up (healthy)`

### 2. 检查 MinIO 控制台

访问 MinIO 控制台：http://localhost:9001

- 默认用户名：`minioadmin`
- 默认密码：`minioadmin`（可在 `.env` 中修改）

**检查项**：
- ✅ 能否正常登录
- ✅ 存储桶列表是否包含以下存储桶：
  - `langfuse-events`（事件存储）
  - `langfuse-media`（媒体文件存储）
  - `langfuse-exports`（批量导出存储，如果启用了批量导出）

### 3. 检查存储桶是否存在

#### 方式1：通过 MinIO 控制台

1. 登录 MinIO 控制台：http://localhost:9001
2. 查看左侧存储桶列表
3. 确认以下存储桶存在：
   - `langfuse-events`
   - `langfuse-media`
   - `langfuse-exports`（如果启用了批量导出）

#### 方式2：使用 MinIO 客户端（mc）

```bash
# 进入 MinIO 容器
docker exec -it langfuse-minio sh

# 使用 mc 命令列出存储桶
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc ls myminio
```

#### 方式3：使用 curl 检查

```bash
# 检查存储桶是否存在（需要认证）
curl -X GET "http://localhost:9002/langfuse-events" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=minioadmin/..."
```

### 4. 创建缺失的存储桶

如果存储桶不存在，需要手动创建：

#### 方式1：通过 MinIO 控制台创建

1. 登录 MinIO 控制台：http://localhost:9001
2. 点击左侧 "Buckets" 菜单
3. 点击 "Create Bucket" 按钮
4. 创建以下存储桶：
   - `langfuse-events`
   - `langfuse-media`
   - `langfuse-exports`（如果启用了批量导出）

#### 方式2：使用 MinIO 客户端（mc）创建

```bash
# 进入 MinIO 容器
docker exec -it langfuse-minio sh

# 配置 MinIO 客户端
mc alias set myminio http://localhost:9000 minioadmin minioadmin

# 创建存储桶
mc mb myminio/langfuse-events
mc mb myminio/langfuse-media
mc mb myminio/langfuse-exports

# 验证存储桶已创建
mc ls myminio
```

#### 方式3：使用 Python 脚本创建（推荐）

创建一个脚本 `create_minio_buckets.py`：

```python
#!/usr/bin/env python3
"""
创建 Langfuse 所需的 MinIO 存储桶
"""
import boto3
from botocore.exceptions import ClientError
import os

# MinIO 配置
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://localhost:9002")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")

# 需要创建的存储桶
BUCKETS = [
    "langfuse-events",
    "langfuse-media",
    "langfuse-exports",
]

def create_buckets():
    """创建 MinIO 存储桶"""
    # 创建 S3 客户端
    s3_client = boto3.client(
        's3',
        endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=MINIO_ACCESS_KEY,
        aws_secret_access_key=MINIO_SECRET_KEY,
    )
    
    print(f"连接到 MinIO: {MINIO_ENDPOINT}")
    
    # 创建每个存储桶
    for bucket_name in BUCKETS:
        try:
            # 检查存储桶是否已存在
            s3_client.head_bucket(Bucket=bucket_name)
            print(f"✅ 存储桶 '{bucket_name}' 已存在")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                # 存储桶不存在，创建它
                try:
                    s3_client.create_bucket(Bucket=bucket_name)
                    print(f"✅ 成功创建存储桶 '{bucket_name}'")
                except ClientError as create_error:
                    print(f"❌ 创建存储桶 '{bucket_name}' 失败: {create_error}")
            else:
                print(f"❌ 检查存储桶 '{bucket_name}' 时出错: {e}")
    
    # 列出所有存储桶
    print("\n当前存储桶列表：")
    try:
        response = s3_client.list_buckets()
        for bucket in response['Buckets']:
            print(f"  - {bucket['Name']}")
    except ClientError as e:
        print(f"❌ 列出存储桶失败: {e}")

if __name__ == "__main__":
    create_buckets()
```

运行脚本：

```bash
# 安装依赖
pip install boto3

# 运行脚本
python create_minio_buckets.py
```

### 5. 检查网络连接

验证 langfuse-web 容器能否访问 minio 容器：

```bash
# 从 langfuse-web 容器内测试连接
docker exec langfuse-web wget --spider http://minio:9000/minio/health/live 2>&1

# 或者使用 curl（如果容器内有 curl）
docker exec langfuse-web curl -v http://minio:9000/minio/health/live
```

**预期结果**：应该能够成功连接

### 6. 检查环境变量配置

确认 `docker-compose.yml` 中的 MinIO 配置正确：

```bash
# 查看 langfuse-web 容器的环境变量
docker exec langfuse-web env | grep -i s3

# 应该看到类似以下配置：
# LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000
# LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse-events
# LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minioadmin
# LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=minioadmin
```

### 7. 检查 MinIO 认证配置

确认 `.env` 文件中的 MinIO 配置与 `docker-compose.yml` 一致：

```bash
# 查看 .env 文件中的 MinIO 配置
grep -i minio .env

# 应该看到：
# MINIO_ROOT_USER=minioadmin
# MINIO_ROOT_PASSWORD=minioadmin
```

**重要**：确保 `docker-compose.yml` 中的 `MINIO_ROOT_USER` 和 `MINIO_ROOT_PASSWORD` 与 `.env` 文件中的值一致。

### 8. 查看 Langfuse 日志

查看详细的错误信息：

```bash
# 查看 langfuse-web 日志
docker compose logs langfuse-web | grep -i "s3\|minio\|upload\|error"

# 查看 langfuse-worker 日志
docker compose logs langfuse-worker | grep -i "s3\|minio\|upload\|error"

# 查看最近的错误日志
docker compose logs --tail=100 langfuse-web
```

## 解决方案

### 方案1：创建存储桶（最常见）

如果存储桶不存在，按照上述步骤创建存储桶。

### 方案2：修复 MinIO 健康检查

如果 MinIO 容器健康检查失败，可能需要修复健康检查配置（类似 langfuse-web 的问题）。

检查 MinIO 容器内是否有 curl：

```bash
docker exec langfuse-minio curl --version
```

如果没有 curl，需要修改 `docker-compose.yml` 中的健康检查配置。

### 方案3：重启服务

创建存储桶后，重启 Langfuse 服务：

```bash
docker compose restart langfuse-web langfuse-worker
```

### 方案4：检查存储空间

确保 MinIO 有足够的存储空间：

```bash
# 检查 Docker volume 使用情况
docker system df -v | grep minio

# 检查 MinIO 容器内的磁盘空间
docker exec langfuse-minio df -h
```

## 自动化脚本

创建一个自动化脚本来检查和创建存储桶：

```bash
#!/bin/bash
# check_minio_buckets.sh

echo "检查 MinIO 存储桶..."

# 检查 MinIO 容器是否运行
if ! docker compose ps minio | grep -q "Up"; then
    echo "❌ MinIO 容器未运行"
    exit 1
fi

# 使用 MinIO 客户端检查存储桶
docker exec langfuse-minio sh -c "
    mc alias set myminio http://localhost:9000 minioadmin minioadmin 2>/dev/null
    mc ls myminio 2>/dev/null | grep -E 'langfuse-events|langfuse-media|langfuse-exports' || {
        echo '创建缺失的存储桶...'
        mc mb myminio/langfuse-events 2>/dev/null || true
        mc mb myminio/langfuse-media 2>/dev/null || true
        mc mb myminio/langfuse-exports 2>/dev/null || true
        echo '✅ 存储桶创建完成'
    }
"
```

## 验证配置

完成配置后，验证是否正常工作：

```bash
# 1. 检查存储桶是否存在
docker exec langfuse-minio mc ls myminio

# 2. 测试上传（使用 Python 脚本或 curl）

# 3. 查看 Langfuse 日志，确认没有 S3 相关错误
docker compose logs langfuse-web | tail -20
```

## 常见问题

### Q1: 存储桶创建后仍然报错

**可能原因**：
- 存储桶权限不正确
- MinIO 配置未生效
- 需要重启 Langfuse 服务

**解决方案**：
```bash
# 重启 Langfuse 服务
docker compose restart langfuse-web langfuse-worker

# 等待服务启动后，再次测试
```

### Q2: MinIO 控制台无法访问

**可能原因**：
- 端口映射错误
- 防火墙阻止
- MinIO 容器未正常运行

**解决方案**：
```bash
# 检查端口映射
docker compose ps minio

# 检查端口是否被占用
lsof -i :9001

# 查看 MinIO 日志
docker compose logs minio
```

### Q3: 认证失败

**可能原因**：
- `.env` 文件中的 MinIO 凭证与 `docker-compose.yml` 不一致
- 环境变量未正确加载

**解决方案**：
1. 检查 `.env` 文件中的 `MINIO_ROOT_USER` 和 `MINIO_ROOT_PASSWORD`
2. 确保 `docker-compose.yml` 中使用了正确的环境变量
3. 重启服务：`docker compose restart`

## 相关文档

- [MinIO 官方文档](https://min.io/docs)
- [Langfuse S3 配置文档](https://langfuse.com/docs/self-hosting/storage)
- [Docker网络配置说明.md](./Docker网络配置说明.md)

## 总结

主要解决步骤：

1. ✅ **检查 MinIO 服务状态**：确保容器正常运行
2. ✅ **创建必需的存储桶**：`langfuse-events`、`langfuse-media`、`langfuse-exports`
3. ✅ **验证网络连接**：确保 langfuse-web 能访问 minio
4. ✅ **检查认证配置**：确保访问密钥正确
5. ✅ **重启服务**：使配置生效

按照以上步骤排查和修复，应该能够解决 "Failed to upload JSON to S3" 错误。
