# 1 JdbcTemolate
批量新增例子
```
@Autowired
private JdbcTemplate jdbcTemplate;
@Autowired
private NamedParameterJdbcTemplate namedParameterJdbcTemplate;

public void batchInsert() {
    jdbcTemplate.batchUpdate("INSERT INTO FOO (BAR) VALUES (?)",
            new BatchPreparedStatementSetter() {
                @Override
                public void setValues(PreparedStatement ps, int i) throws SQLException {
                    ps.setString(1, "b-" + i);
                }

                @Override
                public int getBatchSize() {
                    return 2;
                }
            });

    List<Foo> list = new ArrayList<>();
    list.add(Foo.builder().id(100L).bar("b-100").build());
    list.add(Foo.builder().id(101L).bar("b-101").build());
    namedParameterJdbcTemplate
            .batchUpdate("INSERT INTO FOO (ID, BAR) VALUES (:id, :bar)",
                    SqlParameterSourceUtils.createBatch(list));
}
```

批量更新的例子
```
@Autowired
private JdbcTemplate jdbcTemplate;
@Autowired
private SimpleJdbcInsert simpleJdbcInsert;

public void insertData() {
    Arrays.asList("b", "c").forEach(bar -> {
        jdbcTemplate.update("INSERT INTO FOO (BAR) VALUES (?)", bar);
    });

    HashMap<String, String> row = new HashMap<>();
    row.put("BAR", "d");
    Number id = simpleJdbcInsert.executeAndReturnKey(row);
    log.info("ID of d: {}", id.longValue());
}

public void listData() {
    log.info("Count: {}",
            jdbcTemplate.queryForObject("SELECT COUNT(*) FROM FOO", Long.class));

    List<String> list = jdbcTemplate.queryForList("SELECT BAR FROM FOO", String.class);
    list.forEach(s -> log.info("Bar: {}", s));

    List<Foo> fooList = jdbcTemplate.query("SELECT * FROM FOO", new RowMapper<Foo>() {
        @Override
        public Foo mapRow(ResultSet rs, int rowNum) throws SQLException {
            return Foo.builder()
                    .id(rs.getLong(1))
                    .bar(rs.getString(2))
                    .build();
        }
    });
    fooList.forEach(f -> log.info("Foo: {}", f));
}
```

# 2 JdbcTemolate类的介绍 #

JdbcTemplate是Spring JDBC的核心类，封装了常见的JDBC的用法，同时尽量避免常见的错误。该类简化JDBC的操作，我们只需要书写提供SQL的代码和如何返回的结果的代码。JdbcTemplate可以执行查询、更新等操作、初始化对ResultSets的遍历操作以及捕获JDBC异常并将其转换成在org.springframework.dao包下定义的更常规更有用的异常类。

通过实现回调接口，可以自定义这些回调函数的具体操作。其中，PreparedStatementSetter和RowMapper是两个最常用的回调接口。

所有的SQL的操作都被以org.springframework.jdbc.core.JdbcTemplate下的debug级别的日志所记录。

> 说明：该类的实例在配置后是线程安全

## 2.1 JdbcAccessor类介绍 ##

JdbcAccessor类是JdbcTemplate类的基类，用于处理JDBC的连接操作，同时也定义数据源、异常翻译器等常用属性。

## 2.2 JdbcOperations接口介绍 ##

JdbcOperations接口定义了JDBC的一些基本操作，具体实现则放在JdbcTemplate类中，不推荐直接使用，但是由于比较适合于mock和stub，因此在测试的时候是一个非常好的选择。

# 3 JdbcTemplate的变量 #

## 3.1 ignoreWarnings ##

如果该变量为false，那么将抛出JDBC警告(SQL warnings)。默认为true。

> 说明：SQL Warnings 来处理不太严重的异常情况、非致命错误或意想不到的条件，因此可以忽略它们。

## 3.2 fetchSize ##

如果该变量为非负值，那将赋值给用于执行查询的statements的fetchSize变量。默认为-1。

## 3.3 maxRows ##

如果该变量为非负值，那将赋值给用于执行查询的statements的maxRows变量。默认为-1。

## 3.4 queryTimeout ##

如果该变量为非负值，那将赋值给用于执行查询的statements的queryTimeout变量。默认为-1。

## 3.5 skipResultsProcessing ##

如果该变量为true, 那么所有可调用语句处理都将绕过所有结果检查，这可以用来避免一些早期版本oracle jdbc驱动程序(如 10.1.0.2)中的bug。默认为false。

## 3.6 skipUndeclaredResults ##

如果该变量为true,那么有输出参数的存储过程的调用结果检查将被省略，除非skipResultsProcessing为true，否侧其他返回结果都将被处理。默认为false。

## 3.7 dataSource ##

该变量为javax.sql.DataSource类型，从JdbcAccessor类继承而来，可以为null，但是在Spring初始化Bean的时候会检查该变量，如果为null，将抛出IllegalArgumentException,提示"Property 'dataSource' is required"。

## 3.8 exceptionTranslator ##

该变量属于一个函数式接口，用于将SQLException和Spring自定义的DataAccessException转化，从JdbcAccessor类继承而来，可以为null。

## 3.9 lazyInit ##

如果该变量为true,那么知道第一次遇到SQLException，否则不初始化exceptionTranslator。默认为true。

> 因为JdbcAccessor类继承了InitializingBean接口，而JdbcTemplate类由继承了JdbcAccessor类，因此Spring初始化JdbcTemplate这个bean的时候会调用afterPropertiesSet。此时如果lazyInit为false且exceptionTranslator，那么则将对exceptionTranslator尝试初始化，如果dataSource为null则使用SQLStateSQLExceptionTranslator进行初始化，否则使用SQLErrorCodeSQLExceptionTranslator。

## 3.10 nativeJdbcExtractor ##

自定义本地JDBC操作对象，用于操作非标准的JDBC API。

> 为了更好支持JDBC4，SpringFramework工作组于2017年6月7号在Github上的master分支上删除了nativeJdbcExtractor，但其他分支还存在该变量，尚不清楚为了是否恢复该变量

分类: [Spring学习笔记][Spring]

好文要顶 关注我 收藏该文 ![icon_weibo_24.png][] ![wechat.png][]

[![20160801160258.png][]][20160801160258.png 1]

[大明二代][20160801160258.png 1]  
[关注 - 9][- 9]  
[粉丝 - 9][- 9 1]

\+加关注

0

0

[« ][Link 1] 上一篇： [Gradle的介绍与安装][Link 1]  
[» ][Link 2] 下一篇： [DataUtils对Connection的获取、释放和关闭的操作学习][Link 2]


[Spring]: https://www.cnblogs.com/xiao2/category/1032667.html
[icon_weibo_24.png]: https://common.cnblogs.com/images/icon_weibo_24.png
[wechat.png]: https://common.cnblogs.com/images/wechat.png
[20160801160258.png]: https://pic.cnblogs.com/face/1001991/20160801160258.png
[20160801160258.png 1]: https://home.cnblogs.com/u/xiao2/
[- 9]: https://home.cnblogs.com/u/xiao2/followees/
[- 9 1]: https://home.cnblogs.com/u/xiao2/followers/
[Link 1]: https://www.cnblogs.com/xiao2/p/7138487.html
[Link 2]: https://www.cnblogs.com/xiao2/p/7170882.html