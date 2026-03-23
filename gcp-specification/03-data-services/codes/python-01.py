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