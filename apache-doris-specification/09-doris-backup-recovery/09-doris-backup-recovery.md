# Doris备份恢复

## 概述

本文档介绍Doris的数据备份和恢复功能，包括快照备份、远程备份和恢复操作。

## 快照备份

### 创建快照

```sql
-- 创建数据库快照
CREATE SNAPSHOT ON DATABASE database_name
FOR SNAPSHOT snapshot_name
ON backup_location;

-- 创建表快照
CREATE SNAPSHOT ON TABLE database_name.table_name
FOR SNAPSHOT snapshot_name
ON backup_location;

-- 查看快照列表
SHOW SNAPSHOT ON backup_location;

-- 查看快照详细信息
SHOW SNAPSHOT ON backup_location WHERE SNAPSHOT = 'snapshot_name';
```

### 从快照恢复

```sql
-- 恢复数据库
RESTORE DATABASE database_name
FROM SNAPSHOT snapshot_name
ON backup_location;

-- 恢复表
RESTORE TABLE database_name.table_name
FROM SNAPSHOT snapshot_name
ON backup_location;

-- 查看恢复进度
SHOW RESTORE;

-- 取消恢复
CANCEL RESTORE;
```

## 远程备份

### 配置远程存储

```sql
-- 添加S3存储
SHOW PROC '/backends';

-- 创建仓库
CREATE REPOSITORY repo_name
ON LOCATION 's3://bucket/backup'
PROPERTIES
(
    "AWS_ENDPOINT" = "s3.amazonaws.com",
    "AWS_ACCESS_KEY" = "your_access_key",
    "AWS_SECRET_KEY" = "your_secret_key",
    "AWS_REGION" = "us-east-1"
);
```

### 执行全量备份

```sql
-- 备份整个数据库
BACKUP DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/full_backup';

-- 备份指定表
BACKUP DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/table_backup'
(
    'table_name1',
    'table_name2'
);

-- 查看备份进度
SHOW BACKUP;

-- 取消备份
CANCEL BACKUP;
```

### 执行增量备份

```sql
-- 增量备份（自动检测变化）
BACKUP DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/incremental_backup'
PROPERTIES ('type' = 'INCREMENTAL');
```

### 执行恢复

```sql
-- 查看可用的备份
SHOW BACKUP;

-- 恢复整个数据库
RESTORE DATABASE database_name
FROM repo_name
ON LOCATION 's3://bucket/backup/full_backup';

-- 恢复指定表
RESTORE DATABASE database_name
FROM repo_name
ON LOCATION 's3://bucket/backup/full_backup'
(
    'table_name1',
    'table_name2'
);

-- 按备份时间恢复
RESTORE DATABASE database_name
FROM repo_name
ON LOCATION 's3://bucket/backup/full_backup'
PROPERTIES ('backup_timestamp' = '2024-01-01-10-00-00');

-- 查看恢复进度
SHOW RESTORE;

-- 取消恢复
CANCEL RESTORE;
```

## 定时备份

### 创建定时备份任务

```sql
-- 创建定时备份任务
CREATE BACKUP TASK ON DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/scheduled_backup'
PROPERTIES
(
    'schedule' = '0 2 * * *',  -- 每天凌晨2点
    'backup_type' = 'FULL',
    'retention' = '7'  -- 保留7天
);

-- 查看定时任务
SHOW BACKUP TASK;

-- 暂停定时任务
PAUSE BACKUP TASK task_name;

-- 恢复定时任务
RESUME BACKUP TASK task_name;

-- 删除定时任务
DROP BACKUP TASK task_name;
```

## 备份策略配置

### 多级备份策略

```sql
-- 每日备份（保留7天）
CREATE BACKUP TASK ON DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/daily'
PROPERTIES
(
    'schedule' = '0 2 * * *',
    'retention' = '7'
);

-- 每周备份（保留30天）
CREATE BACKUP TASK ON DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/weekly'
PROPERTIES
(
    'schedule' = '0 3 * * 0',  -- 每周日凌晨3点
    'retention' = '30'
);

-- 每月备份（保留365天）
CREATE BACKUP TASK ON DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/monthly'
PROPERTIES
(
    'schedule' = '0 4 1 * *',  -- 每月1日凌晨4点
    'retention' = '365'
);
```

