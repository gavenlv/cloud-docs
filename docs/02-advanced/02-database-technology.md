# 数据库技术

## 本章概述

数据库是应用系统的核心组件。本章将系统介绍关系型数据库和NoSQL数据库的技术原理与实践。

## 学习目标

- 掌握SQL语言高级特性
- 理解数据库设计原则
- 掌握索引优化技术
- 理解事务与隔离级别
- 掌握主从复制与读写分离
- 了解各类NoSQL数据库

---

## 1. SQL语言精通

### 1.1 查询优化

```sql
-- 使用EXPLAIN分析查询计划
EXPLAIN SELECT * FROM orders WHERE customer_id = 100;

-- 避免SELECT *
SELECT id, name, email FROM users WHERE status = 'active';

-- 使用索引覆盖
CREATE INDEX idx_user_status_email ON users(status, email);

-- 分页优化
SELECT * FROM orders 
WHERE id > 1000 
ORDER BY id 
LIMIT 20;

-- JOIN优化
SELECT o.id, o.total, c.name
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
WHERE o.created_at > '2024-01-01';

-- 子查询 vs JOIN
SELECT * FROM orders 
WHERE customer_id IN (SELECT id FROM customers WHERE status = 'vip');

SELECT o.* FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
WHERE c.status = 'vip';
```

### 1.2 高级SQL特性

```sql
-- 窗口函数
SELECT 
    id,
    name,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num,
    SUM(salary) OVER (PARTITION BY department) as dept_total,
    AVG(salary) OVER (PARTITION BY department) as dept_avg
FROM employees;

-- CTE (Common Table Expression)
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(total) as total_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
),
running_total AS (
    SELECT 
        month,
        total_sales,
        SUM(total_sales) OVER (ORDER BY month) as cumulative
    FROM monthly_sales
)
SELECT * FROM running_total;

-- 递归CTE
WITH RECURSIVE org_hierarchy AS (
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.id, e.name, e.manager_id, h.level + 1
    FROM employees e
    INNER JOIN org_hierarchy h ON e.manager_id = h.id
)
SELECT * FROM org_hierarchy;

-- JSON操作
SELECT 
    id,
    data->>'name' as name,
    data->'address'->>'city' as city,
    jsonb_array_length(data->'items') as item_count
FROM orders
WHERE data @> '{"status": "completed"}';
```

### 1.3 存储过程与触发器

```sql
-- 存储过程
DELIMITER //
CREATE PROCEDURE GetCustomerOrders(
    IN p_customer_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        o.id,
        o.order_date,
        o.total,
        COUNT(oi.id) as item_count
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE o.customer_id = p_customer_id
      AND o.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY o.id, o.order_date, o.total
    ORDER BY o.order_date DESC;
END //
DELIMITER ;

-- 触发器
DELIMITER //
CREATE TRIGGER update_inventory
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE id = NEW.product_id;
END //
DELIMITER ;
```

---

## 2. 数据库设计

### 2.1 范式理论

```
数据库范式

第一范式（1NF）
├── 每列都是原子的
└── 无重复的列

第二范式（2NF）
├── 满足1NF
└── 非主键列完全依赖主键

第三范式（3NF）
├── 满足2NF
└── 非主键列不传递依赖主键

BCNF（Boyce-Codd范式）
├── 满足3NF
└── 主属性不依赖于非主属性

反范式化
├── 适当冗余提高查询性能
└── 需要在规范化和性能间平衡
```

### 2.2 设计示例

```
电商系统数据库设计

┌─────────────┐       ┌─────────────┐
│  customers  │       │  products   │
├─────────────┤       ├─────────────┤
│ id (PK)     │       │ id (PK)     │
│ name        │       │ name        │
│ email       │       │ price       │
│ phone       │       │ stock       │
│ address     │       │ category_id │
└─────────────┘       └──────┬──────┘
      │                      │
      │                      │
      ▼                      ▼
┌─────────────┐       ┌─────────────┐
│   orders    │       │ categories  │
├─────────────┤       ├─────────────┤
│ id (PK)     │       │ id (PK)     │
│ customer_id │       │ name        │
│ order_date  │       │ parent_id   │
│ status      │       └─────────────┘
│ total       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ order_items │
├─────────────┤
│ id (PK)     │
│ order_id    │
│ product_id  │
│ quantity    │
│ price       │
└─────────────┘
```

