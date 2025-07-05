# 1 简单配置方式
+ 核心maven

```pom
<dependency>  
    <groupId>com.h2database</groupId>  
    <artifactId>h2</artifactId>  
</dependency>
```

## 1.1 单数据源
+ 核心配置
``` properties
spring.datasource.url=jdbc:h2:mem:testdb  
spring.datasource.username=sa  
spring.datasource.password=
```

```java
@Autowired  
private DataSource dataSource;  
  
@Autowired  
private JdbcTemplate jdbcTemplate;
```

## 1.2 多数据源
+ 核心配置
``` properties
foo.datasource.url=jdbc:h2:mem:foo  
foo.datasource.username=sa  
foo.datasource.password=  
  
bar.datasource.url=jdbc:h2:mem:bar  
bar.datasource.username=sa  
bar.datasource.password=
```

``` java
@Configuration  
@Log4j2  
public class DataSourceConfig {  
    @Bean  
    @ConfigurationProperties("foo.datasource")  
    public DataSourceProperties fooDataSourceProperties() {  
        return new DataSourceProperties();  
    }  
  
    @Bean  
    public DataSource fooDataSource() {  
        DataSourceProperties dataSourceProperties = fooDataSourceProperties();  
        log.info("foo datasource: {}", dataSourceProperties.getUrl());  
        return dataSourceProperties.initializeDataSourceBuilder().build();  
    }  
  
    @Bean  
    @Resource    public PlatformTransactionManager fooTxManager(DataSource fooDataSource) {  
        return new DataSourceTransactionManager(fooDataSource);  
    }  
  
    @Bean  
    @ConfigurationProperties("bar.datasource")  
    public DataSourceProperties barDataSourceProperties() {  
        return new DataSourceProperties();  
    }  
  
    @Bean  
    public DataSource barDataSource() {  
        DataSourceProperties dataSourceProperties = barDataSourceProperties();  
        log.info("bar datasource: {}", dataSourceProperties.getUrl());  
        return dataSourceProperties.initializeDataSourceBuilder().build();  
    }  
  
    @Bean  
    @Resource    public PlatformTransactionManager barTxManager(DataSource barDataSource) {  
        return new DataSourceTransactionManager(barDataSource);  
    }  
}
```