# Doris数据导入

## 概述

本文档介绍Doris的各种数据导入方式，包括Stream Load、Broker Load、Routine Load、Insert和S3 Import。

## Stream Load

适用场景：本地文件导入中小数据量

### 基本语法

```bash
# 准备数据文件
cat > data.csv << EOF
1,user1,25
2,user2,30
3,user3,28
EOF

# 执行Stream Load
curl --location-trusted -u root: \
    -T data.csv \
    -H "column_separator:," \
    -H "columns: id, name, age" \
    http://fe_host:8030/api/database/table/_stream_load
```

### 参数说明

| 参数 | 说明 |
|------|------|
| -T | 要上传的文件 |
| -H "column_separator" | 列分隔符 |
| -H "columns" | 列映射 |
| -H "where" | 条件过滤 |
| -H "max_filter_ratio" | 最大过滤比例 |

### 示例

```bash
# CSV文件导入
curl --location-trusted -u root: \
    -T /path/to/data.csv \
    -H "column_separator:," \
    -H "columns: user_id, name, age, city" \
    -H "label: my_load_001" \
    http://fe_host:8030/api/example_db/user_table/_stream_load

# 带条件导入
curl --location-trusted -u root: \
    -T /path/to/data.csv \
    -H "column_separator:," \
    -H "columns: user_id, name, age, city" \
    -H "where: age > 18" \
    -H "label: my_load_002" \
    http://fe_host:8030/api/example_db/user_table/_stream_load

# JSON格式导入
curl --location-trusted -u root: \
    -T /path/to/data.json \
    -H "format: json" \
    -H "strip_outer_array: true" \
    -H "jsonpaths: $.id, $.name, $.age" \
    -H "label: my_load_json" \
    http://fe_host:8030/api/example_db/user_table/_stream_load
```

## Broker Load

适用场景：大规模数据导入，支持多种数据源

### 基本语法

```sql
-- 创建broker加载任务
LOAD LABEL example_db.label_001
(
    DATA INFILE("hdfs://namenode:9000/path/data.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (id, name, age)
)
WITH BROKER broker_name
(
    "username" = "hdfs_user",
    "password" = "hdfs_password"
)
PROPERTIES
(
    "timeout" = "3600",
    "max_filter_ratio" = "0.1"
);
```

### 完整示例

```sql
-- Hive表导入
LOAD LABEL example_db.hive_load_001
(
    DATA INFILE("hdfs://namenode:9000/user/hive/warehouse/db/tbl/*")
    INTO TABLE target_table
    COLUMNS TERMINATED BY "\t"
    (col1, col2, col3)
)
WITH BROKER broker_name
(
    "hdfs.confs.core.site.xml" = "/path/to/core-site.xml",
    "hdfs.confs.hdfs.site.xml" = "/path/to/hdfs-site.xml"
)
PROPERTIES
(
    "timeout" = "3600"
);

-- 多文件导入
LOAD LABEL example_db.multi_file_load
(
    DATA INFILE("hdfs://namenode:9000/path/file1.csv")
    INTO TABLE table1
    COLUMNS TERMINATED BY ","
    (c1, c2, c3),
    DATA INFILE("hdfs://namenode:9000/path/file2.csv")
    INTO TABLE table2
    COLUMNS TERMINATED BY ","
    (c1, c2, c3)
)
WITH BROKER broker_name;
```

### 查看加载状态

```sql
-- 查看所有导入任务
SHOW LOAD;

-- 查看特定Label的任务
SHOW LOAD WHERE LABEL = "label_001";

-- 查看正在运行的导入任务
SHOW LOAD WHERE LABEL = "label_001"\G
```

## Routine Load

适用场景：实时数据导入（如Kafka）

### 创建Routine Load

```sql
-- 创建Kafka导入任务
CREATE ROUTINE LOAD example_db.kafka_load_001
ON target_table
COLUMNS TERMINATED BY ","
(
    k1, k2, k3
)
FROM KAFKA
(
    "kafka_broker_list" = "broker1:9092,broker2:9092",
    "kafka_topic" = "my_topic",
    "kafka_partitions" = "0,1,2,3",
    "kafka_offsets" = "OFFSET_BEGINNING"
)
PROPERTIES
(
    "desired_concurrent_number" = "5",
    "max_filter_ratio" = "0.1",
    "timeout" = "3600"
);
```

