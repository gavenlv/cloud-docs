# GCP数据服务

## 本章概述

GCP提供强大的数据存储与分析服务，包括结构化数据、半结构化数据和非结构化数据处理。本章深入讲解BigQuery数据仓库、Cloud SQL关系型数据库和Firestore NoSQL数据库的原理、适用场景和实战操作。

## 学习目标

- 掌握BigQuery数据仓库原理和SQL操作
- 深入理解Cloud SQL数据库管理和高可用配置
- 掌握Firestore NoSQL数据库设计和查询
- 理解不同数据存储方案的选型原则
- 掌握Windows环境下的数据服务操作

---

## 1. 深入理解数据服务架构

### 1.1 为什么需要多种数据存储服务？

**数据的多样性决定了存储方案的多样性**

```
数据类型与存储服务匹配

┌─────────────────────────────────────────────────────────────────────────┐
│                        数据类型与服务匹配矩阵                             │
│                                                                         │
│  数据类型              特征                   推荐服务                  │
│  ────────────────────────────────────────────────────────────────────   │
│                                                                         │
│  结构化数据           固定Schema             Cloud SQL                 │
│  │                  强事务需求             PostgreSQL/MySQL           │
│  │                  ACID支持                                        │
│  │                                                                  │
│  半结构化数据         灵活Schema             Firestore                 │
│  │                  文档/JSON               Real-time同步             │
│  │                  移动端/IoT                                      │
│  │                                                                  │
│  大规模分析数据       PB级数据               BigQuery                  │
│  │                  复杂查询               实时分析                  │
│  │                  机器学习                                        │
│  │                                                                  │
│  文件/对象数据        二进制文件             Cloud Storage             │
│  │                  图片/视频              CDN加速                  │
│  │                  备份/归档                                      │
│  │                                                                  │
│  时序数据             高写入吞吐             Bigtable                  │
│  │                  实时分析               IoT/金融                  │
│  │                                                                  │
│  全球分布数据         全球强一致性           Cloud Spanner             │
│                      水平扩展               金融/游戏                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. BigQuery数据仓库 - 原理与实战

### 2.1 BigQuery核心概念

**为什么BigQuery能处理PB级数据？**

传统数据库是"行式存储"，而BigQuery是"列式存储"：

```
行式存储 vs 列式存储

假设有1亿条用户数据，每条包含：id, name, email, age, city, created_at

┌─────────────────────────────────────────────────────────────────────────┐
│                      行式存储（传统数据库）                              │
│                                                                         │
│  存储方式：                                                            │
│  ┌─────┬─────────┬─────────────────┬──────┬─────────┬────────────┐   │
│  │  1  │  Alice  │ alice@email.com │  25  │  NYC   │ 2024-01-01 │   │
│  ├─────┼─────────┼─────────────────┼──────┼─────────┼────────────┤   │
│  │  2  │   Bob   │  bob@email.com  │  30  │  LA    │ 2024-01-02 │   │
│  └─────┴─────────┴─────────────────┴──────┴─────────┴────────────┘   │
│                                                                         │
│  查询 "所有城市的平均年龄" 需要：                                        │
│  1. 读取每一行的city列                                                 │
│  2. 读取每一行的age列                                                  │
│  3. 遍历全部数据                                                       │
│                                                                         │
│  问题：读取了不需要的列，IO效率低                                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      列式存储（BigQuery）                               │
│                                                                         │
│  存储方式：                                                            │
│  ┌─────┬─────┬─────┬─────┬─────┐                                       │
│  │  1  │  2  │  3  │ ... │ 1亿 │  ← ID列                              │
│  ├─────┼─────┼─────┼─────┼─────┤                                       │
│  │Alice│ Bob │ ... │     │     │  ← Name列                           │
│  ├─────┼─────┼─────┼─────┼─────┤                                       │
│  │  25 │  30 │ ... │     │     │  ← Age列（只需读取这列！）          │
│  ├─────┼─────┼─────┼─────┼─────┤                                       │
│  │ NYC │  LA │ ... │     │     │  ← City列                          │
│  └─────┴─────┴─────┴─────┴─────┘                                       │
│                                                                         │
│  查询 "所有城市的平均年龄" 需要：                                        │
│  1. 只读取age列                                                        │
│  2. 只读取city列                                                       │
│  3. 内存中聚合                                                         │
│                                                                         │
│  优势：只读取需要的列，压缩率高（同类数据），适合分析查询                  │
└─────────────────────────────────────────────────────────────────────────┘
```

**BigQuery的其他核心技术：**

```
BigQuery架构解析