### 备份压缩配置

```sql
-- 启用压缩备份
BACKUP DATABASE database_name
TO repo_name
ON LOCATION 's3://bucket/backup/compressed'
PROPERTIES
(
    'compression' = 'lz4'
);
```

## 表结构备份

### 备份表结构

```sql
-- 导出表结构
SHOW CREATE TABLE database_name.table_name;

-- 备份表结构到文件
SELECT CREATE_TABLE_STATEMENT
FROM information_schema.tables
WHERE table_schema = 'database_name' AND table_name = 'table_name';
```

### 重建表结构

```sql
-- 使用备份的建表语句重建表
CREATE TABLE IF NOT EXISTS database_name.table_name_new
(
    col1 TYPE,
    col2 TYPE
)
ENGINE=OLAP
...;
```

## 恢复场景

### 误删除表恢复

```sql
-- 步骤1：查看可用的备份
SHOW BACKUP;

-- 步骤2：从备份恢复表
RESTORE DATABASE database_name
FROM repo_name
ON LOCATION 's3://bucket/backup/full_backup'
(
    'deleted_table'
);

-- 步骤3：验证恢复的数据
SELECT COUNT(*) FROM deleted_table;
SELECT * FROM deleted_table LIMIT 10;
```

### 数据损坏恢复

```sql
-- 步骤1：创建问题表的快照
CREATE SNAPSHOT ON TABLE database_name.problematic_table
FOR SNAPSHOT 'problem_backup'
ON backup_location;

-- 步骤2：从快照恢复
RESTORE TABLE database_name.problematic_table
FROM SNAPSHOT 'problem_backup'
ON backup_location;
```

### 整库恢复

```sql
-- 恢复整个数据库到指定时间点
RESTORE DATABASE database_name
FROM repo_name
ON LOCATION 's3://bucket/backup/full_backup'
PROPERTIES
(
    'backup_timestamp' = '2024-01-01-10-00-00'
);
```

## 备份管理

### 查看备份状态

```sql
-- 查看所有备份任务
SHOW BACKUP;

-- 查看最近一次备份详情
SHOW BACKUP LAST 1;

-- 查看备份中的表
SHOW BACKUP ON repo_name;

-- 查看备份文件大小
SHOW BACKUP ON repo_name WHERE SNAPSHOT = 'snapshot_name';
```

### 清理备份

```sql
-- 删除过期的备份
DROP SNAPSHOT repo_name.'snapshot_name';

-- 删除仓库
DROP REPOSITORY repo_name;

-- 清理远程存储中的备份文件（手动）
```

### 备份监控

```sql
-- 查看备份任务统计
SELECT * FROM information_schema.backup_tasks;

-- 查看恢复任务统计
SELECT * FROM information_schema.restore_tasks;

-- 查看备份历史
SELECT * FROM information_schema.backup_history;
```

## 最佳实践

### 备份策略建议

1. **定期备份**
   - 每日增量备份
   - 每周全量备份
   - 异地存储备份

2. **验证备份**
   ```sql
   -- 定期验证备份完整性
   SHOW BACKUP ON repo_name;
   
   -- 定期测试恢复
   RESTORE DATABASE test_db
   FROM repo_name
   ON LOCATION 's3://bucket/backup/test_backup';
   ```

3. **监控备份任务**
   ```sql
   -- 设置告警（需要结合外部监控）
   SHOW BACKUP;
   SHOW RESTORE;
   ```

### 恢复时间预估

| 数据量 | 备份时间 | 恢复时间 |
|--------|----------|----------|
| 100GB | 5-10分钟 | 10-20分钟 |
| 1TB | 30-60分钟 | 1-2小时 |
| 10TB | 5-10小时 | 10-20小时 |

### 常见问题

```sql
-- Q: 备份失败？
-- A: 检查仓库配置和存储空间

-- Q: 恢复时间长？
-- A: 可以分表恢复，减少停机时间

-- Q: 备份占用空间大？
-- A: 启用压缩，使用增量备份
```
