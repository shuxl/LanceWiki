# pgVector向量库学习计划

## 学习重点

本文档为向量库小白制定的系统化学习计划，重点包括：

1. **向量数据库基础概念**：理解什么是向量、向量数据库、以及为什么需要向量数据库
2. **pgVector简介**：了解pgVector与PostgreSQL的关系，以及其核心特性
3. **环境搭建**：通过Docker方式快速搭建pgVector学习环境
4. **基础操作**：学习向量的存储、查询、索引等基本操作
5. **实践项目**：通过实际案例（如文本相似度搜索、推荐系统）巩固知识
6. **性能优化**：了解向量索引的原理和优化方法
7. **进阶应用**：探索向量数据库在AI场景中的应用

---

## 第一阶段：向量数据库基础概念

### 1.1 什么是向量（Vector）

向量是一个有序的数字列表，用来表示数据的高维特征。

**关键知识点：**
- 向量是数学中的概念，可以表示为 $(x_1, x_2, ..., x_n)$
- 在机器学习中，向量常用于表示文本、图像、音频等数据
- 向量维度通常从几十到几千不等，常见的如128维、256维、768维、1536维

**实际例子：**
- 文本："今天天气真好" → 经过模型处理 → `[0.1, 0.3, -0.2, 0.5, ...]` (768维向量)
- 图像：一张猫的照片 → 经过CNN模型 → `[0.23, 0.45, 0.12, ...]` (512维向量)

### 1.2 向量相似度

向量相似度用于衡量两个向量的相似程度。

**常用相似度计算方法：**

1. **余弦相似度（Cosine Similarity）**：
   $$
   \text{cos}(\theta) = \frac{\mathbf{A} \cdot \mathbf{B}}{||\mathbf{A}|| \times ||\mathbf{B}||} = \frac{\sum_{i=1}^{n} A_i B_i}{\sqrt{\sum_{i=1}^{n} A_i^2} \times \sqrt{\sum_{i=1}^{n} B_i^2}}
   $$
   - 值域：[-1, 1]，值越大越相似
   - 适用于文本相似度等场景

2. **欧氏距离（Euclidean Distance）**：
   $$
   d(\mathbf{A}, \mathbf{B}) = \sqrt{\sum_{i=1}^{n} (A_i - B_i)^2}
   $$
   - 值越小越相似
   - 适用于空间距离计算

3. **内积（Inner Product/Dot Product）**：
   $$
   \mathbf{A} \cdot \mathbf{B} = \sum_{i=1}^{n} A_i B_i
   $$
   - 值越大越相似（需向量归一化）

### 1.3 为什么需要向量数据库

**传统数据库的局限性：**
- 擅长精确匹配查询（如 WHERE id = 123）
- 不适合相似度搜索（如"找相似的图片"）

**向量数据库的优势：**
- 专门优化了向量存储和相似度搜索
- 支持高效的近似最近邻搜索（ANN - Approximate Nearest Neighbor）
- 可以处理高维向量的快速检索

**应用场景：**
- 语义搜索（如ChatGPT的知识库检索）
- 推荐系统（商品推荐、内容推荐）
- 图像搜索（以图搜图）
- 异常检测
- 去重和聚类

### 1.4 主流向量数据库对比

| 数据库 | 类型 | 特点 | 适用场景 |
|--------|------|------|----------|
| pgVector | PostgreSQL扩展 | 与PostgreSQL深度集成，SQL友好 | 需要关系型+向量混合查询 |
| Milvus | 独立数据库 | 高性能，云原生架构 | 大规模向量检索 |
| Pinecone | 云服务 | 托管服务，易于使用 | 快速原型和中小规模应用 |
| Weaviate | 图向量数据库 | 支持语义图查询 | 复杂的关系型向量查询 |
| Chroma | 轻量级 | 简单易用，嵌入式 | 小规模应用和开发测试 |
| Qdrant | Rust实现 | 高性能，API友好 | 生产环境向量检索 |

---

## 第二阶段：pgVector简介与安装

### 2.1 什么是pgVector

pgVector是PostgreSQL的一个扩展插件，为PostgreSQL添加了向量数据类型和向量相似度搜索功能。

**核心特性：**
- 支持向量数据类型（vector）
- 支持多种距离计算（余弦、欧氏、内积）
- 支持向量索引（IVFFlat、HNSW）加速查询
- 完全兼容PostgreSQL的SQL语法
- 可以结合PostgreSQL的关系型查询

### 2.2 Docker方式安装（推荐新手）

参考：[110-pgvector（pg向量版本）.md](./110-pgvector（pg向量版本）.md)

**步骤1：拉取镜像**
```bash
# 拉取基于 PostgreSQL 16 的镜像
docker pull pgvector/pgvector:pg16

# 或者，拉取基于 PostgreSQL 17 的镜像
docker pull pgvector/pgvector:pg17
```

