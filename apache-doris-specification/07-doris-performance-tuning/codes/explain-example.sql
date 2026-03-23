-- 执行计划分析示例

-- 查看简单查询的执行计划
EXPLAIN SELECT * FROM example_db.test_table WHERE id = 1;

-- 查看带聚合的查询计划
EXPLAIN SELECT
    user_id,
    COUNT(*) as cnt,
    SUM(amount) as total
FROM example_db.order_table
GROUP BY user_id;

-- 查看JOIN查询计划
EXPLAIN SELECT
    a.user_id,
    a.username,
    b.order_id,
    b.amount
FROM example_db.user_table a
INNER JOIN example_db.order_table b ON a.user_id = b.user_id
WHERE a.status = 1;

-- 查看详细执行计划
EXPLAIN VERICAL SELECT * FROM example_db.test_table;

-- 查看分布式执行计划
EXPLAIN SELECT
    date,
    SUM(revenue) as total_revenue
FROM example_db.agg_table
GROUP BY date;

-- 分析实际执行时间
EXPLAIN ANALYZE SELECT * FROM example_db.test_table WHERE create_time > '2024-01-01';

-- 查看查询的切片信息
EXPLAIN SELECT
    a.user_id,
    COUNT(b.order_id) as order_count
FROM example_db.user_table a
LEFT JOIN example_db.order_table b ON a.user_id = b.user_id
GROUP BY a.user_id;

-- 使用Hint控制执行计划
EXPLAIN SELECT /* +broadcast*/ a.*, b.*
FROM example_db.small_table a
INNER JOIN example_db.large_table b ON a.id = b.id;

-- 查看物化视图是否能被命中
EXPLAIN SELECT date, SUM(revenue) FROM example_db.order_table GROUP BY date;
