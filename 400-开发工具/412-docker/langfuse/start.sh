#!/bin/bash

# ============================================
# Langfuse Docker 服务启动脚本
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}启动 Langfuse Docker 服务${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ 未找到 .env 文件${NC}"
    echo -e "${YELLOW}请先运行 ./setup.sh 进行初始化${NC}"
    exit 1
fi

# 检查 Docker Compose 命令
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ 未找到 docker compose 命令${NC}"
    exit 1
fi

# 启动服务
echo -e "${YELLOW}启动 Docker 服务...${NC}"
$DOCKER_COMPOSE up -d

echo ""
echo -e "${GREEN}✅ 服务启动中...${NC}"
echo ""

# 等待服务就绪
echo -e "${YELLOW}等待服务就绪（这可能需要几分钟）...${NC}"
echo -e "${BLUE}提示：首次启动需要下载镜像和初始化数据库，请耐心等待${NC}"
echo ""

# 检查服务状态
sleep 5
echo -e "${YELLOW}检查服务状态...${NC}"
$DOCKER_COMPOSE ps

echo ""
echo -e "${YELLOW}等待 MinIO 服务就绪并初始化存储桶...${NC}"

# 等待 MinIO 容器启动
MAX_RETRIES=30
RETRY_INTERVAL=2
RETRY_COUNT=0
MINIO_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if $DOCKER_COMPOSE ps | grep -q "langfuse-minio.*Up"; then
        # 测试 MinIO 是否可访问
        if docker exec langfuse-minio curl -f -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
            MINIO_READY=true
            break
        fi
    fi
    echo -e "${YELLOW}  等待 MinIO 启动... (${RETRY_COUNT}/${MAX_RETRIES})${NC}"
    sleep $RETRY_INTERVAL
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$MINIO_READY" = true ]; then
    echo -e "${GREEN}✅ MinIO 服务已就绪${NC}"
    
    # 自动创建存储桶
    echo -e "${YELLOW}检查并创建 MinIO 存储桶...${NC}"
    
    # 配置 MinIO 客户端别名
    docker exec langfuse-minio sh -c "mc alias set myminio http://localhost:9000 minioadmin minioadmin 2>/dev/null || true" > /dev/null 2>&1
    
    # 需要创建的存储桶
    BUCKETS=("langfuse-events" "langfuse-media" "langfuse-exports")
    
    # 获取当前存储桶列表
    CURRENT_BUCKETS=$(docker exec langfuse-minio mc ls myminio 2>/dev/null | awk '{print $NF}' | sed 's|/$||' || echo "")
    
    BUCKETS_CREATED=0
    for bucket in "${BUCKETS[@]}"; do
        if echo "$CURRENT_BUCKETS" | grep -q "^${bucket}$"; then
            echo -e "${GREEN}  ✅ 存储桶 '${bucket}' 已存在${NC}"
        else
            CREATE_RESULT=$(docker exec langfuse-minio mc mb "myminio/${bucket}" 2>&1)
            CREATE_EXIT_CODE=$?
            
            if [ $CREATE_EXIT_CODE -eq 0 ]; then
                echo -e "${GREEN}  ✅ 成功创建存储桶 '${bucket}'${NC}"
                BUCKETS_CREATED=$((BUCKETS_CREATED + 1))
                CURRENT_BUCKETS=$(docker exec langfuse-minio mc ls myminio 2>/dev/null | awk '{print $NF}' | sed 's|/$||' || echo "")
            elif echo "$CREATE_RESULT" | grep -qi "already exists\|already exist\|already own"; then
                echo -e "${GREEN}  ✅ 存储桶 '${bucket}' 已存在${NC}"
            else
                echo -e "${YELLOW}  ⚠️  创建存储桶 '${bucket}' 失败（可能已存在）${NC}"
            fi
        fi
    done
    
    if [ $BUCKETS_CREATED -gt 0 ]; then
        echo -e "${GREEN}✅ 已创建 ${BUCKETS_CREATED} 个新存储桶${NC}"
    else
        echo -e "${GREEN}✅ 所有存储桶已就绪${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MinIO 服务未就绪，跳过存储桶创建${NC}"
    echo -e "${YELLOW}提示：可以稍后运行 ${GREEN}./fix_minio_buckets.sh${NC} 手动创建存储桶${NC}"
fi

echo ""
echo -e "${YELLOW}检查 langfuse-web 端口 3000 是否可访问...${NC}"

# 检查 langfuse-web 端口是否可访问
MAX_RETRIES=30
RETRY_INTERVAL=5
RETRY_COUNT=0
WEB_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # 检查容器是否运行
    if ! $DOCKER_COMPOSE ps | grep -q "langfuse-web.*Up"; then
        echo -e "${YELLOW}  langfuse-web 容器未运行，等待中... (${RETRY_COUNT}/${MAX_RETRIES})${NC}"
        sleep $RETRY_INTERVAL
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
    fi
    
    # 检查端口 3000 是否可访问
    if command -v nc &> /dev/null; then
        # 使用 nc (netcat) 检查端口
        if nc -z localhost 3000 2>/dev/null; then
            WEB_READY=true
            break
        fi
    elif command -v curl &> /dev/null; then
        # 使用 curl 检查健康端点
        if curl -f -s http://localhost:3000/api/public/health > /dev/null 2>&1; then
            WEB_READY=true
            break
        fi
    else
        # 如果没有 nc 或 curl，至少检查容器健康状态
        if $DOCKER_COMPOSE ps | grep -q "langfuse-web.*healthy"; then
            WEB_READY=true
            break
        fi
    fi
    
    echo -e "${YELLOW}  等待 langfuse-web 在端口 3000 上就绪... (${RETRY_COUNT}/${MAX_RETRIES})${NC}"
    sleep $RETRY_INTERVAL
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$WEB_READY" = true ]; then
    echo -e "${GREEN}✅ langfuse-web 端口 3000 已就绪${NC}"
    
    # 额外检查 Docker 健康状态
    if $DOCKER_COMPOSE ps | grep -q "langfuse-web.*healthy"; then
        echo -e "${GREEN}✅ Docker 健康检查状态：健康${NC}"
    elif $DOCKER_COMPOSE ps | grep -q "langfuse-web.*unhealthy"; then
        echo -e "${YELLOW}⚠️  Docker 健康检查状态：不健康（但端口可访问）${NC}"
        echo -e "${YELLOW}提示：服务可能正在启动中，请稍后查看日志确认${NC}"
    else
        echo -e "${BLUE}ℹ️  Docker 健康检查状态：检查中...${NC}"
    fi
else
    echo -e "${RED}⚠️  langfuse-web 端口 3000 在 ${MAX_RETRIES} 次检查后仍未就绪${NC}"
    echo -e "${YELLOW}请检查日志：${GREEN}$DOCKER_COMPOSE logs langfuse-web${NC}"
    
    # 显示容器状态
    echo -e "${YELLOW}当前容器状态：${NC}"
    $DOCKER_COMPOSE ps | grep "langfuse-web" || echo "  容器未运行"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 服务启动完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}访问信息：${NC}"
echo -e "  - Langfuse Web UI: ${GREEN}http://localhost:3000${NC}"
echo -e "  - MinIO 控制台: ${GREEN}http://localhost:9001${NC}"
echo -e "    - 用户名: ${YELLOW}minioadmin${NC}"
echo -e "    - 密码: ${YELLOW}minioadmin${NC}（可在 .env 中修改）"
echo ""
echo -e "${BLUE}常用命令：${NC}"
echo -e "  - 查看日志：${GREEN}$DOCKER_COMPOSE logs -f${NC}"
echo -e "  - 查看 Web 日志：${GREEN}$DOCKER_COMPOSE logs -f langfuse-web${NC}"
echo -e "  - 查看状态：${GREEN}$DOCKER_COMPOSE ps${NC}"
echo -e "  - 停止服务：${GREEN}$DOCKER_COMPOSE down${NC}"
echo -e "  - 重启服务：${GREEN}$DOCKER_COMPOSE restart${NC}"
echo ""
echo -e "${YELLOW}提示：服务完全启动需要一些时间，请查看日志确认：${NC}"
echo -e "  ${GREEN}$DOCKER_COMPOSE logs -f langfuse-web${NC}"
echo ""
