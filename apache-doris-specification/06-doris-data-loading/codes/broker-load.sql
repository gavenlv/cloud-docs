-- Broker Load示例

-- 创建HDFS导入任务
LOAD LABEL example_db.hdfs_load_001
(
    DATA INFILE("hdfs://namenode:9000/path/to/data.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (id, name, age, city)
    SET (
        id = id,
        name = name,
        age = age,
        city = city
    )
)
WITH BROKER broker_name
(
    "hadoop.username" = "hdfs_user",
    "hdfs confs.core.site.xml" = "/path/to/core-site.xml",
    "hdfs confs.hdfs.site.xml" = "/path/to/hdfs-site.xml"
)
PROPERTIES
(
    "timeout" = "3600",
    "max_filter_ratio" = "0.1",
    "desired_concurrent_number" = "5"
);

-- 创建多文件导入任务
LOAD LABEL example_db.multi_file_load
(
    DATA INFILE("hdfs://namenode:9000/path/file1.csv")
    INTO TABLE table1
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4),
    DATA INFILE("hdfs://namenode:9000/path/file2.csv")
    INTO TABLE table2
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4)
)
WITH BROKER broker_name;

-- 创建Parquet格式导入
LOAD LABEL example_db.parquet_load
(
    DATA INFILE("hdfs://namenode:9000/path/data.parquet")
    INTO TABLE target_table
    FORMAT AS PARQUET
    (col1, col2, col3)
)
WITH BROKER broker_name;

-- 创建ORC格式导入
LOAD LABEL example_db.orc_load
(
    DATA INFILE("hdfs://namenode:9000/path/data.orc")
    INTO TABLE target_table
    FORMAT AS ORC
    (col1, col2, col3)
)
WITH BROKER broker_name;

-- 查看导入状态
SHOW LOAD;

-- 查看特定Label的详情
SHOW LOAD WHERE LABEL = "hdfs_load_001";

-- 取消导入
CANCEL LOAD example_db.hdfs_load_001;