┌─────────────────────────────────────────────────────────────────────────┐
│                        BigQuery架构                                     │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      查询层 (Query Layer)                        │   │
│  │                                                                  │   │
│  │  Dremel ─── 分布式SQL查询引擎                                    │   │
│  │   ├── 将SQL转换为执行计划                                        │   │
│  │   ├── 调度数千个worker并行执行                                   │   │
│  │   └── 支持PB级数据秒级返回                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      存储层 (Storage Layer)                      │   │
│  │                                                                  │   │
│  │  Capacitor ─── 列式存储格式                                      │   │
│  │   ├── 自动压缩（通常3-10倍）                                     │   │
│  │   ├── 按列存储和读取                                            │   │
│  │   └── 列元数据统计（快速过滤）                                   │   │
│  │                                                                  │   │
│  │  数据分布在全球多个节点                                          │   │
│  │  自动复制和容错                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      隔离层 (Isolation)                          │   │
│  │                                                                  │   │
│  │  项目(Project) ── 计费和权限边界                                │   │
│  │   └── 数据集(Dataset) ── 表和视图的容器                         │   │
│  │       └── 表(Table) ── 数据                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 BigQuery操作 - Windows PowerShell

```powershell
# ============================================================
# BigQuery操作 - Windows PowerShell
# ============================================================

# ========== 1. 准备工作 ==========

# BigQuery API需要手动启用
gcloud services enable bigquery.googleapis.com

# 验证启用
gcloud services list --enabled | Select-String "bigquery"

# ========== 2. 创建数据集 ==========

# 数据集 = 表的容器（类似数据库）
bq mk my_dataset

# 创建带选项的数据集
bq mk --location=US my_dataset

# 查看数据集
bq ls

# ========== 3. 创建表 ==========

# 方法1：从CSV文件创建
bq load my_dataset.users gs://bucket/users.csv name:string,age:integer,city:string

# 方法2：从JSON创建
bq load my_dataset.users_json gs://bucket/users.json ./schema.json

# 方法3：创建空表并指定Schema
bq mk --schema=name:string,age:integer,city:string,created_at:timestamp my_dataset.users

# ========== 4. 查询数据 ==========

# 查询示例
bq query --use_legacy_sql=false "
SELECT 
    city,
    COUNT(*) as user_count,
    AVG(age) as avg_age
FROM my_dataset.users
GROUP BY city
ORDER BY user_count DESC
LIMIT 10
"

# 参数化查询
bq query --use_legacy_sql=false --params='{"min_age": 25}' "
SELECT * FROM my_dataset.users
WHERE age >= @min_age
"

# ========== 5. 管理表 ==========

# 查看表
bq ls my_dataset

# 查看表Schema
bq show my_dataset.users

# 复制表
bq cp my_dataset.users my_dataset.users_backup

# 删除表
bq rm -f my_dataset.users

# ========== 6. 高级特性 ==========

# 创建分区表（提高查询性能）
bq mk --table --schema=name:string,timestamp:timestamp,data:string \
    --time_partitioning_type=DAY \
    my_dataset.partitioned_table

# 创建聚簇表（按列排序存储）
bq mk --table --schema=name:string,city:string,age:integer \
    --clustering_fields=city,age \
    my_dataset.clustered_table

# 创建视图
bq mk --view='SELECT * FROM my_dataset.users WHERE age > 18' my_dataset.adult_users_view

# 创建 materialized view（物化视图）
bq query --use_legacy_sql=false "
CREATE MATERIALIZED VIEW my_dataset.mv_daily_users
OPTIONS (
    enable_refresh = true,
    refresh_interval_minutes = 60
) AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) as user_count
FROM my_dataset.users
GROUP BY DATE(created_at)
"
```

