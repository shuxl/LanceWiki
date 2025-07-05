当然可以。以下是**完整的主从 MySQL 配置方案**，基于你最初请求的逻辑，并结合了：

- 自动化主从复制环境；
- 使用 my.cnf 配置文件明确指定不同的 server-id；
- 使用 docker-compose 启动容器；
- 手动初始化主从同步逻辑。

---

# 1 ** 文件结构**

```
mysql-replication/
├── docker-compose.yml
├── master/
│   └── my.cnf
└── slave/
    └── my.cnf
```

## 1.1 **docker-compose.yml**

```
version: '3.8'

services:
  mysql-master:
    image: mysql:8.0
    container_name: mysql-master
    ports:
      - "3307:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - ./master/my.cnf:/etc/mysql/my.cnf
    networks:
      - mysql-net

  mysql-slave:
    image: mysql:8.0
    container_name: mysql-slave
    ports:
      - "3308:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
    depends_on:
      - mysql-master
    volumes:
      - ./slave/my.cnf:/etc/mysql/my.cnf
    networks:
      - mysql-net

networks:
  mysql-net:
    driver: bridge
```

## 1.2 **master/my.cnf**

```
[mysqld]
server-id=1
log-bin=mysql-bin
binlog_do_db=testdb
```

## 1.3 **slave/my.cnf**

```
[mysqld]
server-id=2
relay-log=relay-log
read_only=1
```

---

# 2 **启动步骤（在 macOS 上）**

## 2.1 ** 准备目录和文件**

```
mkdir -p ~/mysql-replication/master
mkdir -p ~/mysql-replication/slave
cd ~/mysql-replication
```

使用编辑器（如 nano, vim, VS Code）将上面 YAML 和配置文件内容填入对应文件。

## 2.2 **启动容器**

```
docker compose up -d
```

确保两个容器都启动成功：

```
docker ps
```


# 3 **初始化主从（手动）**

## 3.1 **进入主库，创建数据库、同步用户并获取位点**

```
docker exec -it mysql-master mysql -uroot -proot
```

执行：
```
CREATE DATABASE testdb;

CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;

SHOW MASTER STATUS;
```

**记下输出中的：**
- File（如：mysql-bin.000003）
- Position（如：1018）
然后打开一个新终端窗口配置从库（保持主库锁住表）。

---

## 3.2 ** 在从库设置主从复制**

```
docker exec -it mysql-slave mysql -uroot -proot
```

然后执行：

```
CHANGE MASTER TO
  MASTER_HOST='mysql-master',
  MASTER_USER='repl',
  MASTER_PASSWORD='replpass',
  MASTER_LOG_FILE='mysql-bin.000003',
  MASTER_LOG_POS=1018;

START SLAVE;
```

---

## 3.3 **验证同步是否成功**

```
docker exec -it mysql-slave mysql -uroot -proot -e "SHOW SLAVE STATUS\G"
```

检查以下两项：
- Slave_IO_Running: Yes
- Slave_SQL_Running: Yes
说明主从成功 ✅
## 3.4 从库初始化
```
docker exec -it mysql-slave mysql -uroot -proot

CREATE DATABASE testdb;
```

# 4 测试
+ 进入主库
```
docker exec -it mysql-master mysql -uroot -proot
```
+ 新建表
```
USE testdb;
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100)
);
```
+ 再进入从库，验证表是否同步，以及其它测试