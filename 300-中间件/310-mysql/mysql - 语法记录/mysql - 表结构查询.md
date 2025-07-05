# 1 查询表结构(只看字段)
```
    DESC idmp_gc_yp;
    DESCRIBE idmp_gc_yp_20220211;
    SELECT * FROM information_schema.columns WHERE table_name='test_table';
```
# 2 查询表结构描述（表名、备注等信息）
```
    select * from information_schema.TABLES where table_name = 'test_table';

    SELECT * FROM information_schema.columns WHERE table_schema='flexflow' and column_name like '%id%';

	SELECT * FROM information_schema.columns WHERE table_schema='site_pro_common' and table_name like 'mdm_form_data_v2%'
and column_name not in ('id','tenant_id','project_id','form_id','form_value_id','value_version','group_id')
order by table_name asc;

```


# 3 查询表的建表语句
```
    SHOW CREATE TABLE idmp_gc_yp;
```