# 1 Spring JDBC Template
Spring JDBC Template 是 Spring Framework 提供的用于简化 JDBC 数据库访问的核心工具。其核心类围绕 **JdbcTemplate** 展开，辅以若干策略接口和辅助类，形成一套清晰的协作机制。

## 1.1 **核心类与接口及其功能**

| **类/接口**                                                     | **功能说明**                                                         |
| ------------------------------------------------------------ | ---------------------------------------------------------------- |
| **JdbcTemplate**                                             | Spring JDBC 的核心类，封装了 JDBC 操作（增删改查、调用存储过程、批处理等），提供模板方法屏蔽底层样板代码。   |
| **DataSource**                                               | 提供数据库连接的接口（通常由连接池实现，如 HikariDataSource）。JdbcTemplate 持有其引用以获取连接。 |
| **RowMapper**                                                | 将 ResultSet 中的每一行映射为 Java 对象。例如 BeanPropertyRowMapper<T>。        |
| **ResultSetExtractor**                                       | 用于从整个 ResultSet 中提取数据，不逐行处理，适合复杂结构。                              |
| **PreparedStatementSetter**                                  | 用于给 SQL 的占位符参数设值。                                                |
| **BatchPreparedStatementSetter**                             | 用于批处理时为每一条语句设置参数。                                                |
| **SqlParameter** / **SqlOutParameter**                       | 用于存储过程参数定义。                                                      |
| **CallableStatementCreator** / **CallableStatementCallback** | 用于调用存储过程或函数。                                                     |
| **StatementCallback**                                        | 执行普通语句的回调接口。                                                     |

---

## 1.2 **核心类协作流程（以常见的查询为例）**

**示例代码**
```
List<User> users = jdbcTemplate.query(
    "SELECT * FROM users WHERE status = ?",
    new Object[] { "ACTIVE" },
    new BeanPropertyRowMapper<>(User.class)
);
```

**底层协作过程解析：**
1. **JdbcTemplate.query(…)**
    - 接收 SQL 和参数，构造 PreparedStatement。
2. **DataSource.getConnection()**
    - 从连接池获取一个 Connection。
3. **PreparedStatementSetter**
    - 自动将参数（“ACTIVE”）绑定到 SQL 占位符。
4. **执行 SQL，返回 ResultSet**
5. **RowMapper**
    - BeanPropertyRowMapper 将每行映射为 User 实例。
6. **收集所有行组成结果 List 并返回**
7. **自动关闭资源**
    - 使用 try-finally 模式关闭 ResultSet / Statement / Connection。

## 1.3 **JdbcTemplate 提供的主要方法分类**

| **方法名**             | **功能**                                       |
| ------------------- | -------------------------------------------- |
| query(...)          | 执行查询并返回多个结果（支持 RowMapper、ResultSetExtractor） |
| queryForObject(...) | 查询并返回单个对象（常用于聚合、单记录）                         |
| queryForList(...)   | 返回 List<Map<String, Object>>                 |
| queryForMap(...)    | 返回单条记录的 Map 结构                               |
| update(...)         | 执行 INSERT/UPDATE/DELETE 操作                   |
| batchUpdate(...)    | 批量更新                                         |
| execute(...)        | 执行任意 SQL（无返回）或存储过程调用                         |
| call(...)           | 用于调用存储过程，返回 Map 结构                           |

## 1.4 **典型协作图示（简化）**

```
Client Code
   |
JdbcTemplate (模板核心)
   |
+---> DataSource.getConnection()
|         |
|    JDBC Connection
|         |
+---> create PreparedStatement
|         |
+---> set parameters
|         |
+---> execute query
|         |
+---> process ResultSet (RowMapper / ResultSetExtractor)
|         |
+---> close resources
```
  
## 1.5 核心时序图
以下是 **Spring JDBC Template** 的 **类图（PlantUML 格式）** 以及 execute / query / getConnection 三个方法的 **时序图（PlantUML 格式）**，帮助你清晰理解其结构与运行机制。

### 1.5.1 **Spring JDBC Template 核心类图（PlantUML）**