### 2.3 索引设计

```sql
-- 主键索引
ALTER TABLE users ADD PRIMARY KEY (id);

-- 唯一索引
CREATE UNIQUE INDEX idx_user_email ON users(email);

-- 普通索引
CREATE INDEX idx_user_status ON users(status);

-- 复合索引（最左前缀原则）
CREATE INDEX idx_order_customer_date ON orders(customer_id, order_date);

-- 覆盖索引
CREATE INDEX idx_user_status_name_email ON users(status, name, email);

-- 全文索引
CREATE FULLTEXT INDEX idx_product_name_desc ON products(name, description);

-- 部分索引
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active';

-- 函数索引
CREATE INDEX idx_lower_email ON users(LOWER(email));
```

**索引选择原则**：

| 场景 | 推荐索引类型 |
|-----|-------------|
| 主键查询 | 主键索引 |
| 唯一约束 | 唯一索引 |
| 范围查询 | B-Tree索引 |
| 精确匹配 | Hash索引 |
| 文本搜索 | 全文索引 |
| 多列查询 | 复合索引 |

---

## 3. 事务与隔离级别

### 3.1 ACID特性

```
ACID特性

Atomicity（原子性）
├── 事务是不可分割的工作单位
└── 要么全部完成，要么全部回滚

Consistency（一致性）
├── 事务使数据库从一个一致性状态变到另一个
└── 满足所有预定义的规则

Isolation（隔离性）
├── 多个事务并发执行时互不干扰
└── 需要设置合适的隔离级别

Durability（持久性）
├── 事务完成后对数据的修改是永久的
└── 即使系统故障也不会丢失
```

### 3.2 隔离级别

```sql
-- 查看当前隔离级别
SELECT @@transaction_isolation;

-- 设置隔离级别
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

```
隔离级别与问题

┌─────────────────┬────────┬────────┬────────┐
│    隔离级别      │ 脏读   │ 不可重复读 │ 幻读  │
├─────────────────┼────────┼────────┼────────┤
│ Read Uncommitted│   ✓    │    ✓    │   ✓   │
│ Read Committed  │   ✗    │    ✓    │   ✓   │
│ Repeatable Read │   ✗    │    ✗    │   ✓   │
│ Serializable    │   ✗    │    ✗    │   ✗   │
└─────────────────┴────────┴────────┴────────┘

✓ = 可能发生
✗ = 不会发生
```

### 3.3 并发问题示例

```sql
-- 脏读示例
-- 事务1
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- 未提交

-- 事务2（Read Uncommitted）
BEGIN;
SELECT balance FROM accounts WHERE id = 1;  -- 读到未提交的数据
COMMIT;

-- 事务1
ROLLBACK;  -- 数据回滚，事务2读到的是脏数据

-- 不可重复读示例
-- 事务1
BEGIN;
SELECT balance FROM accounts WHERE id = 1;  -- 返回1000

-- 事务2
BEGIN;
UPDATE accounts SET balance = 900 WHERE id = 1;
COMMIT;

-- 事务1
SELECT balance FROM accounts WHERE id = 1;  -- 返回900，两次读取不一致
COMMIT;

-- 幻读示例
-- 事务1
BEGIN;
SELECT COUNT(*) FROM orders WHERE customer_id = 1;  -- 返回5

-- 事务2
BEGIN;
INSERT INTO orders (customer_id, total) VALUES (1, 100);
COMMIT;

-- 事务1
SELECT COUNT(*) FROM orders WHERE customer_id = 1;  -- 返回6
COMMIT;
```

---

## 4. 主从复制与读写分离

### 4.1 复制架构

```
主从复制架构

