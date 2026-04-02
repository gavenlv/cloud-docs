# AlloyDB 迁移指南

## 本章概述

本章详细介绍如何从自建PostgreSQL、Cloud SQL for PostgreSQL以及其他数据库迁移到AlloyDB的完整流程和最佳实践。

## 学习目标

- 掌握从PostgreSQL迁移到AlloyDB的方法
- 了解在线迁移和离线迁移的适用场景
- 学会处理兼容性问题
- 理解数据验证和回滚策略

---

## 1. 迁移策略概述

### 1.1 迁移方式对比

```
迁移方式对比

┌─────────────────────────────────────────────────────────────────────────┐
│                        迁移方式选择                                     │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      在线迁移 (Zero-Downtime)                     │   │
│  │  • 使用DMS (Database Migration Service)                         │   │
│  │  • 持续同步数据变更                                              │   │
│  │  • 切换时短暂停机 (分钟级)                                        │   │
│  │  • 适用于生产环境                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      离线迁移 (Batch)                             │   │
│  │  • 导出-导入模式                                                  │   │
│  │  • 迁移期间服务不可用                                            │   │
│  • 适用于开发/测试环境或可接受停机的场景                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 迁移流程

```powershell
# 迁移前检查清单

# 1. 评估源数据库规模
$SourceProject = "source-project"
$SourceInstance = "source-postgres"

# 查看数据库大小
gcloud sql instances describe $SourceInstance --project=$SourceProject

# 列出所有数据库
gcloud sql databases list --instance=$SourceInstance --project=$SourceProject

# 查看表结构和数据量
# (连接到数据库后执行)
# SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
# FROM information_schema.tables WHERE table_schema = 'public';
```

---

## 2. 从自建PostgreSQL迁移

### 2.1 前提条件

```powershell
# 2.1.1 启用必要API

# 启用AlloyDB API
gcloud services enable alloydb.googleapis.com

# 启用DMS API (如果使用在线迁移)
gcloud services enable datamigration.googleapis.com

# 2.1.2 配置网络

# 确保源PostgreSQL可以从GCP访问
# 如果是本地数据库，需要配置Cloud VPN或Cloud Interconnect

# 创建VPC Peering或Cloud SQL Auth Proxy
$VPC_NETWORK = "projects/$PROJECT_ID/global/networks/default"
```

### 2.2 离线迁移步骤

```powershell
# 2.2.1 准备工作

# 1. 创建AlloyDB集群
$CLUSTER_ID = "migrated-cluster"
$REGION = "us-central1"

gcloud alloydb clusters create $CLUSTER_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --network=$VPC_NETWORK `
    --recovery-window-days=7 `
    --storage-type=SSD `
    --storage-capacity=500GB

# 2. 创建实例
$INSTANCE_ID = "migrated-instance"

gcloud alloydb instances create $INSTANCE_ID `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --location=$REGION `
    --cpu-count=4 `
    --memory-size=32GB

# 3. 等待集群就绪
gcloud alloydb clusters wait $CLUSTER_ID `
    --project=$PROJECT_ID `
    --location=$REGION
```

### 2.3 导出数据

```bash
# 2.3.1 导出数据库 (源PostgreSQL)

# 导出数据库结构
pg_dump -h $SOURCE_HOST -U $SOURCE_USER -d $DATABASE_NAME `
    --schema-only `
    --file=schema.sql

# 导出数据 (并行导出大表)
pg_dump -h $SOURCE_HOST -U $SOURCE_USER -d $DATABASE_NAME `
    --data-only `
    --jobs=4 `
    --file=data.sql

# 或者导出所有 (结构+数据)
pg_dump -h $SOURCE_HOST -U $SOURCE_USER -d $DATABASE_NAME `
    --file=full_dump.sql

# 2.3.2 处理大表 (可选)

# 使用COPY导出
psql -h $SOURCE_HOST -U $SOURCE_USER -d $DATABASE_NAME -c "
COPY (SELECT * FROM large_table) TO STDOUT WITH CSV HEADER" > large_table.csv
```

### 2.4 导入数据

```powershell
# 2.4.1 获取连接信息

$CONNECTION_URI = gcloud alloydb instances describe $INSTANCE_ID `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --location=$REGION `
    --format="value(connectionInfo.uri)"

