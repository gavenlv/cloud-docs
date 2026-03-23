-- 恢复示例

-- 查看可用的备份
SHOW BACKUP;

-- 恢复整个数据库
RESTORE DATABASE example_db
FROM s3_repo
ON LOCATION 's3://bucket/doris_backup/full_backup_20240101'
PROPERTIES
(
    "timeout" = "7200"
);

-- 恢复指定表
RESTORE DATABASE example_db
FROM s3_repo
ON LOCATION 's3://bucket/doris_backup/table_backup_20240101'
(
    'order_table',
    'user_table'
);

-- 按时间点恢复
RESTORE DATABASE example_db
FROM s3_repo
ON LOCATION 's3://bucket/doris_backup/full_backup_20240101'
PROPERTIES
(
    "backup_timestamp" = "2024-01-01-10-00-00",
    "timeout" = "7200"
);

-- 创建测试数据库并恢复
CREATE DATABASE test_restore;
RESTORE DATABASE test_restore
FROM s3_repo
ON LOCATION 's3://bucket/doris_backup/full_backup_20240101'
(
    'order_table'
);

-- 查看恢复进度
SHOW RESTORE;

-- 取消恢复
CANCEL RESTORE FROM s3_repo;

-- 恢复完成后验证数据
SELECT COUNT(*) FROM example_db.order_table;
SELECT * FROM example_db.order_table LIMIT 10;

-- 从快照恢复
CREATE SNAPSHOT ON DATABASE example_db
FOR SNAPSHOT 'pre_fix_backup'
ON backup_location;

RESTORE DATABASE example_db
FROM SNAPSHOT 'pre_fix_backup'
ON backup_location;
