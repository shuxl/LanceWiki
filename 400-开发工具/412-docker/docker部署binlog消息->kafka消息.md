# 1 创建网络
```
docker network create docker-binlog-net
```

# 2 创建容器
+ 构建容器服务，服务列表见文件夹“mysql-binlog”中的yml文件。进入文件夹，执行命令
```
docker compose up -d
```

+ 然后执行[Docker 部署mysql主从](Docker%20部署mysql主从.md)中的主从同步步骤。

+ 然后进入容器检查 binlog 开启状态：
```
docker exec -it mysql mysql -uroot -p
```

```
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW MASTER STATUS;
```

# 3 配置和验证
  **在 Kafka Connect 中注册 Debezium Connector**
 Debezium 2.x 配置
```
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-connector",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "mysql-master",
      "database.port": "3306",
      "database.user": "root",
      "database.password": "root",
      "database.server.id": "184054",
      "topic.prefix": "debezium",
      "database.include.list": "testdb",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.debezium"
    }
  }'
```

```
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-connector",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "mysql-master",
      "database.port": "3306",
      "database.user": "root",
      "database.password": "root",
      "database.server.id": "184054",
      "topic.prefix": "debezium",
      "database.include.list": "testdb",

      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
      "include.schema.changes": "false",
      
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.debezium"
    }
  }'
```

说明：
- database.hostname: mysql 指向你启动的 MySQL 容器（因为在同一网络中）
- database.include.list 是要监听的数据库
- topic.prefix 是 topic 名字前缀，后续会生成的 Kafka topic 如：

验证
```
curl http://localhost:8083/connectors/mysql-connector/status
```
显示
```
{
  "state": "RUNNING",
  "tasks": [
    {
      "state": "RUNNING"
    }
  ]
}
```


如果要重建
```
curl -X DELETE http://localhost:8083/connectors/mysql-connector
```
# 4 **使用 Kafka UI 查看消息**
```
http://localhost:8980/
```
