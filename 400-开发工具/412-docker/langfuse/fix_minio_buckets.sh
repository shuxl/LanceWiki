#!/bin/bash

# ============================================
# MinIO 存储桶自动创建脚本
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
echo -e "${BLUE}MinIO 存储桶自动创建脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 Docker Compose 命令
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ 未找到 docker compose 命令${NC}"
    exit 1
fi

# 检查 MinIO 容器是否运行
echo -e "${YELLOW}检查 MinIO 容器状态...${NC}"
if ! $DOCKER_COMPOSE ps | grep -q "langfuse-minio.*Up"; then
    echo -e "${RED}❌ MinIO 容器未运行${NC}"
    echo -e "${YELLOW}请先启动服务：${GREEN}$DOCKER_COMPOSE up -d${NC}"
    exit 1
fi

echo -e "${GREEN}✅ MinIO 容器正在运行${NC}"
echo ""

# 需要创建的存储桶
BUCKETS=("langfuse-events" "langfuse-media" "langfuse-exports")

echo -e "${YELLOW}检查并创建存储桶...${NC}"

# 首先配置 MinIO 客户端别名（如果未配置）
echo -e "${YELLOW}配置 MinIO 客户端...${NC}"
docker exec langfuse-minio sh -c "mc alias set myminio http://localhost:9000 minioadmin minioadmin 2>/dev/null || true" > /dev/null 2>&1

# 获取当前存储桶列表（用于检查）
CURRENT_BUCKETS=$(docker exec langfuse-minio mc ls myminio 2>/dev/null | awk '{print $NF}' | sed 's|/$||' || echo "")

# 使用 MinIO 客户端 (mc) 创建存储桶
for bucket in "${BUCKETS[@]}"; do
    echo -e "${BLUE}处理存储桶: ${bucket}${NC}"
    
    # 检查存储桶是否已存在
    if echo "$CURRENT_BUCKETS" | grep -q "^${bucket}$"; then
        echo -e "${GREEN}  ✅ 存储桶 '${bucket}' 已存在${NC}"
    else
        # 创建存储桶
        CREATE_RESULT=$(docker exec langfuse-minio mc mb "myminio/${bucket}" 2>&1)
        CREATE_EXIT_CODE=$?
        
        if [ $CREATE_EXIT_CODE -eq 0 ]; then
            echo -e "${GREEN}  ✅ 成功创建存储桶 '${bucket}'${NC}"
            # 更新存储桶列表
            CURRENT_BUCKETS=$(docker exec langfuse-minio mc ls myminio 2>/dev/null | awk '{print $NF}' | sed 's|/$||' || echo "")
        else
            # 检查是否是因为存储桶已存在（某些情况下可能检查不到但创建时会提示已存在）
            if echo "$CREATE_RESULT" | grep -qi "already exists\|already exist\|already own"; then
                echo -e "${GREEN}  ✅ 存储桶 '${bucket}' 已存在${NC}"
            else
                echo -e "${RED}  ❌ 创建存储桶 '${bucket}' 失败${NC}"
                echo -e "${YELLOW}  错误信息: ${CREATE_RESULT}${NC}"
                echo -e "${YELLOW}  提示：请检查 MinIO 日志：${GREEN}$DOCKER_COMPOSE logs minio${NC}"
            fi
        fi
    fi
done

echo ""
echo -e "${YELLOW}当前 Langfuse 相关存储桶列表：${NC}"
# 重新获取最新的存储桶列表
FINAL_BUCKET_LIST=$(docker exec langfuse-minio mc ls myminio 2>/dev/null | awk '{print $NF}' | sed 's|/$||' | grep -E "^langfuse-" || echo "")

if [ -n "$FINAL_BUCKET_LIST" ]; then
    echo "$FINAL_BUCKET_LIST" | while read -r bucket_name; do
        if [ -n "$bucket_name" ]; then
            echo -e "  ${GREEN}✅${NC} ${bucket_name}"
        fi
    done
    echo ""
    echo -e "${GREEN}✅ 所有必需的存储桶已就绪！${NC}"
else
    echo -e "  ${YELLOW}(无 Langfuse 相关存储桶)${NC}"
    echo -e "${RED}⚠️  警告：未找到任何 Langfuse 存储桶${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 存储桶检查完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 提示重启服务
echo -e "${YELLOW}提示：如果刚刚创建了存储桶，建议重启 Langfuse 服务：${NC}"
echo -e "  ${GREEN}$DOCKER_COMPOSE restart langfuse-web langfuse-worker${NC}"
echo ""