### 2.3 BigQuery Python SDK

```python
# bigquery_demo.py
"""
BigQuery Python SDK示例
展示如何用Python操作BigQuery
"""

from google.cloud import bigquery
import pandas as pd
from datetime import datetime

# ============================================================
# 原理说明：
# BigQuery客户端自动处理：
# 1. 凭证管理（通过Application Default Credentials）
# 2. 连接池和重试逻辑
# 3. 大型查询的分页处理
# 4. 数据类型转换
# ============================================================

# 创建客户端
client = bigquery.Client()

# 指定项目和数据集
PROJECT_ID = "your-project-id"
DATASET_ID = "my_dataset"
TABLE_ID = "users"


def create_dataset():
    """创建数据集"""
    print("\n" + "="*50)
    print("创建数据集")
    print("="*50)
    
    dataset_id = f"{PROJECT_ID}.{DATASET_ID}"
    
    try:
        client.get_dataset(dataset_id)
        print(f"数据集 {dataset_id} 已存在")
    except Exception:
        dataset = bigquery.Dataset(dataset_id)
        dataset.location = "US"
        dataset = client.create_dataset(dataset)
        print(f"✓ 数据集 {dataset_id} 创建成功")


def create_table():
    """创建表"""
    print("\n" + "="*50)
    print("创建用户表")
    print("="*50)
    
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    
    schema = [
        bigquery.SchemaField("user_id", "INTEGER", mode="REQUIRED"),
        bigquery.SchemaField("name", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("email", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("age", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("city", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("signup_date", "DATE", mode="NULLABLE"),
    ]
    
    table = bigquery.Table(table_id, schema=schema)
    table = client.create_table(table)
    print(f"✓ 表 {table_id} 创建成功")


def insert_data():
    """插入数据"""
    print("\n" + "="*50)
    print("插入测试数据")
    print("="*50)
    
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    
    rows_to_insert = [
        {
            "user_id": 1,
            "name": "Alice",
            "email": "alice@example.com",
            "age": 28,
            "city": "New York",
            "signup_date": "2024-01-15",
        },
        {
            "user_id": 2,
            "name": "Bob",
            "email": "bob@example.com",
            "age": 35,
            "city": "Los Angeles",
            "signup_date": "2024-02-01",
        },
        {
            "user_id": 3,
            "name": "Charlie",
            "email": "charlie@example.com",
            "age": 22,
            "city": "Chicago",
            "signup_date": "2024-03-10",
        },
    ]
    
    errors = client.insert_rows_json(table_id, rows_to_insert)
    
    if errors == []:
        print("✓ 成功插入3条数据")
    else:
        print(f"✗ 插入失败: {errors}")


def query_data():
    """查询数据"""
    print("\n" + "="*50)
    print("查询数据")
    print("="*50)
    
    query = f"""
        SELECT 
            city,
            COUNT(*) as user_count,
            ROUND(AVG(age), 1) as avg_age,
            MIN(age) as min_age,
            MAX(age) as max_age
        FROM `{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}`
        WHERE age IS NOT NULL
        GROUP BY city
        ORDER BY user_count DESC
    """
    
    # 执行查询
    query_job = client.query(query)
    
    # 等待结果
    results = query_job.result()
    
    print("\n城市用户统计：")
    print("-" * 60)
    print(f"{'城市':<15} {'用户数':<10} {'平均年龄':<10} {'最小':<8} {'最大':<8}")
    print("-" * 60)
    
    for row in results:
        print(f"{row.city:<15} {row.user_count:<10} {row.avg_age:<10} {row.min_age:<8} {row.max_age:<8}")


def query_to_dataframe():
    """查询并转换为DataFrame"""
    print("\n" + "="*50)
    print("查询并转换为Pandas DataFrame")
    print("="*50)
    
    query = f"""
        SELECT * FROM `{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}`
        ORDER BY user_id
    """
    
    # 直接转换为DataFrame
    df = client.query(query).to_dataframe()
    
    print(f"\n数据形状: {df.shape}")
    print("\n数据预览：")
    print(df.to_string())


def streaming_insert():
    """流式插入（实时数据）"""
    print("\n" + "="*50)
    print("流式插入")
    print("="*50)
    
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    
    # 流式插入不需要预先创建表
    rows = [
        {"user_id": 100, "name": "Test User", "email": "test@example.com"},
    ]
    
    errors = client.insert_rows_json(table_id, rows)
    
    if errors == []:
        print("✓ 流式插入成功")
    else:
        print(f"✗ 错误: {errors}")


def main():
    """主函数"""
    print("\n" + "="*60)
    print("BigQuery Python SDK 演示")
    print("="*60)
    
    # 创建数据集和表
    create_dataset()
    create_table()
    
    # 插入数据
    insert_data()
    
    # 查询数据
    query_data()
    
    # DataFrame查询
    query_to_dataframe()


if __name__ == "__main__":
    main()
```