**步骤2：运行容器**
```bash
docker run -d \
  --name postgres-pgvector-17 \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=vector_db \
  -p 5433:5432 \
  -v postgres_data_17:/var/lib/postgresql/data \
  pgvector/pgvector:pg17
```

**步骤3：验证安装**
```bash
# 进入容器
docker exec -it postgres-pgvector-17 psql -U postgres -d vector_db

# 在psql中执行
CREATE EXTENSION vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';
```

### 2.3 连接数据库

**使用psql命令行：**
```bash
docker exec -it postgres-pgvector-17 psql -U postgres -d vector_db
```

**使用图形化工具（如DBeaver、pgAdmin）：**
- 主机：localhost
- 端口：5433（根据你的端口映射）
- 数据库：vector_db
- 用户名：postgres
- 密码：your_password

---

## 第三阶段：基础操作实践

### 3.1 创建向量表

**练习1：创建简单的文档向量表**

```sql
-- 创建扩展（如果还没创建）
CREATE EXTENSION IF NOT EXISTS vector;

-- 创建文档表，包含文档内容和向量
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    embedding vector(1536),  -- 1536维向量（例如OpenAI的text-embedding-3-small）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**要点说明：**
- `vector(1536)` 表示1536维的向量
- 向量维度需要在创建表时指定，后续不能修改
- 可以根据你使用的嵌入模型选择维度（如384、768、1536等）

### 3.2 插入向量数据

**练习2：插入向量数据**

```sql
-- 插入示例数据（这里使用随机向量作为示例）
INSERT INTO documents (title, content, embedding) VALUES
(
    'Python基础教程',
    'Python是一种高级编程语言...',
    '[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]'::vector  -- 简化示例，实际应该是1536维
);

-- 插入多个向量（实际使用时向量应该是完整维度）
INSERT INTO documents (title, content, embedding) VALUES
(
    'Java编程入门',
    'Java是一种面向对象的编程语言...',
    array[0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,0.1]::vector
),
(
    '数据库设计原理',
    '数据库是存储和管理数据的系统...',
    array[0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,0.1,0.2]::vector
);
```

**注意事项：**
- 实际应用中，向量需要通过嵌入模型（Embedding Model）生成
- 可以使用OpenAI、Hugging Face等模型生成向量

### 3.3 向量相似度查询

**练习3：使用余弦相似度查询**

```sql
-- 查询与给定向量最相似的文档（余弦相似度）
SELECT 
    id,
    title,
    content,
    1 - (embedding <=> '[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]'::vector) AS cosine_similarity
FROM documents
ORDER BY embedding <=> '[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]'::vector
LIMIT 5;
```

**操作符说明：**
- `<->` Defense欧氏距离（L2距离）
- `<#>` 负内积（negative inner product）
- `<=>` 余弦距离（1 - 余弦相似度）

**练习4：使用欧氏距离查询**

```sql
-- 使用欧氏距离查找最近邻
SELECT 
    id,
    title,
    embedding <-> '[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]'::vector AS distance
FROM documents
ORDER BY embedding <-> '[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]'::vector
LIMIT 5;
```

### 3.4 创建向量索引（提升查询性能）

**练习5：创建IVFFlat索引**

```sql
-- 创建IVFFlat索引（需要先有一些数据）
-- IVFFlat适合中等规模数据（< 100万条）
CREATE INDEX ON documents 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- 说明：
-- lists参数：聚类中心数量，一般设置为行数的1/1000到1/10000
-- vector_cosine_ops：用于余弦相似度
-- vector_l2_ops：用于欧氏距离
-- vector_ip_ops：用于内积
```

**练习6：创建HNSW索引（推荐）**

```sql
-- 创建HNSW索引（适合大规模数据，查询速度快）
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- 说明：
-- m：每个节点连接的边数（默认16，范围4-64，越大精度越高但索引越大）
-- ef_construction：构建索引时搜索的候选数（默认64，范围4-1000，越大精度越高但构建越慢）
```

**索引选择建议：**
- **小数据量（< 10万）**：可以不使用索引
- **中等数据量（10万-100万）**：使用IVFFlat索引
- **大数据量（> 100万）**：使用HNSW索引

---

## 第四阶段：实际项目实践

### 4.1 项目1：文本相似度搜索系统

**目标：**构建一个文档相似度搜索系统

**步骤1：准备数据表**
```sql
CREATE TABLE articles (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    embedding vector(1536),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops);
```

**步骤2：生成向量（Python示例）**

