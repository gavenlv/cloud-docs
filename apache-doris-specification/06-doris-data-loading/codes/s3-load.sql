-- S3 Import示例

-- 创建S3仓库（如果不存在）
-- 需要先在FE配置S3访问凭证

-- 从S3导入CSV文件
LOAD LABEL example_db.s3_load_001
(
    DATA INFILE("s3://bucket/path/data.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
)
PROPERTIES
(
    "timeout" = "3600",
    "max_filter_ratio" = "0.1"
);

-- 导入压缩CSV文件
LOAD LABEL example_db.s3_gzip_load
(
    DATA INFILE("s3://bucket/path/data.csv.gz")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
)
PROPERTIES
(
    "compress_type" = "gz"
);

-- 导入Parquet文件
LOAD LABEL example_db.s3_parquet_load
(
    DATA INFILE("s3://bucket/path/data.parquet")
    INTO TABLE target_table
    FORMAT AS PARQUET
    (col1, col2, col3)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
);

-- 批量导入多个文件
LOAD LABEL example_db.s3_batch_load
(
    DATA INFILE("s3://bucket/path/*.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4)
)
WITH S3
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key"
);

-- MinIO导入示例
LOAD LABEL example_db.minio_load
(
    DATA INFILE("http://minio:9000/bucket/path/data.csv")
    INTO TABLE target_table
    COLUMNS TERMINATED BY ","
    (col1, col2, col3, col4)
)
WITH S3
(
    "AWS_ENDPOINT" = "http://minio:9000",
    "AWS_ACCESS_KEY" = "minioadmin",
    "AWS_SECRET_KEY" = "minioadmin",
    "AWS_REGION" = "us-east-1"
);

-- 查看导入状态
SHOW LOAD WHERE LABEL = "s3_load_001";

-- 取消导入
CANCEL LOAD example_db.s3_load_001;
