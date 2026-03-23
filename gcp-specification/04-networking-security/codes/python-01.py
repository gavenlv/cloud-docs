# secret_manager_demo.py
"""
Secret Manager Python SDK示例
展示如何安全地管理敏感信息
"""

from google.cloud import secretmanager
import os

# ============================================================
# 原理说明：
# Secret Manager的工作原理：
# 1. 敏感数据加密存储
# 2. 通过IAM控制访问
# 3. 支持版本管理
# 4. 提供审计日志
# ============================================================

# 创建客户端
client = secretmanager.ServiceClient()

PROJECT_ID = "your-project-id"
SECRET_ID = "db-password"


def access_secret():
    """访问Secret"""
    print("\n" + "="*50)
    print("访问Secret")
    print("="*50)
    
    # 构建Secret名称
    name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
    
    # 访问
    response = client.access_secret_version(request={"name": name})
    
    # 解码值
    payload = response.payload.data.decode("UTF-8")
    
    print(f"✓ 成功访问Secret，长度: {len(payload)}字符")


def create_secret():
    """创建Secret"""
    print("\n" + "="*50)
    print("创建Secret")
    print("="*50)
    
    parent = f"projects/{PROJECT_ID}"
    
    # 创建Secret
    secret = client.create_secret(
        request={
            "parent": parent,
            "secret_id": SECRET_ID,
            "secret": {
                "replication": {
                    "automatic": {}
                }
            }
        }
    )
    
    print(f"✓ Secret创建成功: {secret.name}")


def add_secret_version():
    """添加Secret版本"""
    print("\n" + "="*50)
    print("添加Secret版本")
    print("="*50)
    
    parent = client.secret_path(PROJECT_ID, SECRET_ID)
    
    # 添加版本
    version = client.add_secret_version(
        request={
            "parent": parent,
            "payload": {
                "data": b"my-secret-value-v2"
            }
        }
    )
    
    print(f"✓ Secret版本添加成功: {version.name}")


def list_secrets():
    """列出所有Secret"""
    print("\n" + "="*50)
    print("列出Secret")
    print("="*50)
    
    parent = f"projects/{PROJECT_ID}"
    
    # 列出
    secrets = client.list_secrets(request={"parent": parent})
    
    for secret in secrets:
        print(f"  - {secret.name}")


def main():
    """主函数"""
    print("\n" + "="*60)
    print("Secret Manager Python SDK 演示")
    print("="*60)
    
    # 注意：这些操作会创建真实资源
    # 取消注释运行
    
    # access_secret()
    # create_secret()
    # list_secrets()


if __name__ == "__main__":
    main()