```python
# 需要使用OpenAI API或本地嵌入模型
import openai
import psycopg2

# 连接数据库
conn = psycopg2.connect(
    host="localhost",
    port=5433,
    database="vector_db",
    user="postgres",
    password="your_password"
)

# 准备文档
articles = [
    {"title": "Python基础", "content": "Python是一种解释型语言..."},
    {"title": "机器学习入门", "content": "机器学习是人工智能的一个分支..."},
    # ... 更多文档
]

# 生成向量并插入
cur = conn.cursor()
for article in articles:
    # 使用OpenAI生成向量（需要API密钥）
    response = openai.Embedding.create(
        model="text-embedding-3-small",
        input=article["content"]
    )
    embedding = response['data'][0]['embedding']
    
    # 插入数据库
    cur.execute(
        "INSERT INTO articles (title, content, embedding) VALUES (%s, %s, %s)",
        (article["title"], article["content"], str(embedding))
    )

conn.commit()
```

**步骤3：查询相似文档**
```sql
-- 根据查询文本找相似文档
-- 先获取查询文本的向量（通过应用层），然后查询
SELECT 
    id,
    title,
    content,
    1 - (embedding <=> %s::vector) AS similarity
FROM articles
ORDER BY embedding <=> %s::vector
LIMIT 10;
```

### 4.2 项目2：混合查询（关系型+向量）

**场景：**在特定分类中查找相似文档

```sql
-- 添加分类字段
ALTER TABLE articles ADD COLUMN category TEXT;

-- 创建复合索引
CREATE INDEX ON articles (category);
CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops);

-- 混合查询：在"技术"分类中查找相似文档
SELECT 
    id,
    title,
    category,
    1 - (embedding <=> %s::vector) AS similarity
FROM articles
WHERE category = '技术'
ORDER BY embedding <=> %s::vector
LIMIT 10;
```

### 4.3 项目3：推荐系统原型

**场景：**基于用户浏览历史推荐相似内容

```sql
-- 用户浏览记录表
CREATE TABLE user_views (
    user_id BIGINT,
    article_id BIGINT REFERENCES articles(id),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 根据用户最近浏览的文章推荐相似内容
WITH user_recent_articles AS (
    SELECT DISTINCT a.embedding
    FROM user_views uv
    JOIN articles a ON uv.article_id = a.id
    WHERE uv.user_id = 123
    ORDER BY uv.viewed_at DESC
    LIMIT 5
),
user_avg_embedding AS (
    SELECT avg(embedding) AS avg_vec
    FROM user_recent_articles
)
SELECT 
    a.id,
    a.title,
    1 - (a.embedding <=> u.avg_vec::vector) AS similarity
FROM articles a
CROSS JOIN user_avg_embedding u
WHERE a.id NOT IN (SELECT article_id FROM user_views WHERE user_id = 123)
ORDER BY a.embedding <=> u.avg_vec::vector
LIMIT 10;
```

---

## 第五阶段：性能优化与最佳实践

### 5.1 索引参数调优

**HNSW索引调优：**
```sql
-- 高精度场景（牺牲存储和构建时间）
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 32, ef_construction = 200);

-- 平衡场景（推荐）
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- 快速构建场景（适合频繁更新）
CREATE INDEX ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 8, ef_construction = 32);
```

### 5.2 查询性能优化

**设置查询时的ef_search参数：**
```sql
-- 提高查询精度（但会变慢）
SET hnsw.ef_search = 200;

SELECT * FROM documents 
ORDER BY embedding <=> %s::vector 
LIMIT 10;

-- 恢复默认
SET hnsw.ef_search = 40;
```

### 5.3 向量维度选择

**常见嵌入模型维度：**
- **OpenAI text-embedding-3-small**: 1536维
- **OpenAI text-embedding-3-large**: 3072维
- **sentence-transformers/all-MiniLM-L6-v2**: 384维
- **sentence-transformers/all-mpnet-base-v2**: 768维
- **BGE-large-zh**: 1024维

**选择建议：**
- 更高维度：通常精度更高，但存储和计算成本更高
- 更低维度：速度快、存储小，但可能丢失细节
- 根据业务需求选择平衡点

### 5.4 数据更新策略

**批量插入优化：**
```sql
-- 先插入数据，再创建索引（推荐）
-- 1. 插入所有数据
INSERT INTO documents (title, embedding) VALUES ...;

-- 2. 创建索引
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

-- 注意：如果先创建索引再插入，每次插入都会更新索引，会很慢
```

**增量更新：**
- 定期重建索引（适合数据变化不大的场景）
- 使用部分索引（PostgreSQL特性）
- 考虑分表策略（按时间或类别分表）

---

## 第六阶段：与AI模型集成

### 6.1 使用OpenAI生成向量

```python
import openai
import numpy as np

def get_embedding(text, model="text-embedding-3-small"):
    """获取文本的向量表示"""
    response = openai.Embedding.create(
        model=model,
        input=text
    )
    return response['data'][0]['embedding']

# 使用示例
text = "Python是一种编程语言"
embedding = get_embedding(text)
print(f"向量维度: {len(embedding)}")
print(f"向量: {embedding[:5]}...")  # 显示前5维
```