---

## 3. Cloud SQL - 关系型数据库

### 3.1 Cloud SQL核心概念

**为什么选择Cloud SQL而不是自建数据库？**

```
Cloud SQL vs 自建数据库

┌─────────────────────────────────────────────────────────────────────────┐
│                        Cloud SQL核心优势                                 │
│                                                                         │
│  1. 托管运维                                                            │
│     ├── 自动备份（每日/随时）                                           │
│     ├── 自动打补丁（维护窗口）                                          │
│     ├── 自动复制（高可用）                                              │
│     └── 故障转移（自动）                                                │
│                                                                         │
│  2. 高可用                                                              │
│     ├── 主备自动同步                                                    │
│     ├── 故障自动检测                                                    │
│     ├── 自动故障转移（<60秒）                                          │
│     └── 99.99%可用性                                                    │
│                                                                         │
│  3. 安全                                                                │
│     ├── 静态加密（Google管理密钥）                                     │
│     ├── 传输加密（SSL/TLS）                                            │
│     ├── VPC私有访问                                                    │
│     └── IAM集成                                                        │
│                                                                         │
│  4. 可扩展                                                              │
│     ├── 垂直扩展（增加CPU/内存）                                        │
│     ├── 只读副本（横向扩展读取）                                        │
│     └── 自动存储扩展                                                    │
│                                                                         │
│  成本对比：                                                             │
│  - 自建：需付服务器+运维+备份+高可用+安全                               │
│  - Cloud SQL：按需付费，运维包含在内                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Cloud SQL操作 - Windows PowerShell

```powershell
# ============================================================
# Cloud SQL操作 - Windows PowerShell
# ============================================================

# ========== 1. 创建Cloud SQL实例 ==========

# Cloud SQL支持MySQL、PostgreSQL、SQL Server

# 创建MySQL实例
gcloud sql instances create my-mysql `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --storage-size=20GB `
    --storage-type=SSD `
    --enable-bin-log `
    --backup-start-time=03:00

# 创建PostgreSQL实例
gcloud sql instances create my-postgres `
    --database-version=POSTGRES_15 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --storage-size=20GB

# 创建高可用实例（Multi-AZ）
gcloud sql instances create my-ha-mysql `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --availability-type=REGIONAL `
    --storage-size=20GB

# ========== 2. 创建数据库和用户 ==========

# 创建数据库
gcloud sql databases create myapp_db --instance=my-mysql

# 创建用户
gcloud sql users create app_user `
    --instance=my-mysql `
    --password=SecurePassword123

# 查看用户
gcloud sql users list --instance=my-mysql

# ========== 3. 连接Cloud SQL ==========

# 方法1：通过代理连接（安全）
# 下载代理
Invoke-WebRequest -Uri "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy_x64.exe" -OutFile "cloud-sql-proxy.exe"

# 启动代理（需要先下载密钥文件）
./cloud-sql-proxy --port 5432 my-project:us-central1:my-mysql

# 方法2：通过公网IP连接（需要配置授权网络）
gcloud sql instances patch my-mysql --authorized-networks=0.0.0.0/0

# 获取连接信息
gcloud sql instances describe my-mysql

# ========== 4. 备份和恢复 ==========

# 查看备份
gcloud sql instances list-backups my-mysql

# 创建按需备份
gcloud sql instances create-backup my-mysql --description="before-migration"

# 从备份恢复
gcloud sql instances restore-backup my-mysql --backup-id=BACKUP_ID --target-instance=restored-instance

# ========== 5. 复制和高可用 ==========

# 创建只读副本
gcloud sql instances create read-replica `
    --master-instance-name=my-mysql `
    --region=us-east1

# 故障转移测试（HA实例）
gcloud sql instances failover my-ha-mysql

# ========== 6. 管理操作 ==========

# 重启实例
gcloud sql instances restart my-mysql

# 升级实例
gcloud sql instances patch my-mysql --tier=db-n1-standard-4

# 导出数据
gcloud sql export sql my-mysql gs://bucket/backup.sql --database=myapp_db

# 导入数据
gcloud sql import sql my-mysql gs://bucket/backup.sql --database=myapp_db

# 删除实例
gcloud sql instances delete my-mysql
```

