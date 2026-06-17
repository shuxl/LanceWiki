# OpenTelemetry 与 Langfuse 集成配置指南

## 概述

本文档说明如何配置 OpenTelemetry 与自托管的 Langfuse 服务集成，解决常见的超时和连接问题。

## 问题现象

在使用 OpenTelemetry 向 Langfuse 发送 traces 时，可能遇到以下错误：

```
requests.exceptions.ReadTimeout: HTTPConnectionPool(host='localhost', port=3000): Read timed out. (read timeout=0.16562628746032715)
```

**问题原因**：
- OpenTelemetry OTLP HTTP Exporter 的默认超时时间过短
- Langfuse 服务响应时间可能较长（首次请求、数据库查询等）
- 网络延迟或服务负载较高

## 解决方案

### 方案1：配置 OpenTelemetry OTLP HTTP Exporter 超时（推荐）

#### Python 配置示例

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
import os

# Langfuse 配置
LANGFUSE_HOST = os.getenv("LANGFUSE_HOST", "http://localhost:3000")
LANGFUSE_SECRET_KEY = os.getenv("LANGFUSE_SECRET_KEY")
LANGFUSE_PUBLIC_KEY = os.getenv("LANGFUSE_PUBLIC_KEY")

# 创建 OTLP HTTP Exporter，配置超时时间
exporter = OTLPSpanExporter(
    endpoint=f"{LANGFUSE_HOST}/api/public/otel/v1/traces",  # Langfuse OTLP 端点
    headers={
        "Authorization": f"Basic {base64.b64encode(f'{LANGFUSE_PUBLIC_KEY}:{LANGFUSE_SECRET_KEY}'.encode()).decode()}"
    },
    timeout=30.0,  # 设置超时时间为 30 秒（默认可能只有几秒）
)