┌─────────────────────────────────────────────────────┐
│                     Master                           │
│  ┌─────────────────────────────────────────────┐   │
│  │  写操作 → Binlog                              │   │
│  └─────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
           ▼            ▼            ▼
    ┌───────────┐ ┌───────────┐ ┌───────────┐
    │  Slave 1  │ │  Slave 2  │ │  Slave 3  │
    │  读操作   │ │  读操作   │ │  读操作   │
    └───────────┘ └───────────┘ └───────────┘

复制流程：
1. Master写入Binlog
2. Slave的IO线程读取Binlog
3. 写入Slave的Relay Log
4. Slave的SQL线程执行Relay Log
```

### 4.2 配置主从复制

**Master配置**：
```ini
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
gtid-mode = ON
enforce-gtid-consistency = ON
```

**Slave配置**：
```ini
[mysqld]
server-id = 2
relay-log = mysql-relay-bin
read-only = ON
```

**设置复制**：
```sql
-- Master创建复制用户
CREATE USER 'repl'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Slave配置复制
CHANGE MASTER TO
    MASTER_HOST = 'master-ip',
    MASTER_USER = 'repl',
    MASTER_PASSWORD = 'password',
    MASTER_AUTO_POSITION = 1;

START SLAVE;
```

### 4.3 读写分离实现

```python
import pymysql
from pymysql.cursors import DictCursor

class DatabaseRouter:
    def __init__(self):
        self.master = {
            'host': 'master.db.example.com',
            'user': 'app',
            'password': 'password',
            'database': 'app_db'
        }
        self.slaves = [
            {'host': 'slave1.db.example.com', 'user': 'app', 'password': 'password', 'database': 'app_db'},
            {'host': 'slave2.db.example.com', 'user': 'app', 'password': 'password', 'database': 'app_db'},
        ]
        self.slave_index = 0
    
    def get_master_connection(self):
        return pymysql.connect(**self.master, cursorclass=DictCursor)
    
    def get_slave_connection(self):
        conn = pymysql.connect(**self.slaves[self.slave_index], cursorclass=DictCursor)
        self.slave_index = (self.slave_index + 1) % len(self.slaves)
        return conn
    
    def execute_write(self, sql, params=None):
        with self.get_master_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql, params)
                conn.commit()
                return cursor.lastrowid
    
    def execute_read(self, sql, params=None):
        with self.get_slave_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql, params)
                return cursor.fetchall()

router = DatabaseRouter()

users = router.execute_read("SELECT * FROM users WHERE status = %s", ('active',))
router.execute_write("INSERT INTO logs (message) VALUES (%s)", ('User login',))
```

---

## 5. NoSQL数据库

### 5.1 NoSQL类型对比

```
NoSQL数据库分类

键值存储（Key-Value）
├── Redis
├── DynamoDB
├── etcd
└── 特点：高性能、简单操作

文档存储（Document）
├── MongoDB
├── CouchDB
├── DynamoDB
└── 特点：灵活schema、嵌套数据

列式存储（Column-Family）
├── Cassandra
├── HBase
├── Bigtable
└── 特点：高写入、分布式

图数据库（Graph）
├── Neo4j
├── Neptune
├── JanusGraph
└── 特点：关系查询优化
```

### 5.2 Redis实践

```bash
# 基本操作
SET user:1:name "John"
GET user:1:name

# 哈希
HSET user:1 name "John" email "john@example.com"
HGET user:1 name
HGETALL user:1

# 列表
LPUSH queue:tasks "task1"
RPOP queue:tasks

# 集合
SADD tags:article:1 "redis" "database" "nosql"
SMEMBERS tags:article:1

# 有序集合
ZADD leaderboard 100 "player1" 200 "player2"
ZREVRANGE leaderboard 0 9 WITHSCORES

# 过期时间
SET session:abc123 "user_data" EX 3600

