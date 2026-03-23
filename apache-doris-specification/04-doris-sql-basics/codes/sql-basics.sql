-- ============================================
-- Doris SQL基础示例
-- ============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS example_db;

-- 使用数据库
USE example_db;

-- 创建明细表
CREATE TABLE IF NOT EXISTS detail_table
(
    user_id LARGEINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age SMALLINT,
    status TINYINT,
    last_visit DATETIME DEFAULT CURRENT_TIMESTAMP
)
DUPLICATE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3"
);

-- 插入数据
INSERT INTO detail_table (user_id, username, email, age, status)
VALUES (1, 'user1', 'user1@example.com', 25, 1);

INSERT INTO detail_table (user_id, username, email, age, status)
VALUES (2, 'user2', 'user2@example.com', 30, 1);

-- 查询数据
SELECT * FROM detail_table;

SELECT user_id, username, email FROM detail_table WHERE age > 25;

-- 更新数据
UPDATE detail_table SET email = 'newemail@example.com' WHERE user_id = 1;

-- 删除数据
DELETE FROM detail_table WHERE user_id = 2;

-- 聚合查询
SELECT COUNT(*) as total_users,
       AVG(age) as avg_age,
       MIN(age) as min_age,
       MAX(age) as max_age
FROM detail_table;

-- 分组查询
SELECT status, COUNT(*) as cnt, AVG(age) as avg_age
FROM detail_table
GROUP BY status;

-- 排序查询
SELECT * FROM detail_table ORDER BY age DESC LIMIT 10;

-- 分页查询
SELECT * FROM detail_table ORDER BY user_id LIMIT 5 OFFSET 5;

-- JOIN查询
CREATE TABLE IF NOT EXISTS order_table
(
    order_id BIGINT NOT NULL,
    user_id LARGEINT NOT NULL,
    amount DECIMAL(15,2),
    order_date DATE
)
DUPLICATE KEY(order_id, user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;

INSERT INTO order_table VALUES (1, 1, 100.00, '2024-01-01');
INSERT INTO order_table VALUES (2, 1, 200.00, '2024-01-02');
INSERT INTO order_table VALUES (3, 2, 150.00, '2024-01-03');

SELECT d.username, o.order_id, o.amount, o.order_date
FROM detail_table d
INNER JOIN order_table o ON d.user_id = o.user_id;

-- 子查询
SELECT * FROM detail_table
WHERE user_id IN (SELECT user_id FROM order_table WHERE amount > 100);

-- 视图
CREATE VIEW user_order_summary AS
SELECT d.user_id, d.username, COUNT(o.order_id) as order_count, SUM(o.amount) as total_amount
FROM detail_table d
LEFT JOIN order_table o ON d.user_id = o.user_id
GROUP BY d.user_id, d.username;

SELECT * FROM user_order_summary;
