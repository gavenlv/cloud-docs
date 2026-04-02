# AlloyDB实战场景

## 本章概述

本章介绍AlloyDB在实际生产环境中的典型应用场景，包括电商、游戏、金融等行业的具体实施方案。

## 学习目标

- 掌握 AlloyDB 在不同业务场景下的应用模式
- 学会根据场景选择合适的 AlloyDB 配置
- 理解混合工作负载的处理策略
- 了解读写分离的最佳实践

---

## 1. 电商订单系统

### 1.1 场景特点

```
电商订单系统特点

┌─────────────────────────────────────────────────────────────────────────┐
│                        电商订单系统工作负载                              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      OLTP 写入负载                               │   │
│  │  • 高并发订单创建 (10,000+ QPS 峰值)                            │   │
│  │  • 库存扣减 (分布式事务)                                        │   │
│  │  • 支付状态更新                                                 │   │
│  │  • 毫秒级延迟要求                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      OLAP 分析负载                               │   │
│  │  • 实时销售报表                                                 │   │
│  │  • 库存分析                                                     │   │
│  │  • 用户行为分析                                                 │   │
│  │  • 促销活动效果分析                                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 架构设计

```powershell
# 电商场景 AlloyDB 配置

# 创建专用集群
gcloud alloydb clusters create ecommerce-cluster `
    --project=$PROJECT_ID `
    --location=us-central1 `
    --network=projects/$PROJECT_ID/global/networks/ecommerce-vpc `
    --recovery-window-days=14 `
    --storage-type=SSD `
    --storage-capacity=500GB

# 创建高配实例（处理写入）
gcloud alloydb instances create order-instance-write `
    --project=$PROJECT_ID `
    --cluster=ecommerce-cluster `
    --location=us-central1 `
    --cpu-count=8 `
    --memory-size=64GB `
    --instance-type=PRIMARY

# 创建只读实例（处理分析查询）
gcloud alloydb instances create order-instance-read `
    --project=$PROJECT_ID `
    --cluster=ecommerce-cluster `
    --location=us-central1 `
    --cpu-count=16 `
    --memory-size=128GB `
    --instance-type=READ_POOL
```

### 1.3 订单表设计

```sql
-- 订单表设计（支持高并发写入）
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    order_number VARCHAR(32) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    shipping_address JSONB,
    billing_address JSONB,
    payment_method VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    shipped_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- 订单项目表