### 3.3 Cloud SQL Python连接

```python
# cloud_sql_demo.py
"""
Cloud SQL连接示例 - Python
展示如何安全连接Cloud SQL
"""

import os
import pymysql
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# ============================================================
# 连接方式选择：
#
# 1. 直接连接（公网）：
#    - 需要配置授权网络
#    - 安全性较低
#    - 适合开发测试
#
# 2. Cloud SQL Proxy（推荐）：
#    - 本地启动代理
#    - 所有流量经过加密
#    - 不需要公网IP
# ============================================================

# 方法1：使用pymysql直接连接
def connect_direct():
    """直接连接（需要配置授权网络）"""
    print("\n" + "="*50)
    print("方法1：直接连接")
    print("="*50)
    
    # 获取实例IP
    # gcloud sql instances describe INSTANCE_NAME --format="get(ipAddresses[0].ipAddress)"
    instance_ip = "10.0.0.1"  # 替换为实际IP
    
    connection = pymysql.connect(
        host=instance_ip,
        user="app_user",
        password="SecurePassword123",
        database="myapp_db",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )
    
    return connection


def connect_with_proxy():
    """通过代理连接"""
    print("\n" + "="*50)
    print("方法2：通过Cloud SQL Proxy连接")
    print("="*50)
    
    # 启动代理后，本地监听5432端口
    # ./cloud-sql-proxy --port 5432 PROJECT:REGION:INSTANCE
    
    connection = pymysql.connect(
        host="127.0.0.1",
        port=5432,  # 代理端口
        user="app_user",
        password="SecurePassword123",
        database="myapp_db"
    )
    
    return connection


def connect_with_sqlalchemy():
    """使用SQLAlchemy连接（推荐）"""
    print("\n" + "="*50)
    print("方法3：使用SQLAlchemy")
    print("="*50)
    
    # 连接字符串格式
    # mysql+pymysql://user:password@host:port/database
    
    engine = create_engine(
        "mysql+pymysql://app_user:SecurePassword123@127.0.0.1:5432/myapp_db",
        pool_pre_ping=True,
        pool_recycle=3600
    )
    
    return engine


def demo_operations():
    """演示数据库操作"""
    print("\n" + "="*50)
    print("数据库操作演示")
    print("="*50)
    
    # 使用SQLAlchemy
    engine = connect_with_sqlalchemy()
    Session = sessionmaker(bind=engine)
    session = Session()
    
    # 插入数据
    # session.execute(text("INSERT INTO users (name, email) VALUES (:name, :email)"),
    #                {"name": "Alice", "email": "alice@example.com"})
    # session.commit()
    
    # 查询数据
    # result = session.execute(text("SELECT * FROM users"))
    # for row in result:
    #     print(row)
    
    print("✓ 数据库操作完成")
    session.close()


def main():
    """主函数"""
    print("\n" + "="*60)
    print("Cloud SQL Python连接演示")
    print("="*60)
    
    # 演示操作
    demo_operations()


if __name__ == "__main__":
    main()
```

---

## 4. Firestore NoSQL数据库

### 4.1 Firestore核心概念

**为什么选择Firestore而不是传统数据库？**