# 发布订阅
SUBSCRIBE channel:notifications
PUBLISH channel:notifications "New message"
```

**Redis应用场景**：

| 场景 | 数据结构 | 示例 |
|-----|---------|------|
| 缓存 | String | 用户会话、API响应 |
| 计数器 | String | 点赞数、访问量 |
| 排行榜 | Sorted Set | 游戏积分榜 |
| 消息队列 | List | 任务队列 |
| 社交关系 | Set | 关注、粉丝 |
| 分布式锁 | String + Lua | 库存扣减 |

### 5.3 MongoDB实践

```javascript
// 插入文档
db.users.insertOne({
    name: "John",
    email: "john@example.com",
    age: 30,
    address: {
        city: "Beijing",
        country: "China"
    },
    tags: ["developer", "mongodb"]
});

// 批量插入
db.users.insertMany([
    {name: "Alice", age: 25},
    {name: "Bob", age: 35}
]);

// 查询
db.users.find({age: {$gt: 25}})
db.users.find({tags: "developer"})
db.users.find({"address.city": "Beijing"})

// 更新
db.users.updateOne(
    {name: "John"},
    {$set: {age: 31}, $push: {tags: "expert"}}
);

// 聚合
db.orders.aggregate([
    {$match: {status: "completed"}},
    {$group: {
        _id: "$customer_id",
        total: {$sum: "$amount"},
        count: {$sum: 1}
    }},
    {$sort: {total: -1}},
    {$limit: 10}
]);

// 创建索引
db.users.createIndex({email: 1}, {unique: true})
db.users.createIndex({name: 1, age: -1})
db.users.createIndex({"address.city": 1})
```

### 5.4 数据库选型

```
数据库选型决策树

是否需要ACID事务？
├── 是 → 关系型数据库
│        ├── MySQL/MariaDB
│        ├── PostgreSQL
│        └── 云数据库（RDS/Aurora）
│
└── 否 → 数据模型是什么？
         ├── 简单键值 → Redis/DynamoDB
         ├── 文档数据 → MongoDB
         ├── 时序数据 → InfluxDB/TimescaleDB
         ├── 图关系 → Neo4j
         └── 大规模写入 → Cassandra
```

---

## 6. 实操项目

### 项目：构建高可用数据库架构

**架构设计**：
```
┌─────────────────────────────────────────────────────────────┐
│                        应用层                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              数据库路由层                             │   │
│  │         (读写分离 + 分库分表)                         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   Master      │  │   Master      │  │   Master      │
│  (用户库)      │  │  (订单库)      │  │  (商品库)      │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
   ┌────┴────┐        ┌────┴────┐        ┌────┴────┐
   ▼         ▼        ▼         ▼        ▼         ▼
┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
│ S1  │  │ S2  │  │ S1  │  │ S2  │  │ S1  │  │ S2  │
└─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘

缓存层
┌─────────────────────────────────────────────────────────────┐
│                    Redis Cluster                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │ Master1 │  │ Master2 │  │ Master3 │                    │
│  └────┬────┘  └────┬────┘  └────┬────┘                    │
│       │            │            │                          │
│  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐                    │
│  │ Slave1  │  │ Slave2  │  │ Slave3  │                    │
│  └─────────┘  └─────────┘  └─────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 知识检测

### 选择题

1. 哪种隔离级别可以防止幻读？
   - A. Read Uncommitted
   - B. Read Committed
   - C. Repeatable Read
   - D. Serializable

2. 以下哪个不是NoSQL数据库？
   - A. MongoDB
   - B. PostgreSQL
   - C. Redis
   - D. Cassandra

3. 复合索引(a, b, c)可以优化哪个查询？
   - A. WHERE b = 1
   - B. WHERE a = 1 AND c = 1
   - C. WHERE a = 1 AND b = 1
   - D. WHERE c = 1

---

## 8. 扩展阅读

- [高性能MySQL](https://book.douban.com/subject/23008813/)
- [Redis设计与实现](https://book.douban.com/subject/25900156/)
- [MongoDB权威指南](https://book.douban.com/subject/25798102/)

---

## 学习进度

- [ ] 掌握SQL高级特性
- [ ] 理解数据库设计原则
- [ ] 掌握索引优化
- [ ] 理解事务隔离级别
- [ ] 掌握主从复制配置
- [ ] 了解NoSQL数据库
- [ ] 完成实操项目
