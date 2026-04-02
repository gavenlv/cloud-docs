# AlloyDB 性能调优最佳实践

## 本章概述

本章详细介绍AlloyDB性能调优的各个方面，包括配置优化、索引策略、查询优化和监控诊断。

## 学习目标

- 掌握AlloyDB配置参数优化
- 学会索引设计和优化策略
- 理解查询优化技巧
- 掌握性能监控和诊断方法

---

## 1. 实例配置优化

### 1.1 实例规格选择指南

```
实例规格选择

┌─────────────────────────────────────────────────────────────────────────┐
│                        CPU/内存配置建议                                 │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      OLTP 场景                                   │   │
│  │  • 推荐 CPU:内存比 = 1:4 或 1:8                                 │   │
│  │  • 如: 4 CPU + 32GB 内存                                        │   │
│  │  • 适合高并发短查询                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      OLAP 场景                                   │   │
│  │  • 推荐 CPU:内存比 = 1:8 或更高                                  │   │
│  │  • 如: 8 CPU + 128GB 内存                                       │   │
│  │  • 适合复杂分析查询                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      混合负载                                    │   │
│  │  • 使用读写分离                                                  │   │
│  │  • 写节点: 4 CPU + 32GB                                         │   │
│  │  • 读节点: 8 CPU + 64GB                                         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 调整实例规格

```powershell
# 1.2.1 查看当前配置

$INSTANCE_ID = "my-alloydb-instance"
$CLUSTER_ID = "my-cluster"

# 查看实例详情
gcloud alloydb instances describe $INSTANCE_ID `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --location=$REGION

# 1.2.2 调整CPU和内存

# 扩缩容实例
gcloud alloydb instances update $INSTANCE_ID `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --location=$REGION `
    --cpu-count=8 `
    --memory-size=64GB

# 1.2.3 扩缩容存储

# 增加存储容量
gcloud alloydb clusters update $CLUSTER_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --storage-capacity=500GB
```

---

## 2. 索引优化

### 2.1 索引设计原则

```sql
-- 2.1.1 索引设计检查清单

-- 索引设计原则：
-- 1. 为WHERE子句中的列创建索引
-- 2. 为JOIN条件的列创建索引
-- 3. 为ORDER BY列创建索引
-- 4. 考虑列的选择性（高选择性更好）
-- 5. 避免过多索引（影响写入性能）

-- 2.1.2 查看查询计划

-- 分析查询性能
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE user_id = 'xxx'
AND status = 'completed'
ORDER BY created_at DESC;

-- 2.1.3 查看索引使用情况

-- 检查未使用的索引
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### 2.2 常见索引策略

```sql
-- 2.2.1 B-tree索引（默认，最常用）

-- 单列索引
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- 复合索引（列顺序很重要！）
-- 原则：等值查询列在前，范围查询列在后
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- 2.2.2 部分索引（只索引满足条件的行）

-- 只索引活跃订单
CREATE INDEX idx_active_orders ON orders(user_id, created_at)
WHERE status = 'active';

-- 只索引大额订单
CREATE INDEX idx_large_orders ON orders(total_amount)
WHERE total_amount > 10000;

-- 2.2.3 覆盖索引（包含查询所需的所有列）

-- 查询只需从索引获取数据，无需回表
CREATE INDEX idx_orders_cover ON orders(user_id)
INCLUDE (order_id, status, total_amount, created_at);

-- 2.2.4 表达式索引

-- 经常按日期查询时
CREATE INDEX idx_orders_date ON orders(DATE(created_at));

-- 2.2.5 索引维护

-- 查看索引大小
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- 重建碎片化索引
REINDEX INDEX CONCURRENTLY idx_orders_user_id;
```

### 2.3 索引案例

```sql
-- 电商订单系统索引设计

-- 1. 用户订单查询（最常见）
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- 2. 订单状态查询
CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC)
WHERE status IN ('pending', 'processing');

-- 3. 商品订单查询
CREATE INDEX idx_order_items_product ON order_items(product_id, created_at DESC);

-- 4. 复合条件查询
CREATE INDEX idx_orders_user_status ON orders(user_id, status, created_at DESC);

-- 5. 文本搜索（如果需要）
CREATE INDEX idx_products_name ON products USING gin(to_tsvector('english', name));
```

---

## 3. 查询优化

### 3.1 分析查询执行计划

```sql
-- 3.1.1 阅读执行计划

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    o.order_id,
    o.user_id,
    o.total_amount,
    COUNT(oi.item_id) as item_count
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY o.order_id, o.user_id, o.total_amount;

-- 执行计划关键指标：
-- • Seq Scan: 全表扫描（可能需要优化）
-- • Index Scan: 索引扫描（好）
-- • Bitmap Heap Scan: 位图扫描（中等）
-- • Hash Join: 哈希连接（适合大表）
-- • Nested Loop: 嵌套循环（适合小表）
```

