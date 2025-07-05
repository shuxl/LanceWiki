# 1 查询库的表
```
SHOW TABLES;
```

# 2 查询库的schema
```
SELECT * FROM information_schema.SCHEMATA s where schema_name = 'esae_sponsor';
```

# 3 安全模式
```
show variables like 'SQL_SAFE_UPDATES';
SET SQL_SAFE_UPDATES = 0;
```