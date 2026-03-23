-- 物化视图示例

-- 创建聚合物化视图（用于加速聚合查询）
CREATE MATERIALIZED VIEW mv_monthly_revenue
AS
SELECT
    DATE_TRUNC(date, 'month') as month,
    city,
    SUM(revenue) as total_revenue,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(revenue) as avg_revenue
FROM example_db.order_table
GROUP BY DATE_TRUNC(date, 'month'), city;

-- 创建明细物化视图（用于加速JOIN查询）
CREATE MATERIALIZED VIEW mv_user_order_detail
AS
SELECT
    o.order_id,
    o.user_id,
    o.date,
    o.amount,
    u.username,
    u.email,
    u.city
FROM example_db.order_table o
INNER JOIN example_db.user_table u ON o.user_id = u.user_id;

-- 创建预计算物化视图
CREATE MATERIALIZED VIEW mv_category_stats
AS
SELECT
    category,
    DATE_TRUNC(date, 'week') as week,
    COUNT(*) as total_orders,
    SUM(amount) as total_amount
FROM example_db.order_table
GROUP BY category, DATE_TRUNC(date, 'week');

-- 创建Bloom Filter物化视图（用于加速高基列查询）
CREATE MATERIALIZED VIEW mv_user_high_cardinality
AS
SELECT
    user_id,
    email,
    phone,
    last_login
FROM example_db.user_table;

-- 查看物化视图列表
SHOW MATERIALIZED VIEW;

-- 查看物化视图创建进度
SHOW ALTER TABLE MATERIALIZED VIEW;

-- 删除物化视图
DROP MATERIALIZED VIEW mv_monthly_revenue;

-- 刷新物化视图
REFRESH MATERIALIZED VIEW mv_monthly_revenue;

-- 验证物化视图是否被命中
EXPLAIN SELECT
    DATE_TRUNC(date, 'month') as month,
    city,
    SUM(revenue) as total_revenue
FROM example_db.order_table
GROUP BY DATE_TRUNC(date, 'month'), city;