### 3.2 常见查询优化

```sql
-- 3.2.1 避免SELECT *

-- 差: SELECT * FROM orders
-- 好: SELECT order_id, user_id, total_amount FROM orders

-- 3.2.2 使用LIMIT限制结果

-- 分页查询
SELECT order_id, user_id, total_amount, created_at
FROM orders
WHERE user_id = 'xxx'
ORDER BY created_at DESC
LIMIT 20 OFFSET 100;

-- 3.2.3 优化JOIN顺序

-- 小表驱动大表
-- PostgreSQL会自动优化，但复杂查询可能需要提示

-- 3.2.4 使用批量操作

-- 差: 循环插入
-- INSERT INTO orders VALUES (1, ...);
-- INSERT INTO orders VALUES (2, ...);

-- 好: 批量插入
INSERT INTO orders (order_id, user_id, total_amount)
VALUES
    (1, 'user1', 100.00),
    (2, 'user2', 200.00),
    (3, 'user3', 300.00);

-- 3.2.5 使用CTE简化复杂查询

WITH recent_orders AS (
    SELECT order_id, user_id, created_at
    FROM orders
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
),
order_totals AS (
    SELECT order_id, SUM(subtotal) as total
    FROM order_items
    GROUP BY order_id
)
SELECT
    r.order_id,
    r.user_id,
    t.total
FROM recent_orders r
INNER JOIN order_totals t ON r.order_id = t.order_id;
```

### 3.3 分页优化

```sql
-- 3.3.1 基于游标的分页（性能更好）

-- 使用keyset分页
SELECT *
FROM orders
WHERE created_at < '2024-01-01'
AND order_id > 'last-seen-order-id'
ORDER BY created_at DESC, order_id DESC
LIMIT 20;

-- 3.3.2 COUNT查询优化

-- 差: SELECT COUNT(*) FROM huge_table;

-- 好: 使用近似计数
SELECT reltuples::bigint AS estimate
FROM pg_class
WHERE relname = 'huge_table';

-- 或使用覆盖索引
CREATE INDEX idx_covering ON orders(user_id) INCLUDE (order_id);
SELECT COUNT(*) FROM orders WHERE user_id = 'xxx';
```

---

## 4. 连接池配置

### 4.1 PgBouncer最佳配置

```ini
; pgbouncer.ini

[databases]
mydb = host=/cloudsql/project:region:instance dbname=mydb

[pgbouncer]
listen_port = 5432
listen_addr = 0.0.0.0

; 认证
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt

; 连接池模式
; transaction: 事务级连接池（推荐）
; session: 会话级连接池
; statement: 语句级连接池
pool_mode = transaction

; 连接池大小
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 5

; 超时设置
query_timeout = 60
server_idle_timeout = 600
server_connect_timeout = 15
server_login_retry = 5

; 保留空闲连接
reserve_pool_size = 5
reserve_pool_timeout = 5

; 日志
log_connections = 0
log_disconnections = 0
log_errors = 1
```

### 4.2 应用连接池配置

```python
# application_connection_pool.py
import psycopg2
from psycopg2 import pool
import threading

class ApplicationPool:
    """应用层连接池"""
    
    def __init__(self, min_conn=5, max_conn=20):
        self.pool = pool.ThreadedConnectionPool(
            minconn=min_conn,
            maxconn=max_conn,
            host=os.environ.get('ALLOYDB_HOST'),
            port=int(os.environ.get('ALLOYDB_PORT', 5432)),
            database=os.environ.get('DB_NAME'),
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASSWORD'),
            connect_timeout=10,
            options='-c statement_timeout=30000'  # 30秒查询超时
        )
        self.lock = threading.Lock()
    
    def get_connection(self):
        """获取连接"""
        return self.pool.getconn()
    
    def return_connection(self, conn):
        """归还连接"""
        self.pool.putconn(conn)
    
    def execute_query(self, query, params=None):
        """执行查询"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
        finally:
            self.return_connection(conn)
    
    def execute_write(self, query, params=None):
        """执行写操作"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(query, params)
                conn.commit()
                return cur.rowcount
        except Exception as e:
            conn.rollback()
            raise
        finally:
            self.return_connection(conn)
```

---

## 5. 监控与诊断

### 5.1 关键性能指标