# 创建 TracerProvider
resource = Resource.create({
    "service.name": "your-service-name",
    "service.version": "1.0.0",
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(exporter)
provider.add_span_processor(processor)

# 设置全局 TracerProvider
trace.set_tracer_provider(provider)
```

#### 使用环境变量配置（更灵活）

```python
import os
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# 从环境变量读取配置
exporter = OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:3000/api/public/otel/v1/traces"),
    headers={
        "Authorization": f"Basic {base64.b64encode(f'{os.getenv(\"LANGFUSE_PUBLIC_KEY\")}:{os.getenv(\"LANGFUSE_SECRET_KEY\")}'.encode()).decode()}"
    },
    timeout=float(os.getenv("OTEL_EXPORTER_OTLP_TIMEOUT", "30.0")),  # 默认 30 秒
)
```

### 方案2：使用自定义 HTTP 客户端（更高级）

如果需要更细粒度的控制（连接超时、读取超时、重试等）：

```python
import requests
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# 创建自定义 HTTP 会话
session = requests.Session()
adapter = requests.adapters.HTTPAdapter(
    pool_connections=10,
    pool_maxsize=20,
    max_retries=3,  # 自动重试 3 次
    pool_block=False,
)
session.mount("http://", adapter)
session.mount("https://", adapter)

# 创建 Exporter，使用自定义会话
exporter = OTLPSpanExporter(
    endpoint=f"{LANGFUSE_HOST}/api/public/otel/v1/traces",
    headers={
        "Authorization": f"Basic {base64.b64encode(f'{LANGFUSE_PUBLIC_KEY}:{LANGFUSE_SECRET_KEY}'.encode()).decode()}"
    },
    timeout=30.0,
    session=session,  # 使用自定义会话
)
```

### 方案3：配置 BatchSpanProcessor 参数

调整批处理参数，减少请求频率，提高成功率：

```python
from opentelemetry.sdk.trace.export import BatchSpanProcessor

processor = BatchSpanProcessor(
    exporter,
    max_queue_size=2048,  # 队列大小
    export_timeout_millis=30000,  # 导出超时（30秒）
    schedule_delay_millis=5000,  # 批处理延迟（5秒）
    max_export_batch_size=512,  # 每批最大 span 数量
)
```

## 完整配置示例

### Python 完整示例

```python
import os
import base64
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource

def setup_opentelemetry():
    """配置 OpenTelemetry 与 Langfuse 集成"""
    
    # Langfuse 配置
    langfuse_host = os.getenv("LANGFUSE_HOST", "http://localhost:3000")
    langfuse_public_key = os.getenv("LANGFUSE_PUBLIC_KEY")
    langfuse_secret_key = os.getenv("LANGFUSE_SECRET_KEY")
    
    if not langfuse_public_key or not langfuse_secret_key:
        raise ValueError("LANGFUSE_PUBLIC_KEY 和 LANGFUSE_SECRET_KEY 必须设置")
    
    # 创建认证头
    credentials = f"{langfuse_public_key}:{langfuse_secret_key}"
    auth_header = base64.b64encode(credentials.encode()).decode()
    
    # 创建 OTLP Exporter
    exporter = OTLPSpanExporter(
        endpoint=f"{langfuse_host}/api/public/otel/v1/traces",
        headers={
            "Authorization": f"Basic {auth_header}",
            "Content-Type": "application/x-protobuf",
        },
        timeout=30.0,  # 30 秒超时
    )
    
    # 创建资源
    resource = Resource.create({
        "service.name": os.getenv("OTEL_SERVICE_NAME", "my-service"),
        "service.version": os.getenv("OTEL_SERVICE_VERSION", "1.0.0"),
    })
    
    # 创建 TracerProvider
    provider = TracerProvider(resource=resource)
    
    # 创建批处理器
    processor = BatchSpanProcessor(
        exporter,
        max_queue_size=2048,
        export_timeout_millis=30000,  # 30 秒
        schedule_delay_millis=5000,  # 5 秒批处理延迟
        max_export_batch_size=512,
    )
    
    provider.add_span_processor(processor)
    
    # 设置全局 TracerProvider
    trace.set_tracer_provider(provider)
    
    return trace.get_tracer(__name__)

# 使用示例
if __name__ == "__main__":
    # 初始化 OpenTelemetry
    tracer = setup_opentelemetry()
    
    # 创建 span
    with tracer.start_as_current_span("my-operation") as span:
        span.set_attribute("key", "value")
        # 你的业务逻辑
        pass
```

### 环境变量配置

在 `.env` 文件或环境变量中设置：

```bash
# Langfuse 配置
LANGFUSE_HOST=http://localhost:3000
LANGFUSE_PUBLIC_KEY=pk-lf-5068a1df-f703-42da-bc43-8d96968451b9
LANGFUSE_SECRET_KEY=sk-lf-b5f43049-c3ac-4572-ab1d-66e9404efc61

# OpenTelemetry 配置（可选）
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:3000/api/public/otel/v1/traces
OTEL_EXPORTER_OTLP_TIMEOUT=30.0
OTEL_SERVICE_NAME=my-service
OTEL_SERVICE_VERSION=1.0.0
```

## 关键配置参数说明

### OTLPSpanExporter 参数

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `endpoint` | Langfuse OTLP 端点 | `http://localhost:3000/api/public/otel/v1/traces` |
| `timeout` | HTTP 请求超时时间（秒） | `30.0`（默认可能只有几秒） |
| `headers` | HTTP 请求头 | 必须包含 `Authorization` 头 |

### BatchSpanProcessor 参数

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `max_queue_size` | 最大队列大小 | `2048` |
| `export_timeout_millis` | 导出超时（毫秒） | `30000`（30秒） |
| `schedule_delay_millis` | 批处理延迟（毫秒） | `5000`（5秒） |
| `max_export_batch_size` | 每批最大 span 数 | `512` |

## 常见问题排查

### 1. 超时错误

**问题**：`ReadTimeout` 或 `Connection timeout`

**解决方案**：
- ✅ 增加 `timeout` 参数（建议 30 秒或更长）
- ✅ 检查 Langfuse 服务是否正常运行
- ✅ 检查网络连接和防火墙设置
- ✅ 使用 `curl` 测试端点是否可访问：
  ```bash
  curl -v http://localhost:3000/api/public/health
  ```

### 2. 认证失败

**问题**：`401 Unauthorized` 或 `403 Forbidden`

**解决方案**：
- ✅ 检查 `LANGFUSE_PUBLIC_KEY` 和 `LANGFUSE_SECRET_KEY` 是否正确
- ✅ 确认认证头的格式：`Basic <base64(public_key:secret_key)>`
- ✅ 验证 API Key 在 Langfuse 中是否有效

### 3. 连接被拒绝

**问题**：`Connection refused` 或 `ECONNREFUSED`

**解决方案**：
- ✅ 确认 Langfuse 服务正在运行：`docker compose ps`
- ✅ 检查端口是否正确：`http://localhost:3000`
- ✅ 如果从容器内访问，使用容器名或 `host.docker.internal` 而不是 `localhost`

### 4. 端点不存在

**问题**：`404 Not Found`

**解决方案**：
- ✅ 确认端点路径正确：`/api/public/otel/v1/traces`
- ✅ 检查 Langfuse 版本是否支持 OTLP（v3+）
- ✅ 验证 Langfuse 配置中是否启用了 OTLP 端点

## 验证配置

### 1. 测试 Langfuse 端点

```bash
# 测试健康端点
curl http://localhost:3000/api/public/health

# 测试 OTLP 端点（需要认证）
curl -X POST http://localhost:3000/api/public/otel/v1/traces \
  -H "Authorization: Basic $(echo -n 'pk-lf-xxx:sk-lf-xxx' | base64)" \
  -H "Content-Type: application/x-protobuf" \
  -d ""
```

### 2. 检查 OpenTelemetry 日志

启用 OpenTelemetry 调试日志：

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logging.getLogger("opentelemetry").setLevel(logging.DEBUG)
```

### 3. 监控 Langfuse 日志

```bash
# 查看 Langfuse Web 服务日志
docker compose logs -f langfuse-web

# 查看特定错误
docker compose logs langfuse-web | grep -i error
```

## 性能优化建议

1. **使用批处理**：确保使用 `BatchSpanProcessor` 而不是 `SimpleSpanProcessor`
2. **调整批处理参数**：根据应用负载调整 `schedule_delay_millis` 和 `max_export_batch_size`
3. **异步导出**：批处理默认是异步的，不会阻塞主线程
4. **错误处理**：配置适当的错误处理和重试机制
5. **采样**：对于高流量应用，考虑配置采样以减少数据量

## 相关文档

- [Langfuse OpenTelemetry 集成文档](https://langfuse.com/integrations/native/opentelemetry)
- [OpenTelemetry Python SDK 文档](https://opentelemetry.io/docs/instrumentation/python/)
- [OTLP HTTP Exporter 文档](https://opentelemetry-python.readthedocs.io/en/latest/exporter/otlp/proto/http/trace_exporter.html)

## 总结

主要问题通常是**超时时间设置过短**。通过以下方式解决：

1. ✅ 设置 `OTLPSpanExporter` 的 `timeout` 参数为 30 秒或更长
2. ✅ 配置 `BatchSpanProcessor` 的 `export_timeout_millis` 为 30000 毫秒
3. ✅ 确保 Langfuse 服务正常运行且网络可达
4. ✅ 正确配置认证头（`Authorization: Basic ...`）

按照以上配置，应该能够解决超时问题，成功将 traces 发送到 Langfuse。