``` plantuml

interface DataSource {
    +getConnection(): Connection
}

interface RowMapper<T> {
    +mapRow(ResultSet, int): T
}

interface ResultSetExtractor<T> {
    +extractData(ResultSet): T
}

interface PreparedStatementSetter {
    +setValues(PreparedStatement)
}

class JdbcTemplate {
    -DataSource dataSource
    +query(sql: String, args: Object[], rowMapper: RowMapper): List<T>
    +update(sql: String, args: Object[]): int
    +execute(sql: String): void
}

JdbcTemplate --> DataSource : uses
JdbcTemplate --> RowMapper : uses
JdbcTemplate --> ResultSetExtractor : uses
JdbcTemplate --> PreparedStatementSetter : uses

```


### 1.5.2 JdbcTemplate.execute(sql) 时序图（PlantUML）

``` plantuml
actor Client
participant "JdbcTemplate" as JT
participant "DataSource" as DS
participant "Connection" as Conn
participant "Statement" as Stmt

Client -> JT : execute("DROP TABLE temp")
JT -> DS : getConnection()
DS -> Conn : return Connection
JT -> Conn : createStatement()
Conn -> Stmt : return Statement
JT -> Stmt : execute("DROP TABLE temp")
Stmt -> JT : return
JT -> Stmt : close()
JT -> Conn : close()

```


### 1.5.3 JdbcTemplate.query(sql, args, rowMapper)时序图

``` plantuml
actor Client
participant "JdbcTemplate" as JT
participant "DataSource" as DS
participant "Connection" as Conn
participant "PreparedStatement" as PS
participant "ResultSet" as RS
participant "RowMapper" as RM

Client -> JT : query("SELECT * FROM users WHERE id = ?", [1], rowMapper)
JT -> DS : getConnection()
DS -> Conn : return Connection
JT -> Conn : prepareStatement(sql)
Conn -> PS : return PreparedStatement
JT -> PS : setObject(1, 1)
JT -> PS : executeQuery()
PS -> RS : return ResultSet

loop for each row
    JT -> RM : mapRow(ResultSet, rowNum)
    RM --> JT : return mapped object
end

JT -> RS : close()
JT -> PS : close()
JT -> Conn : close()
Client <- JT : return List<T>
```



### 1.5.4 声明式事务控制下 JdbcTemplate 的时序图

``` plantuml

actor Client
participant "Proxy (AOP)" as Proxy
participant "TransactionalInterceptor" as TxInterceptor
participant "PlatformTransactionManager" as TM
participant "JdbcTemplate" as JT
participant "DataSource" as DS
participant "Connection" as Conn

Client -> Proxy : call @Transactional method
Proxy -> TxInterceptor : invoke()
TxInterceptor -> TM : getTransaction()
TM -> DS : getConnection()
DS -> Conn : return Connection
TM -> Conn : setAutoCommit(false)
TxInterceptor -> JT : execute JDBC logic
JT -> Conn : prepareStatement / execute

alt no exception
    TxInterceptor -> TM : commit()
    TM -> Conn : commit()
else exception
    TxInterceptor -> TM : rollback()
    TM -> Conn : rollback()
end

TxInterceptor -> Conn : close()
TxInterceptor -> Proxy : return result

```

 **说明**
- **Proxy (AOP)**：由 Spring 创建的代理对象，拦截调用。
- **TransactionalInterceptor**：AOP 拦截器，负责事务控制逻辑。
- **PlatformTransactionManager**：事务管理器，控制提交/回滚。
- **JdbcTemplate**：执行业务逻辑，使用 DataSource 获取连接。
- **连接复用**：Spring 会通过 TransactionSynchronizationManager 绑定 Connection，JdbcTemplate 获取到的是已绑定的事务连接。

## 1.6 **总结**

Spring JDBC Template 的设计思想：
- 使用模板方法模式（Template Method）抽象出通用流程。
- 将变动部分（如参数设置、结果映射）交由回调接口定制。
- 最大限度简化 JDBC 操作，提升开发效率并避免资源泄漏。

# 2 RDBMS
## 2.1 SqlQuery分析
 
 Spring JDBC 中以 SqlQuery 为起点的 RDBMS 抽象层,封装并调用 JdbcTemplate 的。  

> 以 org.springframework.jdbc.object.SqlQuery 为核心，梳理其如何封装 JdbcTemplate，并形成数据库访问的调用链。

### 2.1.1 SqlQuery是什么？

- `SqlQuery<T>` 是 Spring JDBC 提供的抽象类，位于包：
```
org.springframework.jdbc.object.SqlQuery<T>
```

- 它是对 **SQL 查询操作的对象封装**，提供了模板方法模式的封装，开发者只需定义 SQL 和参数绑定，底层由 Spring 管理执行逻辑。

