-- 备份示例

-- 创建仓库（S3存储）
CREATE REPOSITORY s3_repo
ON LOCATION 's3://bucket/doris_backup'
PROPERTIES
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
);

-- 全量备份数据库
BACKUP DATABASE example_db
TO s3_repo
ON LOCATION 's3://bucket/doris_backup/full_backup_20240101'
PROPERTIES
(
    "timeout" = "7200",
    "compression" = "lz4"
);

-- 备份指定表
BACKUP DATABASE example_db
TO s3_repo
ON LOCATION 's3://bucket/doris_backup/table_backup_20240101'
(
    'order_table',
    'user_table'
);

-- 增量备份
BACKUP DATABASE example_db
TO s3_repo
ON LOCATION 's3://bucket/doris_backup/incremental_backup_20240102'
PROPERTIES
(
    "type" = "INCREMENTAL",
    "timeout" = "3600"
);

-- 查看备份状态
SHOW BACKUP;

-- 查看最近一次备份
SHOW BACKUP LAST 1;

-- 查看备份中的表
SHOW BACKUP ON s3_repo;

-- 取消备份
CANCEL BACKUP FROM s3_repo;

-- 删除快照
DROP SNAPSHOT s3_repo.'snapshot_name';

-- 查看可用的备份
SELECT * FROM information_schema.backup_restore;