Write-Host "Connection URI: $CONNECTION_URI"

# 2.4.2 导入结构

# 导入schema到AlloyDB
psql "$CONNECTION_URI" -f schema.sql

# 2.4.3 导入数据

# 导入数据
psql "$CONNECTION_URI" -f data.sql

# 或使用并行导入
pg_restore -h $ALLOYDB_HOST -U $ALLOYDB_USER -d $DATABASE_NAME `
    --data-only `
    --jobs=4 `
    --file=full_dump.sql
```

---

## 3. 从Cloud SQL迁移

### 3.1 在线迁移 (使用DMS)

```powershell
# 3.1.1 创建连接配置文件

# 创建源连接 (Cloud SQL)
$SOURCE_CONNECTION_ID = "source-cs-sql-connection"

gcloud datamigration connection-profiles create postgresql $SOURCE_CONNECTION_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --postgresql-host=$CLOUD_SQL_HOST `
    --postgresql-port=5432 `
    --postgresql-username=$CLOUD_SQL_USER `
    --postgresql-password=$CLOUD_SQL_PASSWORD `
    --display-name="Source Cloud SQL"

# 3.1.2 创建迁移任务

$MIGRATION_JOB_ID = "migration-job-001"

gcloud datamigration migration-jobs create $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --source=$SOURCE_CONNECTION_ID `
    --destination=$CLUSTER_ID `
    --display-name="PostgreSQL to AlloyDB Migration"

# 3.1.3 启动迁移

# 启动持续同步
gcloud datamigration migration-jobs start $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION

# 3.1.4 监控迁移进度

# 查看迁移状态
gcloud datamigration migration-jobs describe $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION

# 查看复制延迟
gcloud datamigration migration-jobs describe $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --format="value(state),lastReplicatedTime"
```

### 3.2 迁移完成 - 切换

```powershell
# 3.2.1 验证数据一致性

# 在源数据库和目标数据库执行
SELECT COUNT(*), MAX(updated_at) FROM your_table;

# 3.2.2 停止应用写入

# 配置应用指向AlloyDB

# 3.2.3 完成迁移

# 切换为完全同步
gcloud datamigration migration-jobs cutover $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION

# 3.2.4 清理

# 删除迁移任务
gcloud datamigration migration-jobs delete $MIGRATION_JOB_ID `
    --project=$PROJECT_ID `
    --location=$REGION
```

---

## 4. 兼容性处理

### 4.1 PostgreSQL扩展兼容性

```sql
-- 4.1.1 AlloyDB支持的扩展

-- 查看AlloyDB支持的扩展
SELECT * FROM pg_available_extensions ORDER BY name;

-- AlloyDB支持的核心扩展：
-- • pg_stat_statements (查询统计)
-- • pg_trgm (模糊匹配)
-- • btree_gin (GIN索引)
-- • btree_gist (GiST索引)
-- • uuid-ossp (UUID生成)

-- 4.1.2 需要迁移后重新安装的扩展

-- 某些扩展可能需要重新创建
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 4.1.3 不支持的扩展

-- 以下扩展在AlloyDB中不可用：
-- • PostGIS (地理信息)
-- • pg_repack (表重组)
-- • pg_cron (定时任务) - 使用Cloud Scheduler替代
-- • pg_partman (分区管理) - 使用原生分区表替代
```

### 4.2 语法兼容性

```sql
-- 4.2.1 需要修改的语法

-- 1. 系统表查询可能需要调整
-- 某些information_schema查询可能返回不同结果

-- 2. 序列(SEQUENCE)操作
-- AlloyDB支持标准SEQUENCE操作
CREATE SEQUENCE my_sequence START 1;

-- 3. 触发器(Trigger)兼容
-- AlloyDB完全支持标准PostgreSQL触发器
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_modified
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- 4. 存储过程和函数
-- 完全兼容标准PostgreSQL存储过程
```

### 4.3 数据类型映射

