# 1 拷贝表
+ 拷贝表结构(不拷贝记录，可以拷贝主键等信息)
    ```
        CREATE TABLE newTableName LIKE oldTableName;
    ```
+ 拷贝表记录
    ```
        INSERT INTO newTableName SELECT * FROM oldTableName; 
    ```
+ 拷贝一个表中其中的一些字段(新表不会有主键)
    ```
        CREATE TABLE newadmin AS   
        (
            SELECT username, password FROM admin   
        );
        CREATE TABLE idmp_gc_yp_2 AS   
        (
            SELECT * FROM idmp_gc_yp   
        );
    ```

+ 将新建的表的字段改名
    ```
        CREATE TABLE newadmin AS   
        (   
            SELECT id, username AS uname, password AS pass FROM admin   
        ) 
    ```

+ 新建表后，拷贝一部分数据
    ```
        CREATE TABLE newadmin AS   
        (   
            SELECT * FROM admin WHERE LEFT(username,1) = 's'   
        )  
    ```

+ 创建表的同时定义表中的字段信息
    ```
        CREATE TABLE newadmin   
        (   
            id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY   
        )   
        AS   
        (   
            SELECT * FROM admin   
        ) 
    ```

# 2 