```
Firestore vs 传统数据库

┌─────────────────────────────────────────────────────────────────────────┐
│                        Firestore核心优势                                  │
│                                                                         │
│  1. 灵活的数据模型                                                       │
│     ├── 无需预定义Schema                                                │
│     ├── 文档可以有不同的字段                                            │
│     ├── 支持嵌套对象和数组                                              │
│     └── 适合快速迭代的应用                                              │
│                                                                         │
│  2. 实时同步                                                            │
│     ├── 客户端监听数据变化                                              │
│     ├── 离线支持（本地缓存）                                            │
│     ├── 跨设备实时同步                                                  │
│     └── 特别适合移动应用/Web实时应用                                    │
│                                                                         │
│  3. 简单的API                                                           │
│     ├── 直观的文档/集合概念                                             │
│     ├── 强大的查询能力                                                  │
│     ├── 自动索引                                                        │
│     └── 无需编写复杂SQL                                                 │
│                                                                         │
│  4. 全球分布                                                            │
│     ├── 自动多区域复制                                                  │
│     ├── 就近读取（低延迟）                                              │
│     └── 强一致性或最终一致性可选                                        │
│                                                                         │
│  Firestore数据结构：                                                     │
│                                                                         │
│  集合(Collection) ──→ 文档(Document) ──→ 字段(Field)                   │
│       ↓                                                                  │
│    子集合(Sub-collection)                                               │
│                                                                         │
│  例：                                                                   │
│  users (集合)                                                           │
│   ├── user1 (文档)                                                      │
│   │   ├── name: "Alice"                                               │
│   │   ├── age: 28                                                     │
│   │   └── orders (子集合)                                             │
│   │       └── order1                                                  │
│   └── user2 (文档)                                                      │
│       └── ...                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Firestore操作 - Windows PowerShell

```powershell
# ============================================================
# Firestore操作 - Windows PowerShell
# ============================================================

# ========== 1. 启用Firestore ==========

# Firestore是Datastore的新版本，推荐使用
gcloud firestore databases create --location=us-central1

# 如果是首次创建，需要确认
# gcloud firestore databases create --location=us-central1 --type=firestore-native

# ========== 2. 使用gcloud操作 ==========

# 注意：gcloud firestore命令有限
# 建议使用Firebase CLI或Python SDK

# 列出集合
gcloud firestore indexes collections list

# 查看索引
gcloud firestore indexes composite list

# 导出数据
gcloud firestore export gs://bucket/backup \
    --collection-ids=users,products

# 导入数据
gcloud firestore import gs://bucket/backup
```

### 4.3 Firestore Python SDK

```python
# firestore_demo.py
"""
Firestore Python SDK示例
展示NoSQL文档数据库操作
"""

from google.cloud import firestore
from datetime import datetime
import asyncio

# ============================================================
# Firestore核心概念：
#
# 集合(Collection)：文档的容器，类似表
# 文档(Document)：包含字段的对象，类似行
# 字段(Field)：键值对
# 引用(Reference)：指向其他文档的指针
#
# 与关系型数据库对比：
#   关系型：表 → 行 → 列
#   Firestore：集合 → 文档 → 字段
# ============================================================

# 创建客户端
db = firestore.Client()

PROJECT_ID = "your-project-id"


def create_user():
    """创建用户文档"""
    print("\n" + "="*50)
    print("创建用户文档")
    print("="*50)
    
    # 文档引用
    user_ref = db.collection("users").document("user_alice")
    
    # 设置文档数据
    user_ref.set({
        "name": "Alice",
        "email": "alice@example.com",
        "age": 28,
        "city": "New York",
        "created_at": firestore.SERVER_TIMESTAMP,
        "tags": ["developer", "gcp"],
        "profile": {
            "bio": "Software Engineer",
            "avatar_url": "https://example.com/avatar.jpg"
        }
    })
    
    print("✓ 文档创建成功")


def add_document_auto_id():
    """自动生成ID添加文档"""
    print("\n" + "="*50)
    print("自动ID添加文档")
    print("="*50)
    
    # 自动生成文档ID
    doc_ref = db.collection("users").add({
        "name": "Bob",
        "email": "bob@example.com",
        "age": 35,
        "created_at": firestore.SERVER_TIMESTAMP
    })
    
    print(f"✓ 文档创建，ID: {doc_ref[1].id}")