### 2.1.2 SqlQuery 类结构概览

```
SqlOperation (抽象类)
  └── SqlQuery<T> (抽象类)
       └── MappingSqlQuery<T> // 可用于行映射
```

- SqlOperation 是操作基础类，封装了 JdbcTemplate 和 SQL。
- `SqlQuery<T>` 增加了查询语义，执行逻辑封装。
- `MappingSqlQuery<T>` 增加了 `RowMapper<T>` 支持，简化结果集对象映射。

### 2.1.3 调用链关系（执行查询）以SqlQuery.execute(Object... params)为例：

#### 2.1.3.1 入口方法

```
public List<T> execute(Object... parameters) {
    validateParameters(parameters);
    return executeQuery(parameters);
}
```

#### 2.1.3.2 核心执行：executeQuery

```
protected List<T> executeQuery(final Object[] parameters) {
    return getJdbcTemplate().query(
        newPreparedStatementCreator(parameters),
        newRowMapperResultSetExtractor());
}
```

#### 2.1.3.3 PreparedStatementCreator 创建

```
protected PreparedStatementCreator newPreparedStatementCreator(Object[] parameters) {
    return getPreparedStatementFactory().newPreparedStatementCreator(parameters);
}
```

- PreparedStatementCreator：准备 SQL + 绑定参数。

#### 2.1.3.4 RowMapperResultSetExtractor 构造

```
protected RowMapperResultSetExtractor<T> newRowMapperResultSetExtractor() {
    return new RowMapperResultSetExtractor<>(this.rowMapper);
}
```

#### 2.1.3.5 JdbcTemplate 执行核心

```
JdbcTemplate.query(PreparedStatementCreator psc, ResultSetExtractor<T> rse)
```

- JdbcTemplate 会：
    - 从 DataSource 获取连接；
    - 使用 PreparedStatementCreator 创建语句并绑定参数；
    - 执行查询；
    - 用 ResultSetExtractor 或 RowMapper 处理结果集；
    - 自动释放资源；
    - 捕获并转换 SQL 异常。

### 2.1.4 调用链图解

```
SqlQuery.execute(...)
    └── executeQuery(parameters)
        ├── newPreparedStatementCreator(...)
        │     └── PreparedStatementFactory.newPreparedStatementCreator(...)
        ├── newRowMapperResultSetExtractor()
        │     └── new RowMapperResultSetExtractor(RowMapper)
        └── JdbcTemplate.query(psc, rse)
              ├── getConnection()
              ├── psc.createPreparedStatement()
              ├── stmt.executeQuery()
              └── rse.extractData(ResultSet)
```

### 2.1.5 使用示例

```
public class UserByIdQuery extends MappingSqlQuery<User> {
    public UserByIdQuery(DataSource ds) {
        super(ds, "SELECT id, name FROM users WHERE id = ?");
        declareParameter(new SqlParameter("id", Types.INTEGER));
        compile();
    }

    @Override
    protected User mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new User(rs.getInt("id"), rs.getString("name"));
    }
}

// 使用：
UserByIdQuery query = new UserByIdQuery(dataSource);
User user = query.findObject(1);
```

### 2.1.6 小结

| **层级**                      | **作用**                   |
| --------------------------- | ------------------------ |
| SqlQuery / MappingSqlQuery  | 提供查询的模板定义，屏蔽 JDBC 实现细节   |
| PreparedStatementCreator    | 封装参数绑定逻辑                 |
| RowMapperResultSetExtractor | 提取结果集并映射为 Java 对象        |
| JdbcTemplate                | 执行实际 JDBC 操作，提供统一异常和资源管理 |
| DataSource                  | 提供连接（可由连接池支持）            |

## 2.2 SqlUpdate分析
在 SqlQuery 封装了“查询类操作”，而 SqlUpdate 封装了“写操作”如 INSERT/UPDATE/DELETE。
下面我们就以 SqlUpdate 为核心，分析它对 JdbcTemplate 的封装与调用链。

### 2.2.1 SqlUpdate的基本介绍

- SqlUpdate 是 Spring JDBC 提供的一个封装类，位于包：
```
org.springframework.jdbc.object.SqlUpdate
```
- 它是用于封装 **数据写操作** 的类（即非 SELECT 查询）。
它的继承关系如下：
```
SqlOperation
  └── SqlUpdate
```
- SqlOperation 是公共抽象基类（也被 SqlQuery 继承）
- 这意味着 SqlUpdate 和 SqlQuery 在结构上类似，但内部调用的 JdbcTemplate 方法是不同的。

