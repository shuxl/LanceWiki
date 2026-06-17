# docker 安装
```
# 拉取基于 PostgreSQL 16 的镜像
docker pull pgvector/pgvector:pg16

# 或者，拉取基于 PostgreSQL 17 的镜像
docker pull pgvector/pgvector:pg17
```

```
docker run -d \
  --name postgres-pgvector-17 \
  -e POSTGRES_PASSWORD=sxl_pwd_123 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=sxl_pg_db1 \
  -p 5433:5432 \
  -v postgres_data_17:/var/lib/postgresql/data \
  pgvector/pgvector:pg17
```

```
docker run -d --name postgres-sxl-test -e POSTGRES_PASSWORD=test123 -e POSTGRES_DB=sxl_pg_db1 -p 5432:5432 pgvector/pgvector:pg16-trixie
```