def query_data():
    """查询数据"""
    print("\n" + "="*50)
    print("查询数据")
    print("="*50)
    
    # 简单查询：获取所有文档
    print("\n1. 获取所有用户：")
    users_ref = db.collection("users")
    docs = users_ref.stream()
    
    for doc in docs:
        data = doc.to_dict()
        print(f"  - {data.get('name', 'N/A')}: {data.get('email', 'N/A')}")
    
    # 条件查询：年龄大于25
    print("\n2. 年龄大于25的用户：")
    query = users_ref.where("age", ">", 25).order_by("age")
    docs = query.stream()
    
    for doc in docs:
        data = doc.to_dict()
        print(f"  - {data.get('name', 'N/A')}: {data.get('age', 'N/A')}岁")
    
    # 复合查询：年龄在25-35之间
    print("\n3. 年龄在25-35之间的用户：")
    query = users_ref.where("age", ">=", 25).where("age", "<=", 35)
    docs = query.stream()
    
    for doc in docs:
        data = doc.to_dict()
        print(f"  - {data.get('name', 'N/A')}: {data.get('age', 'N/A')}岁")


def update_document():
    """更新文档"""
    print("\n" + "="*50)
    print("更新文档")
    print("="*50)
    
    user_ref = db.collection("users").document("user_alice")
    
    # 更新特定字段
    user_ref.update({
        "age": 29,
        "city": "San Francisco",
        "updated_at": firestore.SERVER_TIMESTAMP
    })
    
    print("✓ 文档更新成功")


def delete_data():
    """删除数据"""
    print("\n" + "="*50)
    print("删除数据")
    print("="*50)
    
    # 删除文档
    user_ref = db.collection("users").document("user_alice")
    user_ref.delete()
    
    print("✓ 文档删除成功")
    
    # 删除字段
    user_ref = db.collection("users").document("user_bob")
    user_ref.update({
        "age": firestore.DELETE_FIELD
    })
    
    print("✓ 字段删除成功")


def realtime_listener():
    """实时监听（需要异步）"""
    print("\n" + "="*50)
    print("实时监听")
    print("="*50)
    
    # 注意：这个函数需要异步运行
    async def listen_changes():
        # 监听集合变化
        def on_snapshot(collection_snapshot, changes, read_time):
            print("\n--- 集合变化 ---")
            for doc in collection_snapshot:
                print(f"文档: {doc.id} -> {doc.to_dict()}")
        
        # 启动监听
        query_watch = db.collection("users").where("age", ">", 18).on_snapshot(on_snapshot)
        
        # 注意：实际使用需要保持事件循环运行
        # 这里只展示用法
    
    # 实际使用示例（同步版本）
    print("注意：实时监听需要异步环境")
    print("实际用法：")
    print("""
# 监听单个文档
doc_ref = db.collection("users").document("user_alice")

def on_snapshot(doc_snapshot, changes, read_time):
    for doc in doc_snapshot:
        print(f"文档数据: {doc.to_dict()}")

doc_watch = doc_ref.on_snapshot(on_snapshot)

# 保持程序运行...
""")


def transaction_demo():
    """事务示例"""
    print("\n" + "="*50)
    print("事务操作")
    print("="*50)
    
    @firestore.transactional
    def update_balance(transaction, user_ref, amount):
        # 读取当前值
        snapshot = user_ref.get(transaction=transaction)
        current_balance = snapshot.get("balance", 0)
        
        # 计算新值
        new_balance = current_balance + amount
        
        # 写入
        transaction.update(user_ref, {
            "balance": new_balance,
            "updated_at": firestore.SERVER_TIMESTAMP
        })
        
        return new_balance
    
    transaction = db.transaction()
    user_ref = db.collection("users").document("user_alice")
    
    new_balance = transaction.update_balance(user_ref, 100)
    transaction.commit()
    
    print(f"✓ 事务提交成功，新余额: {new_balance}")


