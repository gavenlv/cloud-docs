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