### 6.2 使用本地模型（Hugging Face）

```python
from sentence_transformers import SentenceTransformer
import torch

# 加载模型（首次运行会自动下载）
model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')

# 生成向量
text = "Python是一种编程语言"
embedding = model.encode(text)
print(f"向量维度: {len(embedding)}")
print(f"向量: {embedding[:5]}")
```

### 6.3 构建RAG系统（检索增强生成）

**架构：**
1. 文档库 → 生成向量 → 存储到pgVector
2. 用户查询 → 生成向量 → 在pgVector中搜索相似文档
3. 将检索到的文档作为上下文 → 发送给LLM生成答案

**示例流程：**
```python
# 1. 文档入库
documents = ["文档1内容", "文档2内容", ...]
embeddings = model.encode(documents)
# 存储到pgVector...

# 2. 查询检索
query = "用户问题"
query_embedding = model.encode(query)
# 从pgVector检索相似文档...

# 3. 生成回答
context = "检索到的相关文档内容"
prompt = f"基于以下上下文回答问题：\n{context}\n\n问题：{query}"
answer = llm.generate(prompt)
```

---

## 第七阶段：故障排查与常见问题

### 7.1 常见错误

**错误1：维度不匹配**
```
ERROR: vector dimension 1536 does not match index dimension 768
```
**解决：**检查表定义和插入的向量维度是否一致

**错误2：索引创建失败**
```
ERROR: cannot create index without data
```
**解决：**IVFFlat索引需要先有数据，至少要有lists参数数量的数据

**错误3：查询速度慢**
**解决：**
- 检查是否创建了索引
- 调整ef_search参数
- 检查向量维度是否过高

### 7.2 性能监控

```sql
-- 查看索引大小
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE indexname LIKE '%embedding%';

-- 查看表大小
SELECT 
    pg_size_pretty(pg_total_relation_size('documents')) AS total_size,
    pg_size_pretty(pg_relation_size('documents')) AS table_size,
    pg_size_pretty(pg_total_relation_size('documents') - pg_relation_size('documents')) AS index_size;
```

---

## 学习路径总结

### 新手学习路线图

1. **第1-2周：基础理论学习**
   - [ ] 理解向量和向量相似度的概念
   - [ ] 了解向量数据库的应用场景 python
   - [ ] 完成Docker环境搭建

2. **第3周：基础操作**
   - [ ] 创建向量表
   - [ ] 插入和查询向量数据
   - [ ] 理解三种距离计算方式

3. **第4周：索引与性能**
   - [ ] 学习IVFFlat和HNSW索引
   - [ ] 创建索引并测试性能差异
   - [ ] 理解索引参数的含义

4. **第5-6周：项目实践**
   - [ ] 完成文本相似度搜索项目
   - [ ] 实现混合查询
   - [ ] 构建简单的推荐系统

5. **第7-8周：进阶应用**
   - [ ] 与AI模型集成
   - [ ] 构建RAG系统原型
   - [ ] 性能优化实践

### 实践检查清单

- [ ] 成功搭建pgVector环境
- [ ] 能够创建向量表并插入数据
- [ ] 能够进行向量相似度查询
- [ ] 理解并创建了向量索引
- [ ] 完成至少一个实际项目
- [ ] 理解索引参数调优
- [ ] 能够排查常见问题

### 推荐学习资源

1. **官方文档**：https://github.com/pgvector/pgvector
2. **PostgreSQL文档**：https://www.postgresql.org/docs/
3. **向量数据库对比**：了解不同向量数据库的特点
4. **嵌入模型**：OpenAI、Hugging Face模型文档

---

## pgVector关联的其它知识

### 相关技术栈

1. **PostgreSQL基础**：作为pgVector的基础，需要掌握SQL、索引、查询优化等知识
2. **机器学习基础**：理解嵌入模型、向量空间、相似度计算等概念
3. **Python编程**：用于与pgVector交互、生成向量、构建应用
4. **Docker**：用于快速部署和测试环境
5. **大语言模型（LLM）**：了解如何与ChatGPT、Claude等模型集成，构建RAG系统

### Cogvector扩展学习

1. **Milvus**：学习独立的向量数据库，了解分布式向量检索
2. **Elasticsearch向量搜索**：了解全文检索+向量检索的混合方案
3. **向量压缩技术**：学习量化、降维等优化技术
4. **ANN算法**：深入学习近似最近邻搜索算法原理

### 实际应用场景扩展

1. **搜索引擎**：构建语义搜索系统
2. **推荐系统**：基于向量相似度的内容推荐
3. **知识库问答**：RAG（检索增强生成）系统
4. **图像检索**：以图搜图、相似图片推荐
5. **异常检测**：基于向量距离的异常识别