def batch_operation():
    """批量操作"""
    print("\n" + "="*50)
    print("批量操作")
    print("="*50)
    
    batch = db.batch()
    
    # 批量添加
    for i in range(5):
        doc_ref = db.collection("batch_users").document()
        batch.set(doc_ref, {
            "name": f"User {i}",
            "index": i,
            "created_at": firestore.SERVER_TIMESTAMP
        })
    
    # 批量更新
    # batch.update(doc_ref, {"field": "value"})
    
    # 批量删除
    # batch.delete(doc_ref)
    
    # 提交批量操作
    batch.commit()
    
    print("✓ 批量操作完成")


def main():
    """主函数"""
    print("\n" + "="*60)
    print("Firestore Python SDK 演示")
    print("="*60)
    
    # 注意：以下操作会创建真实数据
    # 取消注释运行
    
    # create_user()
    # add_document_auto_id()
    # query_data()
    # update_document()
    # batch_operation()
    
    print("\n示例代码完成")


if __name__ == "__main__":
    main()
```

---

## 5. 数据服务选择指南

### 5.1 如何选择正确的数据存储？

```
数据存储选择决策树

┌─────────────────────────────────────────────────────────────────────────┐
│                        数据存储选择指南                                   │
│                                                                         │
│  开始                                                                    │
│    │                                                                    │
│    ▼                                                                    │
│  需要事务支持吗？                                                        │
│    │                                                                    │
│    ├─ 是 ──→ 需要水平扩展吗？                                          │
│    │           │                                                        │
│    │           ├─ 是 ──→ 需要全球分布吗？                              │
│    │           │           │                                            │
│    │           │           ├─ 是 ──→ Cloud Spanner                    │
│    │           │           │                                            │
│    │           │           └─ 否 ──→ 需要多区域？                     │
│    │           │               │                                        │
│    │           │               ├─ 是 ──→ Cloud SQL (HA)                │
│    │           │               │                                        │
│    │           │               └─ 否 ──→ Cloud SQL                     │
│    │           │                                                        │
│    │           └─ 否 ──→ Cloud SQL / Firestore                        │
│    │                                                                    │
│    └─ 否 ──→ 需要实时分析吗？                                          │
│                │                                                        │
│                ├─ 是 ──→ BigQuery                                     │
│                │                                                        │
│                └─ 否 ──→ 数据量大小？                                  │
│                        │                                                │
│                        ├─ 小/中 ──→ Firestore                          │
│                        │                                                        │
│                        └─ 大 ──→ BigQuery / Cloud Storage             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Windows PowerShell命令速查

```powershell
# ============================================================
# 数据服务命令速查
# ============================================================

# ---------- BigQuery ----------
# 创建数据集
bq mk dataset_name

# 查询
bq query "SELECT * FROM dataset.table"

# 加载数据
bq load dataset.table gs://bucket/file.csv schema

# ---------- Cloud SQL ----------
# 创建实例
gcloud sql instances create NAME --database-version=VERSION --tier=TIER

# 创建数据库
gcloud sql databases create DB_NAME --instance=INSTANCE

# 创建用户
gcloud sql users create USER --instance=INSTANCE --password=PASSWORD

# 导出
gcloud sql export sql INSTANCE gs://bucket/file.sql --database=DB

# 导入
gcloud sql import sql INSTANCE gs://bucket/file.sql --database=DB

# ---------- Firestore ----------
# 创建数据库
gcloud firestore databases create --location=LOCATION

# 导出
gcloud firestore export gs://bucket/path

# 导入
gcloud firestore import gs://bucket/path
```

---

## 7. 知识检测

### 选择题

1. BigQuery最适合什么场景？
   - A. 事务处理
   - B. PB级数据分析 ✓
   - C. 实时数据写入
   - D. 文件存储

2. Cloud SQL的主要优势是什么？
   - A. 完全免费
   - B. 自动备份和高可用 ✓
   - C. 只能运行MySQL
   - D. 不需要付费

3. Firestore的实时同步功能最适合什么应用？
   - A. 批处理系统
   - B. 移动应用/Web实时应用 ✓
   - C. 传统CRM
   - D. 数据仓库

---

## 学习进度

- [ ] 理解数据服务选择原理
- [ ] 掌握BigQuery数据仓库
- [ ] 学会Cloud SQL数据库管理
- [ ] 掌握Firestore NoSQL数据库
- [ ] 完成实战项目