### 管理Routine Load

```sql
-- 暂停导入任务
PAUSE ROUTINE LOAD FOR example_db.kafka_load_001;

-- 恢复导入任务
RESUME ROUTINE LOAD FOR example_db.kafka_load_001;

-- 停止导入任务
STOP ROUTINE LOAD FOR example_db.kafka_load_001;

-- 查看任务状态
SHOW ROUTINE LOAD;

-- 查看任务详情
SHOW ROUTINE LOAD FOR example_db.kafka_load_001;

-- 查看任务分区状态
SHOW ROUTINE LOAD TASK FOR example_db.kafka_load_001;
```

### Kafka配置说明

| 属性 | 说明 |
|------|------|
| kafka_broker_list | Kafka broker地址 |
| kafka_topic | Kafka主题 |
| kafka_partitions | 要消费的分区 |
| kafka_offsets | 起始消费位置 |

## Insert

适用场景：小数据量导入、数据转换

### 基本语法

```sql
-- 插入单行
INSERT INTO table_name (col1, col2, col3)
VALUES (1, 'value1', '2024-01-01');

-- 插入查询结果
INSERT INTO table_name
SELECT col1, col2, col3 FROM source_table;

-- 带有OVERWRITE
INSERT OVERWRITE table_name
SELECT col1, col2, col3 FROM source_table;
```

### 示例

```sql
-- 从另一张表导入
INSERT INTO target_table
SELECT * FROM source_table WHERE create_date >= '2024-01-01';

-- 带转换的导入
INSERT INTO target_table (id, name, status)
SELECT
    user_id,
    CONCAT(first_name, last_name),
    CASE WHEN age > 18 THEN 1 ELSE 0 END
FROM source_table;

-- 清空表并重新导入
INSERT OVERWRITE target_table
SELECT * FROM source_table;
```

## S3 Import

适用场景：从对象存储导入数据

### 配置S3

```sql
-- 创建S3访问凭证
CREATE S3 FILE (
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
) WITH BROKER broker_name;
```

### S3导入示例

```sql
-- 从S3导入CSV
LOAD LABEL example_db.s3_load_001
(
    DATA INFILE("s3://bucket/path/data.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_key",
    "AWS_SECRET_KEY" = "your_secret",
    "AWS_REGION" = "us-east-1"
);

-- 批量导入多个文件
LOAD LABEL example_db.s3_batch_load
(
    DATA INFILE("s3://bucket/path/*.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_key",
    "AWS_SECRET_KEY" = "your_secret"
);
```

## 数据导入最佳实践

### 导入参数调优

```sql
-- 调整并发度
LOAD LABEL example_db.label_001
(
    DATA INFILE("hdfs://path/data.csv")
    INTO TABLE target_table
)
WITH BROKER broker_name
PROPERTIES
(
    "timeout" = "3600",
    "max_filter_ratio" = "0.1",
    "desired_concurrent_number" = "10"
);
```

### 常见问题处理

```sql
-- 查看导入错误
SHOW LOAD WARNINGS;

-- 取消失败的导入
CANCEL LOAD example_db.label_001;

-- 重新导入
LOAD LABEL example_db.label_002
(
    DATA INFILE("hdfs://path/data.csv")
    INTO TABLE target_table
)
WITH BROKER broker_name;
```

### 导入性能优化

1. **合理设置并发度**
   - 根据集群BE数量设置并发
   - 建议desired_concurrent_number为BE数量的1-3倍

2. **批量提交**
   - 单次导入数据量建议100MB-1GB
   - 避免单次导入过大或过小

3. **数据格式优化**
   - 使用合适的列分隔符
   - 避免特殊字符
   - 压缩数据文件（gzip）

4. **监控导入进度**
```sql
SHOW LOAD WHERE LABEL = "your_label"\G
```
