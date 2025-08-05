# Redis安装配置

## 重点
- Redis的多种安装方法
- Redis配置文件详解
- Redis启动参数和配置选项
- Redis安全配置和最佳实践

## Redis安装方法

### 1. 源码编译安装

**适用场景：** 需要自定义编译选项、最新版本或特定版本

**安装步骤：**
```bash
# 下载源码
wget https://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable

# 编译安装
make
make install

# 创建配置目录
mkdir /etc/redis
mkdir /var/redis

# 复制配置文件
cp redis.conf /etc/redis/redis.conf
```

### 2. Docker安装

**使用官方镜像：**
```bash
# 拉取镜像
docker pull redis:latest

# 运行容器
docker run -d --name redis-server \
  -p 6379:6379 \
  -v /data/redis:/data \
  redis:latest
```

### 3. 包管理器安装

**Ubuntu/Debian：**
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

**CentOS/RHEL：**
```bash
sudo yum install epel-release
sudo yum install redis
sudo systemctl start redis
sudo systemctl enable redis
```

## Redis配置文件详解

### 重要配置项

#### 网络配置
```bash
# 绑定IP地址
bind 127.0.0.1

# 监听端口
port 6379

# 客户端超时时间
timeout 0

# 最大客户端连接数
maxclients 10000
```

#### 内存配置
```bash
# 最大内存使用量
maxmemory 2gb

# 内存淘汰策略
maxmemory-policy allkeys-lru
```

#### 持久化配置
```bash
# RDB配置
save 900 1
save 300 10
save 60 10000

# AOF配置
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
```

#### 安全配置
```bash
# 设置访问密码
requirepass your_password

# 禁用危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
```

## Redis启动参数

### 基本启动命令
```bash
# 使用默认配置启动
redis-server

# 使用指定配置文件启动
redis-server /path/to/redis.conf

# 指定端口启动
redis-server --port 6380
```

### 常用启动参数
```bash
--port <port>           # 指定端口
--bind <ip>             # 绑定IP地址
--maxmemory <bytes>     # 最大内存
--requirepass <password> # 设置密码
--appendonly yes/no     # 启用AOF
```

## 安全配置

### 1. 访问控制
```bash
# 设置强密码
requirepass your_strong_password

# 限制网络访问
bind 127.0.0.1
```

### 2. 网络安全
```bash
# 启用保护模式
protected-mode yes

# 设置连接超时
timeout 300
```

### 3. 文件权限
```bash
# 创建Redis用户
sudo useradd -r -s /bin/false redis

# 设置文件权限
sudo chown redis:redis /var/lib/redis
sudo chmod 750 /var/lib/redis
```

## 性能调优配置

### 内存优化
```bash
maxmemory 2gb
maxmemory-policy allkeys-lru
activedefrag yes
```

### 网络优化
```bash
tcp-keepalive 300
tcp-nodelay yes
```

### 持久化优化
```bash
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec
```

## 监控和日志配置

### 日志配置
```bash
loglevel notice
logfile /var/log/redis/redis.log
syslog-enabled yes
```

### 慢查询配置
```bash
slowlog-log-slower-than 10000
slowlog-max-len 128
```

## 常见问题解决

### 1. 启动失败
```bash
# 检查端口占用
netstat -tlnp | grep 6379

# 检查配置文件语法
redis-server /etc/redis/redis.conf --test
```

### 2. 内存不足
```bash
# 检查内存使用
redis-cli info memory

# 查看大key
redis-cli --bigkeys
```

### 3. 性能问题
```bash
# 监控命令执行
redis-cli monitor

# 查看慢查询
redis-cli slowlog get 10
```

## Redis关联的其它知识

### 相关技术栈
- **Docker**：Redis容器化部署
- **Kubernetes**：Redis在K8s中的配置
- **监控工具**：Prometheus、Grafana监控Redis
- **备份工具**：Redis数据备份和恢复

### 最佳实践
1. **安全第一**：设置强密码，限制网络访问
2. **性能优化**：合理配置内存和网络参数
3. **监控告警**：设置完善的监控体系
4. **备份策略**：定期备份重要数据
5. **版本管理**：及时更新到稳定版本 