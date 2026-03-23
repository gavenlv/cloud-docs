-- Unique模型表示例
-- 适用场景：实时数据更新、主数据管理

CREATE TABLE IF NOT EXISTS example_db.user_table
(
    user_id     BIGINT      NOT NULL,
    username    VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    age         INT,
    status      TINYINT     DEFAULT '1',
    last_login  DATETIME,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP
)
UNIQUE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "3",
    "enable_unique_key_merge_on_write" = "true"
);

-- 插入初始数据
INSERT INTO user_table VALUES
(1, 'user1', 'user1@example.com', '13800138000', 25, 1, '2024-01-01 10:00:00'),
(2, 'user2', 'user2@example.com', '13800138001', 30, 1, '2024-01-01 10:00:00');

-- 更新数据（自动替换）
INSERT INTO user_table VALUES
(1, 'user1', 'newemail@example.com', '13800138000', 26, 1, '2024-01-02 10:00:00');

-- 查询（返回最新数据）
SELECT * FROM user_table;

-- 按状态统计
SELECT status, COUNT(*) as count
FROM user_table
GROUP BY status;
