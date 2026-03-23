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