### 2.2.2 SqlUpdate 封装的核心思想

- **目标**：封装好 SQL + 参数信息 → 调用 JdbcTemplate.update(...) 来完成执行。
- **支持命名参数**：通过 SqlParameter 声明参数位置和类型。
- **隐藏了 PreparedStatement 创建、异常处理和资源管理**。


### 2.2.3 调用链梳理

#### 2.2.3.1 假设代码

```
SqlUpdate update = new SqlUpdate(dataSource, "UPDATE users SET name = ? WHERE id = ?");
update.declareParameter(new SqlParameter("name", Types.VARCHAR));
update.declareParameter(new SqlParameter("id", Types.INTEGER));
update.compile();

int rows = update.update("Tom", 1);
```

#### 2.2.3.2 对应调用链（精简逻辑）

```
update(...)                            ← 调用入口
  └── update(Object... params)         ← SqlUpdate
       └── validateParameters(...)     ← SqlOperation
       └── getJdbcTemplate().update(...) ← JdbcTemplate
            ├── getConnection()
            ├── PreparedStatementCreator.createPreparedStatement()
            ├── stmt.executeUpdate()
            └── return affectedRows
```

#### 2.2.3.3 与 SqlQuery 最大的不同：

|**比较项**|**SqlQuery**|**SqlUpdate**|
|---|---|---|
|JdbcTemplate 方法|query(...)|update(...)|
|结果处理方式|ResultSetExtractor / RowMapper|返回影响行数（int）|
|目标用途|查询类|写操作类（增、删、改）|
|子类|MappingSqlQuery, UpdatableSqlQuery|无常用子类（可直接使用）|


### 2.2.4 源码分析（以SqlUpdate.update(Object...)为起点）

#### 2.2.4.1 **方法定义：**

```
public int update(Object... parameters) throws DataAccessException {
    validateParameters(parameters);
    return getJdbcTemplate().update(
        newPreparedStatementCreator(parameters));
}
```

- 生成 PreparedStatementCreator 绑定参数
- 调用 JdbcTemplate.update(...)

#### 2.2.4.2 进入JdbcTemplate.update(...)

```
@Override
public int update(PreparedStatementCreator psc) throws DataAccessException {
    return update(psc, null);
}

@Override
public int update(PreparedStatementCreator psc, @Nullable PreparedStatementSetter pss)
        throws DataAccessException {

    return updateCount(execute(psc, ps -> {
        if (pss != null) {
            pss.setValues(ps);
        }
        return ps.executeUpdate();
    }));
}
```

- 获取连接
- 使用 psc 创建 PreparedStatement
- 可选使用 PreparedStatementSetter 绑定参数
- 调用 ps.executeUpdate()
- 返回 影响的行数

### 2.2.5 类结构与依赖关系图

```
        DataSource
            ↑
     JdbcTemplate
            ↑
      SqlOperation
            ↑
        SqlUpdate
            ↓
 newPreparedStatementCreator(...)
            ↓
PreparedStatementFactory
            ↓
PreparedStatementCreator
            ↓
JdbcTemplate.update(...)
```

### 2.2.6 完整使用示例

```
public class UpdateUserName extends SqlUpdate {
    public UpdateUserName(DataSource ds) {
        super(ds, "UPDATE users SET name = ? WHERE id = ?");
        declareParameter(new SqlParameter("name", Types.VARCHAR));
        declareParameter(new SqlParameter("id", Types.INTEGER));
        compile();
    }
}

// 使用
UpdateUserName updater = new UpdateUserName(dataSource);
int affected = updater.update("Tom", 1);
System.out.println("更新影响行数：" + affected);
```

### 2.2.7 总结：SqlQuery vs SqlUpdate 对 JdbcTemplate 的封装对比表

|**特性**|**SqlQuery**|**SqlUpdate**|
|---|---|---|
|继承结构|SqlOperation → SqlQuery|SqlOperation → SqlUpdate|
|操作类型|查询类|更新类|
|JdbcTemplate 方法|query(...)|update(...)|
|结果处理|RowMapper, ResultSetExtractor|int（受影响行数）|
|异常处理|都会使用 SQLExceptionTranslator → 转为 Spring DataAccessException||
|参数支持|支持类型声明、命名参数、位置绑定||