CREATE TABLE order_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(order_id),
    product_id UUID NOT NULL,
    product_name VARCHAR(255),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引（优化查询性能）
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- 分区表（按日期分区，支持历史数据归档）
CREATE TABLE orders_partitioned (
    LIKE orders INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 创建月度分区
CREATE TABLE orders_2024_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### 1.4 库存扣减（乐观锁）

```python
# inventory.py
"""库存扣减 - 乐观锁实现"""
import psycopg2
from psycopg2 import sql

def deduct_inventory(product_id: str, quantity: int, max_retries: int = 3):
    """
    乐观锁方式扣减库存
    
    原理：
    1. 读取当前库存和版本号
    2. 验证库存是否充足
    3. 更新时检查版本号未变
    4. 版本号+1
    """
    conn = get_connection()  # 连接到 PRIMARY 实例
    
    for attempt in range(max_retries):
        try:
            with conn.cursor() as cur:
                # 开启事务
                cur.execute("BEGIN")
                
                # 读取当前库存（带版本号）
                cur.execute("""
                    SELECT stock_quantity, version 
                    FROM products 
                    WHERE product_id = %s 
                    FOR UPDATE
                """, (product_id,))
                
                row = cur.fetchone()
                if not row:
                    raise ValueError(f"Product {product_id} not found")
                
                current_stock, version = row
                
                # 检查库存
                if current_stock < quantity:
                    raise ValueError(f"Insufficient stock: {current_stock} < {quantity}")
                
                # 更新库存（乐观锁）
                cur.execute("""
                    UPDATE products 
                    SET stock_quantity = stock_quantity - %s,
                        version = version + 1,
                        updated_at = NOW()
                    WHERE product_id = %s 
                    AND version = %s
                """, (quantity, product_id, version))
                
                if cur.rowcount == 0:
                    # 版本冲突，重试
                    conn.rollback()
                    continue
                
                # 提交事务
                conn.commit()
                return True
                
        except Exception as e:
            conn.rollback()
            if attempt == max_retries - 1:
                raise
        
    return False
```

### 1.5 读写分离配置

```python
# read replica connection
import os

# 写入连接（Primary实例）
WRITE_DSN = os.environ.get('ALLOYDB_WRITE_DSN')

# 读取连接（Read Pool实例）
READ_DSN = os.environ.get('ALLOYDB_READ_DSN')

# 读写分离路由示例
class ReadWriteRouter:
    """简单的读写分离路由"""
    
    def get_write_connection(self):
        return psycopg2.connect(WRITE_DSN)
    
    def get_read_connection(self):
        return psycopg2.connect(READ_DSN)
    
    def execute_write(self, query, params=None):
        """执行写操作"""
        with self.get_write_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.rowcount
    
    def execute_read(self, query, params=None):
        """执行读操作"""
        with self.get_read_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
    
    def execute_read_replica(self, query, params=None):
        """在只读副本上执行查询（分析场景）"""
        # 使用只读副本处理分析查询
        with self.get_read_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
```

---

## 2. 游戏后端

### 2.1 场景特点

```
游戏后端特点

┌─────────────────────────────────────────────────────────────────────────┐
│                        游戏后端工作负载                                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      实时事务负载                                 │   │
│  │  • 玩家状态更新 (位置、经验值、道具)                              │   │
│  │  • 排行榜实时更新                                                │   │
│  │  • 好友关系管理                                                  │   │
│  │  • 聊天消息存储                                                  │   │
│  │  • P99延迟 < 50ms                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      分析负载                                     │   │
│  │  • 玩家行为分析                                                  │   │
│  │  • 游戏经济平衡分析                                              │   │
│  │  • AB测试效果分析                                                │   │
│  │  • 实时大屏数据                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 架构设计

```powershell
# 游戏场景 AlloyDB 配置

# 创建低延迟专用集群
gcloud alloydb clusters create game-cluster `
    --project=$PROJECT_ID `
    --location=us-central1 `
    --network=projects/$PROJECT_ID/global/networks/game-vpc `
    --recovery-window-days=3 `
    --storage-type=SSD `
    --storage-capacity=200GB

# 创建游戏服务器实例
gcloud alloydb instances create game-instance `
    --project=$PROJECT_ID `
    --cluster=game-cluster `
    --location=us-central1 `
    --cpu-count=4 `
    --memory-size=32GB `
    --instance-type=PRIMARY

# 创建分析用只读实例
gcloud alloydb instances create game-analytics `
    --project=$PROJECT_ID `
    --cluster=game-cluster `
    --location=us-central1 `
    --cpu-count=8 `
    --memory-size=64GB `
    --instance-type=READ_POOL
```

### 2.3 玩家数据模型

```sql
-- 玩家基础信息
CREATE TABLE players (
    player_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    level INTEGER DEFAULT 1,
    experience BIGINT DEFAULT 0,
    gold INTEGER DEFAULT 0,
    diamond INTEGER DEFAULT 0,
    guild_id UUID,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 玩家道具表
CREATE TABLE player_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES players(player_id),
    item_type VARCHAR(50) NOT NULL,
    item_count INTEGER DEFAULT 1,
    equipped BOOLEAN DEFAULT FALSE,
    acquired_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 排行榜（使用物化视图优化）
CREATE MATERIALIZED VIEW player_ranking AS
SELECT 
    player_id,
    username,
    level,
    experience,
    RANK() OVER (ORDER BY experience DESC) as exp_rank,
    RANK() OVER (ORDER BY level DESC) as level_rank
FROM players;

-- 刷新排行榜（每小时或每次大规模更新后）
REFRESH MATERIALIZED VIEW CONCURRENTLY player_ranking;

-- 好友关系
CREATE TABLE friendships (
    friendship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES players(player_id),
    friend_id UUID REFERENCES players(player_id),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(player_id, friend_id)
);

-- 游戏事件日志（用于分析）
CREATE TABLE game_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES players(player_id),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 事件分区表
CREATE TABLE game_events_partitioned (
    LIKE game_events INCLUDING ALL
) PARTITION BY RANGE (created_at);
```

### 2.4 排行榜查询

```python
# leaderboard.py
"""排行榜查询优化"""

def get_top_players(limit: int = 100):
    """获取经验值排行榜前N名"""
    conn = get_read_connection()  # 使用只读副本
    
    with conn.cursor() as cur:
        # 直接查询物化视图，性能优异
        cur.execute("""
            SELECT player_id, username, level, experience, exp_rank
            FROM player_ranking
            ORDER BY exp_rank
            LIMIT %s
        """, (limit,))
        
        return cur.fetchall()


def update_player_experience(player_id: str, exp_gain: int):
    """更新玩家经验值"""
    conn = get_write_connection()
    
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE players
            SET experience = experience + %s,
                level = calculate_level(experience + %s),
                updated_at = NOW()
            WHERE player_id = %s
        """, (exp_gain, exp_gain, player_id))
        
        conn.commit()


def get_player_friends(player_id: str):
    """获取玩家好友列表"""
    conn = get_read_connection()
    
    with conn.cursor() as cur:
        cur.execute("""
            SELECT p.player_id, p.username, p.level, p.last_login_at
            FROM players p
            INNER JOIN friendships f ON p.player_id = f.friend_id
            WHERE f.player_id = %s AND f.status = 'accepted'
        """, (player_id,))
        
        return cur.fetchall()
```

---

## 3. 金融交易系统

### 3.1 场景特点

```
金融交易系统特点

┌─────────────────────────────────────────────────────────────────────────┐
│                        金融交易系统工作负载                              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      强一致性要求                                 │   │
│  │  • ACID事务支持                                                  │   │
│  │  • 串行化隔离级别                                                │   │
│  │  • 分布式锁支持                                                  │   │
│  │  • 审计日志完整                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      合规性要求                                   │   │
│  │  • 数据保留策略                                                  │   │
│  │  • 访问审计                                                      │   │
│  │  • 加密存储                                                      │   │
│  │  • 跨区域复制                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 架构设计

```powershell
# 金融场景 AlloyDB 配置（高可用+合规）

# 创建金融集群（多区域推荐）
gcloud alloydb clusters create finance-cluster `
    --project=$PROJECT_ID `
    --location=us-central1 `
    --network=projects/$PROJECT_ID/global/networks/finance-vpc `
    --recovery-window-days=30 `
    --storage-type=SSD `
    --storage-capacity=1TB `
    --enable_point_in_time_recovery=true

# 创建高可用实例
gcloud alloydb instances create finance-instance `
    --project=$PROJECT_ID `
    --cluster=finance-cluster `
    --location=us-central1 `
    --cpu-count=16 `
    --memory-size=128GB `
    --availability-type=REGIONAL  # 跨区域高可用
```

### 3.3 交易数据模型

```sql
-- 账户表
CREATE TABLE accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type VARCHAR(20) NOT NULL, -- checking, savings, investment
    balance DECIMAL(20,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 交易记录表
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_account_id UUID REFERENCES accounts(account_id),
    to_account_id UUID REFERENCES accounts(account_id),
    amount DECIMAL(20,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    transaction_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    description TEXT,
    idem_key VARCHAR(64) UNIQUE,  -- 幂等键，防止重复扣款
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 审计日志表
CREATE TABLE audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- 索引
CREATE INDEX idx_transactions_from_account ON transactions(from_account_id);
CREATE INDEX idx_transactions_to_account ON transactions(to_account_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_audit_logs_record ON audit_logs(table_name, record_id);
```

### 3.4 转账交易（两阶段提交）

```python
# transfer.py
"""安全的转账交易实现"""

def transfer_funds(from_account: str, to_account: str, amount: Decimal):
    """
    转账交易实现（两阶段提交模式）
    
    1. 验证账户状态
    2. 锁定转出账户
    3. 验证余额
    4. 扣减转出账户
    5. 增加转入账户
    6. 记录审计日志
    """
    conn = get_write_connection()
    
    try:
        with conn.cursor() as cur:
            # 设置事务隔离级别为串行化
            cur.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
            cur.execute("BEGIN")
            
            # 1. 验证转出账户状态和余额
            cur.execute("""
                SELECT balance, status 
                FROM accounts 
                WHERE account_id = %s
                FOR UPDATE
            """, (from_account,))
            
            from_acc = cur.fetchone()
            if not from_acc:
                raise ValueError("Source account not found")
            
            balance, status = from_acc
            
            if status != 'active':
                raise ValueError("Source account is not active")
            
            if balance < amount:
                raise ValueError(f"Insufficient balance: {balance} < {amount}")
            
            # 2. 验证转入账户状态
            cur.execute("""
                SELECT status FROM accounts 
                WHERE account_id = %s
                FOR UPDATE
            """, (to_account,))
            
            to_acc = cur.fetchone()
            if not to_acc or to_acc[0] != 'active':
                raise ValueError("Destination account not found or not active")
            
            # 3. 扣减转出账户
            cur.execute("""
                UPDATE accounts 
                SET balance = balance - %s,
                    updated_at = NOW()
                WHERE account_id = %s
            """, (amount, from_account))
            
            # 4. 增加转入账户
            cur.execute("""
                UPDATE accounts 
                SET balance = balance + %s,
                    updated_at = NOW()
                WHERE account_id = %s
            """, (amount, to_account))
            
            # 5. 创建交易记录
            transaction_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO transactions (
                    transaction_id, from_account_id, to_account_id,
                    amount, transaction_type, status, created_at
                )
                VALUES (%s, %s, %s, %s, 'transfer', 'completed', NOW())
            """, (transaction_id, from_account, to_account, amount))
            
            # 6. 提交事务
            cur.execute("COMMIT")
            return transaction_id
            
    except Exception as e:
        cur.execute("ROLLBACK")
        raise
```

---

## 4. 实时分析报表

### 4.1 场景特点

```
实时分析场景特点

┌─────────────────────────────────────────────────────────────────────────┐
│                        实时分析工作负载                                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      复杂查询                                     │   │
│  │  • 多表JOIN                                                      │   │
│  │  • 聚合分析 (SUM, AVG, COUNT, GROUP BY)                          │   │
│  │  • 时间序列分析                                                  │   │
│  │  • 窗口函数应用                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      列式存储优势                                 │   │
│  │  • 只读取需要的列                                                 │   │
│  │  • 高压缩率 (5-10x)                                              │   │
│  │  • 向量化计算                                                    │   │
│  │  • 分析性能提升 10-100x                                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 分析查询示例

```sql
-- 销售数据分析

-- 1. 每日销售汇总
SELECT 
    DATE(created_at) as sale_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    COUNT(DISTINCT user_id) as unique_customers
FROM orders
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY sale_date DESC;

-- 2. 产品类别销售排行
SELECT 
    p.category,
    SUM(oi.quantity) as total_quantity,
    SUM(oi.subtotal) as total_revenue,
    AVG(oi.unit_price) as avg_price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
WHERE oi.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 3. 用户购买行为分析
WITH user_purchases AS (
    SELECT 
        user_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent,
        MAX(created_at) as last_purchase
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'New Customer'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Regular'
        WHEN order_count BETWEEN 6 AND 10 THEN 'Loyal'
        ELSE 'VIP'
    END as customer_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_spent
FROM user_purchases
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN 'New Customer'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Regular'
        WHEN order_count BETWEEN 6 AND 10 THEN 'Loyal'
        ELSE 'VIP'
    END;

-- 4. 时间序列预测数据准备
SELECT 
    DATE_TRUNC('hour', created_at) as time_bucket,
    COUNT(*) as event_count
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY time_bucket;
```

### 4.3 物化视图加速查询

```sql
-- 创建预计算的物化视图
CREATE MATERIALIZED VIEW daily_sales_summary AS
SELECT 
    DATE(o.created_at) as sale_date,
    p.category,
    p.region,
    COUNT(DISTINCT o.user_id) as unique_customers,
    COUNT(*) as order_count,
    SUM(oi.quantity) as total_items,
    SUM(oi.subtotal) as total_revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY DATE(o.created_at), p.category, p.region;

-- 创建索引
CREATE UNIQUE INDEX ON daily_sales_summary(sale_date, category, region);

-- 定时刷新（每日凌晨）
-- 可以使用 Cloud Scheduler + Cloud Functions 触发
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales_summary;
```

---

## 5. 混合负载处理策略

### 5.1 工作负载分离

```
混合负载处理架构

┌─────────────────────────────────────────────────────────────────────────┐
│                        AlloyDB 读写分离架构                             │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      应用层 (Connection Pool)                    │   │
│  │                                                                  │   │
│  │   ┌─────────────────┐     ┌─────────────────┐                   │   │
│  │   │   Write Pool    │     │   Read Pool     │                   │   │
│  │   │   (Primary)     │     │   (列式存储)     │                   │   │
│  │   └────────┬────────┘     └────────┬────────┘                   │   │
│  │            │                       │                             │   │
│  │            ▼                       ▼                             │   │
│  │   ┌─────────────────────────────────────────┐                     │   │
│  │   │              AlloyDB Cluster              │                     │   │
│  │   │   Primary Node  ◄────►  Read Pool       │                     │   │
│  │   │       │                  │              │                     │   │
│  │   │       ▼                  ▼              │                     │   │
│  │   │   ┌─────────────────────────────────┐   │                     │   │
│  │   │   │      Columnar Storage           │   │                     │   │
│  │   │   │   (分析查询加速)                  │   │                     │   │
│  │   │   └─────────────────────────────────┘   │                     │   │
│  │   └─────────────────────────────────────────┘                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 路由策略配置

```python
# routing.py
"""工作负载路由配置"""

import os
from contextlib import contextmanager

class AlloyDBRouter:
    """AlloyDB 工作负载路由器"""
    
    def __init__(self):
        self.write_dsn = os.environ.get('ALLOYDB_WRITE_DSN')
        self.read_dsn = os.environ.get('ALLOYDB_READ_DSN')
        self.analytics_dsn = os.environ.get('ALLOYDB_ANALYTICS_DSN')  # 专用分析副本
    
    @contextmanager
    def write_transaction(self):
        """写事务上下文"""
        conn = psycopg2.connect(self.write_dsn)
        try:
            yield conn
        finally:
            conn.close()
    
    @contextmanager
    def read_query(self, use_analytics=False):
        """
        读查询上下文
        
        Args:
            use_analytics: 是否使用专用分析副本
        """
        dsn = self.analytics_dsn if use_analytics else self.read_dsn
        conn = psycopg2.connect(dsn)
        try:
            yield conn
        finally:
            conn.close()
    
    def is_write_query(self, query: str) -> bool:
        """判断是否为写查询"""
        write_keywords = ['INSERT', 'UPDATE', 'DELETE', 'CREATE', 'DROP', 'ALTER']
        return any(keyword in query.upper() for keyword in write_keywords)
    
    def is_analytics_query(self, query: str) -> bool:
        """判断是否为分析查询"""
        analytics_keywords = [
            'GROUP BY', 'HAVING', 'WINDOW', 
            'RANK', 'LEAD', 'LAG',
            'PERCENTILE', 'EXPLAIN'
        ]
        return any(keyword in query.upper() for keyword in analytics_keywords)


# 使用示例
router = AlloyDBRouter()

# 自动路由示例
def execute_query(query: str, params=None):
    if router.is_write_query(query):
        with router.write_transaction() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.rowcount
    elif router.is_analytics_query(query):
        with router.read_query(use_analytics=True) as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
    else:
        with router.read_query() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
```

---

[← 返回目录](../README.md#目录)