```sql
-- 5.1.1 连接状态

SELECT
    state,
    COUNT(*) as count,
    MAX(now() - state_change) as max_duration
FROM pg_stat_activity
WHERE datname = 'mydb'
GROUP BY state;

-- 5.1.2 慢查询

SELECT
    query,
    calls,
    mean_time,
    total_time,
    rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- 5.1.3 锁等待

SELECT
    l.locktype,
    l.relation::regclass,
    l.mode,
    l.granted,
    l.pid,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted;

-- 5.1.4 表膨胀

SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### 5.2 启用pg_stat_statements

```sql
-- 启用查询统计扩展
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 查看最耗时查询
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    shared_blks_hit,
    shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- 查看最频繁查询
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 20;

-- 查看I/O密集查询
SELECT
    query,
    shared_blks_read + shared_blks_hit as total_blks,
    shared_blks_read,
    shared_blks_hit
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 10;
```

### 5.3 诊断工具

```sql
-- 5.3.1 查看当前长查询

SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
AND state != 'idle'
ORDER BY duration DESC;

-- 5.3.2 取消长时间运行查询

-- 取消查询（不终止连接）
SELECT pg_cancel_backend(pid);

-- 终止连接
SELECT pg_terminate_backend(pid);

-- 5.3.3 表统计信息

-- 更新统计信息（优化器需要）
ANALYZE orders;

-- 查看表大小
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename)) as total_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename) DESC;
```

---

## 6. 存储优化

### 6.1 表设计优化

```sql
-- 6.1.1 使用合适的数据类型

-- 整数类型选择
-- • SMALLINT: -32768 to 32767 (2字节)
-- • INTEGER: -2147483648 to 2147483647 (4字节) - 常用
-- • BIGINT: 极大整数 (8字节)

-- 字符串类型
-- • VARCHAR(n): 可变长度，有长度限制
-- • TEXT: 无长度限制，性能相同

-- 6.1.2 表分区

-- 按时间分区（适合日志、订单等）
CREATE TABLE orders_partitioned (
    order_id UUID,
    user_id UUID,
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE
) PARTITION BY RANGE (created_at);

-- 创建月度分区
CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- 6.1.3 压缩表

-- 使用压缩存储
CREATE TABLE compressed_logs (
    log_id BIGSERIAL,
    log_data TEXT
) WITH (fillfactor=70, autovacuum_vacuum_threshold=1000);
```

### 6.2 VACUUM优化

```sql
-- 6.2.1 手动VACUUM

-- 回收死元组
VACUUM orders;

-- 同时更新统计信息
VACUUM ANALYZE orders;

-- 6.2.2 配置自动VACUUM

-- 在会话中设置
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.01,  -- 1%死元组触发
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_cost_delay = 10
);
```

---

## 7. 常见问题处理

### 7.1 性能问题排查流程

```
排查流程

┌─────────────────────────────────────────────────────────────────────────┐
│                        性能问题排查                                     │
│                                                                         │
│  Step 1: 确认问题范围                                                   │
│  ├─ 单个查询慢还是整体响应慢？                                           │
│  ├─ 特定时间还是持续发生？                                              │
│  └─ 特定用户/功能受影响？                                               │
│                                                                         │
│  Step 2: 检查资源使用                                                    │
│  ├─ CPU使用率                                                           │
│  ├─ 内存使用率                                                          │
│  ├─ 存储I/O                                                            │
│  └─ 连接数                                                             │
│                                                                         │
│  Step 3: 分析查询                                                        │
│  ├─ 使用EXPLAIN ANALYZE                                                │
│  ├─ 检查索引                                                            │
│  └─ 查看pg_stat_statements                                              │
│                                                                         │
│  Step 4: 检查锁等待                                                     │
│  ├─ pg_locks视图                                                        │
│  └─ pg_stat_activity                                                   │
│                                                                         │
│  Step 5: 实施优化                                                        │
│  ├─ 添加/优化索引                                                       │
│  ├─ 重写查询                                                           │
│  ├─ 调整配置参数                                                        │
│  └─ 扩容实例规格                                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 常见问题解决方案

```sql
-- 问题1: 索引未使用

-- 原因: 统计信息过时或查询写法问题
-- 解决: ANALYZE table; 或强制使用索引

SET enable_seqscan = off;  -- 临时禁用顺序扫描
SELECT * FROM orders WHERE user_id = 'xxx';

-- 问题2: 连接池耗尽

-- 原因: 长查询占用连接
-- 解决: 设置statement_timeout

SET statement_timeout = '30s';

-- 问题3: 大量死元组

-- 原因: 频繁更新/删除但VACUUM未及时运行
-- 解决: 手动执行VACUUM ANALYZE

VACUUM ANALYZE orders;

-- 问题4: 临时文件过多

-- 原因: 排序/Hash操作内存不足
-- 解决: 增加work_mem

SET work_mem = '256MB';
```

---

[← 返回目录](../README.md#目录)