```sql
-- 4.3.1 特殊数据类型处理

-- 1. JSON/JSONB - 完全兼容
CREATE TABLE events (
    event_id UUID PRIMARY KEY,
    event_data JSONB,
    metadata JSON
);

-- 2. 数组类型 - 完全兼容
CREATE TABLE tags (
    product_id UUID,
    tags TEXT[]
);

-- 3. UUID - 推荐使用
-- AlloyDB推荐使用gen_random_uuid()
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50)
);

-- 4. 大字段 (BYTEA, TEXT, JSON)
-- AlloyDB存储限制为 1GB
-- 大字段存储在列式存储中，性能更优

-- 5. 时间和时区
-- 推荐使用 TIMESTAMP WITH TIME ZONE
CREATE TABLE logs (
    log_id SERIAL,
    log_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    log_message TEXT
);
```

---

## 5. 性能验证

### 5.1 迁移后验证

```sql
-- 5.1.1 数据一致性验证

-- 1. 记录数验证
SELECT 
    'orders' as table_name,
    COUNT(*) as row_count
FROM orders
UNION ALL
SELECT 
    'order_items',
    COUNT(*)
FROM order_items
UNION ALL
SELECT 
    'products',
    COUNT(*)
FROM products;

-- 2. 数据完整性验证
SELECT COUNT(*) 
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 3. 聚合数据验证
SELECT 
    DATE(created_at) as date,
    COUNT(*) as orders,
    SUM(total_amount) as revenue
FROM orders
GROUP BY DATE(created_at)
ORDER BY date;
```

### 5.2 性能基准测试

```sql
-- 5.2.1 查询性能测试

-- 简单查询
EXPLAIN ANALYZE 
SELECT * FROM orders WHERE user_id = 'specific-user-id';

-- 复杂查询
EXPLAIN ANALYZE
SELECT 
    o.user_id,
    COUNT(*) as order_count,
    SUM(o.total_amount) as total_spent
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY o.user_id;

-- 5.2.2 写入性能测试

-- 批量写入
INSERT INTO orders (order_id, user_id, total_amount, status)
SELECT 
    gen_random_uuid(),
    gen_random_uuid(),
    (random() * 1000)::DECIMAL(10,2),
    'pending'
FROM generate_series(1, 1000);
```

---

## 6. 回滚策略

### 6.1 回滚准备

```powershell
# 6.1.1 保留源数据库

# 在迁移期间，保持源数据库运行
# 不要立即删除源Cloud SQL实例

# 6.1.2 备份AlloyDB

# 创建AlloyDB备份
$BACKUP_ID = "pre-switchover-backup"

gcloud alloydb backups create $BACKUP_ID `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --location=$REGION `
    --description="Pre-switchover backup"
```

### 6.2 回滚执行

```powershell
# 6.2.1 切回源数据库

# 1. 停止应用
# 2. 将应用连接字符串改回源数据库
# 3. 验证源数据库写入正常

# 6.2.2 数据恢复 (如果需要)

# 如果AlloyDB有新数据需要保留
# 1. 导出AlloyDB数据
pg_dump -h $ALLOYDB_HOST -U $ALLOYDB_USER -d $DATABASE_NAME `
    --data-only `
    --file=alloydb_new_data.sql

# 2. 导入回源数据库
psql -h $SOURCE_HOST -U $SOURCE_USER -d $DATABASE_NAME -f alloydb_new_data.sql
```

---

## 7. 迁移检查清单

```
迁移检查清单

┌─────────────────────────────────────────────────────────────────────────┐
│                        迁移前                                           │
│                                                                         │
│  □ 评估源数据库规模和复杂度                                              │
│  □ 选择合适的迁移方式 (在线/离线)                                        │
│  □ 配置网络连接                                                         │
│  □ 创建AlloyDB集群和实例                                                 │
│  □ 审核并修改不兼容的SQL语法                                             │
│  □ 准备回滚方案                                                         │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                        迁移中                                           │
│                                                                         │
│  □ 导出数据库结构                                                        │
│  □ 导入数据库结构到AlloyDB                                               │
│  □ 验证结构迁移完整性                                                    │
│  □ 导出数据                                                              │
│  □ 导入数据到AlloyDB                                                     │
│  □ 验证数据迁移完整性                                                    │
│  □ 执行性能基准测试                                                      │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                        迁移后                                           │
│                                                                         │
│  □ 更新应用连接字符串                                                    │
│  □ 执行最终数据一致性验证                                                 │
│  □ 监控性能和错误日志                                                    │
│  □ 配置备份策略                                                         │
│  □ 更新监控和告警                                                        │
│  □ 清理源数据库 (确认无误后)                                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

[← 返回目录](../README.md#目录)
