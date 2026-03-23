# Doris SQL基础

## 概述

本文档介绍Doris的SQL基础语法，包括数据库操作、表操作、数据类型和常用函数。

## 数据库操作

### 创建数据库

```sql
-- 创建数据库
CREATE DATABASE IF NOT EXISTS example_db;

-- 指定数据库副本数
CREATE DATABASE example_db
PROPERTIES (
    "replication_num" = "3"
);

-- 查看数据库列表
SHOW DATABASES;

-- 使用数据库
USE example_db;
```

### 删除数据库

```sql
-- 删除数据库
DROP DATABASE IF EXISTS example_db;

-- 强制删除（同时删除数据）
DROP DATABASE example_db FORCE;
```

## 表操作

### 创建表

```sql
-- 创建明细表（Duplicate模型）
CREATE TABLE IF NOT EXISTS example_db.detail_table
(
    user_id LARGEINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age SMALLINT,
    status TINYINT,
    last_visit DATETIME DEFAULT CURRENT_TIMESTAMP
)
DUPLICATE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3",
    "storage_medium" = "SSD"
);

-- 创建聚合表（Aggregate模型）
CREATE TABLE IF NOT EXISTS example_db.agg_table
(
    user_id LARGEINT NOT NULL,
    date DATE NOT NULL,
    city VARCHAR(20),
    uv BIGINT SUM DEFAULT '0'
)
AGGREGATE KEY(user_id, date, city)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3"
);

-- 创建唯一表（Unique模型）
CREATE TABLE IF NOT EXISTS example_db.unique_table
(
    user_id LARGEINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    primary key (user_id)
)
UNIQUE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3"
);
```

### 查看表结构

```sql
-- 查看表结构
DESC table_name;

-- 详细表结构
DESC table_name ALL;

-- 查看表创建语句
SHOW CREATE TABLE table_name;
```

### 修改表

```sql
-- 重命名表
ALTER TABLE old_name RENAME new_name;

-- 添加列
ALTER TABLE table_name ADD COLUMN new_col VARCHAR(50) DEFAULT "" AFTER col1;

-- 删除列
ALTER TABLE table_name DROP COLUMN col_name;

-- 修改列类型
ALTER TABLE table_name MODIFY COLUMN col_name BIGINT;

-- 添加分区
ALTER TABLE table_name ADD PARTITION (p1) VALUES LESS THAN ("100");
```

### 删除表

```sql
-- 删除表
DROP TABLE IF EXISTS table_name;

-- 强制删除（不检查权限）
DROP TABLE table_name FORCE;
```

## 数据类型

### 数值类型

| 类型 | 说明 | 范围 |
|------|------|------|
| TINYINT | 1字节整数 | -128 ~ 127 |
| SMALLINT | 2字节整数 | -32768 ~ 32767 |
| INT | 4字节整数 | -2^31 ~ 2^31-1 |
| BIGINT | 8字节整数 | -2^63 ~ 2^63-1 |
| LARGEINT | 16字节整数 | -2^127 ~ 2^127-1 |
| FLOAT | 4字节浮点 | |
| DOUBLE | 8字节浮点 | |
| DECIMAL | 高精度 | |

### 字符串类型

| 类型 | 说明 | 最大长度 |
|------|------|----------|
| CHAR | 定长字符串 | 255 |
| VARCHAR | 变长字符串 | 65533 |
| STRING | 变长字符串 | 2GB |

### 日期类型

| 类型 | 说明 | 格式 |
|------|------|------|
| DATE | 日期 | YYYY-MM-DD |
| DATETIME | 日期时间 | YYYY-MM-DD HH:MM:SS |
| TIME | 时间 | HH:MM:SS |

## 常用函数

### 聚合函数

