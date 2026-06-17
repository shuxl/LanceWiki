#!/bin/bash

# ============================================
# Langfuse Docker 环境快速设置脚本
# 适用于 Mac M1/M3 芯片
# ============================================

set -e  # 遇到错误立即退出

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
echo -e "${BLUE}Langfuse Docker 环境设置脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 Docker 环境
echo -e "${YELLOW}[1/6] 检查 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker Desktop${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker 服务未运行，请启动 Docker Desktop${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 环境检查通过${NC}"
echo ""

# 检查端口占用
echo -e "${YELLOW}[2/6] 检查端口占用...${NC}"
PORTS=(3000 8123 9000 9001)
PORT_OCCUPIED=false

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${RED}⚠️  端口 $port 已被占用${NC}"
        PORT_OCCUPIED=true
    fi
done

if [ "$PORT_OCCUPIED" = true ]; then
    echo -e "${YELLOW}提示：如果端口被占用，请修改 docker-compose.yml 中的端口映射${NC}"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ 端口检查通过${NC}"
fi
echo ""

# 检查 .env 文件
echo -e "${YELLOW}[3/6] 检查环境变量配置...${NC}"
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        echo -e "${YELLOW}未找到 .env 文件，从 env.example 创建...${NC}"
        cp env.example .env
        echo -e "${GREEN}✅ 已创建 .env 文件${NC}"
    elif [ -f ".env.example" ]; then
        echo -e "${YELLOW}未找到 .env 文件，从 .env.example 创建...${NC}"
        cp .env.example .env
        echo -e "${GREEN}✅ 已创建 .env 文件${NC}"
    else
        echo -e "${RED}❌ 未找到 env.example 或 .env.example 文件${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
fi
echo ""

# 生成随机密钥
echo -e "${YELLOW}[4/6] 生成随机密钥...${NC}"

# 检查并生成 NEXTAUTH_SECRET
if grep -q "请使用_openssl_rand_-base64_32_生成随机密钥" .env || grep -q "^NEXTAUTH_SECRET=$" .env; then
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac 系统使用 sed -i '' 格式
        sed -i '' "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$NEXTAUTH_SECRET|" .env
    else
        sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$NEXTAUTH_SECRET|" .env
    fi
    echo -e "${GREEN}✅ 已生成 NEXTAUTH_SECRET${NC}"
else
    echo -e "${BLUE}ℹ️  NEXTAUTH_SECRET 已存在，跳过${NC}"
fi

# 检查并生成 SALT
if grep -q "请使用_openssl_rand_-hex_32_生成随机密钥" .env || grep -q "^SALT=$" .env; then
    SALT=$(openssl rand -hex 32)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^SALT=.*|SALT=$SALT|" .env
    else
        sed -i "s|^SALT=.*|SALT=$SALT|" .env
    fi
    echo -e "${GREEN}✅ 已生成 SALT${NC}"
else
    echo -e "${BLUE}ℹ️  SALT 已存在，跳过${NC}"
fi

# 检查并生成 ENCRYPTION_KEY
if grep -q "请使用_openssl_rand_-hex_32_生成随机密钥" .env || grep -q "^ENCRYPTION_KEY=$" .env; then
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
    else
        sed -i "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
    fi
    echo -e "${GREEN}✅ 已生成 ENCRYPTION_KEY${NC}"
else
    echo -e "${BLUE}ℹ️  ENCRYPTION_KEY 已存在，跳过${NC}"
fi
echo ""

# 提示配置数据库和 Redis
echo -e "${YELLOW}[5/6] 配置数据库和 Redis 连接...${NC}"
echo -e "${BLUE}请确保已配置 .env 文件中的以下变量：${NC}"
echo -e "  - ${YELLOW}DATABASE_URL${NC}: PostgreSQL 连接字符串"
echo -e "  - ${YELLOW}REDIS_CONNECTION_STRING${NC}: Redis 连接字符串"
echo ""
echo -e "${BLUE}如果 PostgreSQL/Redis 在宿主机上，Mac 上使用：${NC}"
echo -e "  - ${GREEN}host.docker.internal${NC} 作为主机名"
echo -e "  - 例如：${GREEN}postgresql://user:pass@host.docker.internal:5432/dbname${NC}"
echo ""
read -p "是否已配置数据库和 Redis 连接？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}请先编辑 .env 文件配置数据库和 Redis 连接，然后重新运行此脚本${NC}"
    exit 1
fi
echo ""

# 拉取镜像
echo -e "${YELLOW}[6/6] 拉取 Docker 镜像...${NC}"
if command -v docker compose &> /dev/null; then
    docker compose pull
else
    docker-compose pull
fi
echo -e "${GREEN}✅ 镜像拉取完成${NC}"
echo ""

# MinIO 存储桶说明
echo -e "${YELLOW}MinIO 存储桶说明...${NC}"
echo -e "${BLUE}提示：MinIO 存储桶将在启动服务时自动创建（通过 start.sh）${NC}"
echo -e "${BLUE}如果使用 docker compose up -d 直接启动，可运行 ./fix_minio_buckets.sh 创建存储桶${NC}"
echo ""

# 完成提示
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 环境设置完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}下一步操作：${NC}"
echo -e "  1. 检查 .env 文件中的配置是否正确"
echo -e "  2. 运行启动命令：${GREEN}./start.sh${NC} 或 ${GREEN}docker compose up -d${NC}"
echo -e "  3. 等待服务启动后访问：${GREEN}http://localhost:3000${NC}"
echo ""
echo -e "${BLUE}常用命令：${NC}"
echo -e "  - 启动服务：${GREEN}docker compose up -d${NC}"
echo -e "  - 查看日志：${GREEN}docker compose logs -f${NC}"
echo -e "  - 停止服务：${GREEN}docker compose down${NC}"
echo -e "  - 查看状态：${GREEN}docker compose ps${NC}"
echo ""