```sql
-- COUNT
SELECT COUNT(*) FROM table_name;
SELECT COUNT(DISTINCT col) FROM table_name;

-- SUM
SELECT SUM(col) FROM table_name;

-- AVG
SELECT AVG(col) FROM table_name;

-- MAX/MIN
SELECT MAX(col), MIN(col) FROM table_name;
```

### 字符串函数

```sql
-- 连接字符串
SELECT CONCAT(col1, '-', col2) FROM table_name;

-- 子串
SELECT SUBSTRING(col, 1, 10) FROM table_name;

-- 长度
SELECT LENGTH(col) FROM table_name;

-- 去空格
SELECT TRIM(col), LTRIM(col), RTRIM(col) FROM table_name;

-- 大小写
SELECT UPPER(col), LOWER(col) FROM table_name;
```

### 日期函数

```sql
-- 当前时间
SELECT NOW(), CURDATE(), CURTIME();

-- 日期提取
SELECT YEAR(date_col), MONTH(date_col), DAY(date_col) FROM table_name;

-- 日期计算
SELECT DATE_ADD(date_col, INTERVAL 1 DAY) FROM table_name;
SELECT DATE_SUB(date_col, INTERVAL 1 MONTH) FROM table_name;

-- 日期差
SELECT DATEDIFF(date1, date2) FROM table_name;
```

### 条件函数

```sql
-- IF
SELECT IF(cond, true_val, false_val) FROM table_name;

-- IFNULL
SELECT IFNULL(col, default_val) FROM table_name;

-- CASE WHEN
SELECT
    CASE
        WHEN col < 60 THEN 'fail'
        WHEN col < 90 THEN 'pass'
        ELSE 'excellent'
    END
FROM table_name;
```

## 查询操作

### 基本查询

```sql
-- 查询所有列
SELECT * FROM table_name;

-- 查询指定列
SELECT col1, col2 FROM table_name;

-- 别名
SELECT col1 AS alias_name FROM table_name;

-- 去重
SELECT DISTINCT col FROM table_name;
```

### 条件查询

```sql
-- WHERE条件
SELECT * FROM table_name WHERE col > 100;

-- 多条件
SELECT * FROM table_name WHERE col1 > 100 AND col2 = 'value';

-- IN
SELECT * FROM table_name WHERE col IN (1, 2, 3);

-- LIKE
SELECT * FROM table_name WHERE col LIKE '%pattern%';

-- IS NULL
SELECT * FROM table_name WHERE col IS NULL;
SELECT * FROM table_name WHERE col IS NOT NULL;
```

### 排序和限制

```sql
-- 排序
SELECT * FROM table_name ORDER BY col ASC;
SELECT * FROM table_name ORDER BY col DESC;

-- 多列排序
SELECT * FROM table_name ORDER BY col1 ASC, col2 DESC;

-- 限制结果
SELECT * FROM table_name ORDER BY col LIMIT 10;

-- 分页
SELECT * FROM table_name ORDER BY col LIMIT 10 OFFSET 20;
```

### 分组查询

```sql
-- GROUP BY
SELECT city, COUNT(*) FROM table_name GROUP BY city;

-- HAVING
SELECT city, COUNT(*) as cnt
FROM table_name
GROUP BY city
HAVING cnt > 100;
```

### 联接查询

```sql
-- INNER JOIN
SELECT a.col1, b.col2
FROM table1 a
INNER JOIN table2 b ON a.id = b.id;

-- LEFT JOIN
SELECT a.col1, b.col2
FROM table1 a
LEFT JOIN table2 b ON a.id = b.id;

-- 多表联接
SELECT a.col1, b.col2, c.col3
FROM table1 a
JOIN table2 b ON a.id = b.id
JOIN table3 c ON b.id = c.id;
```

### 子查询

```sql
-- IN子查询
SELECT * FROM table1 WHERE col IN (SELECT col FROM table2);

-- EXISTS子查询
SELECT * FROM table1 WHERE EXISTS (SELECT 1 FROM table2 WHERE table2.id = table1.id);
```
