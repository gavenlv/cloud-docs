# GCP网络与安全

## 本章概述

GCP提供强大的网络与安全服务。本章深入讲解VPC网络、IAM身份管理、Secret Manager和Cloud Armor安全防护的原理和实战操作，帮助你理解为什么需要这些安全措施，以及如何在Windows环境下完成配置。

## 学习目标

- 掌握VPC网络配置和原理
- 深入理解IAM权限管理机制
- 掌握Secret Manager敏感信息管理
- 学会Cloud Armor安全防护配置
- 理解零信任安全架构

---

## 1. VPC网络 - 深入理解

### 1.1 为什么需要VPC？

**VPC（虚拟私有云）是GCP网络的基础，让我们理解它的核心价值：**

```
传统数据中心 vs VPC

┌─────────────────────────────────────────────────────────────────────────┐
│                    传统数据中心网络                                       │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      物理网络                                    │   │
│  │                                                                  │   │
│  │  路由器 ─── 交换机 ─── 防火墙 ─── 负载均衡器                      │   │
│  │      │                                      │                     │   │
│  │      └──────────────────────────────────────┘                     │   │
│  │                         │                                         │   │
│  │                    服务器集群                                     │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  问题：                                                                │
│  - 需要购买物理设备                                                   │
│  - 扩展困难                                                           │
│  - 难以隔离                                                           │
│  - 配置复杂                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         VPC网络                                         │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    虚拟网络（软件定义）                          │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │   │
│  │  │  子网 A      │  │  子网 B      │  │  子网 C      │        │   │
│  │  │  10.0.1.0/24│  │ 10.0.2.0/24 │  │ 10.0.3.0/24 │        │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │   │
│  │         │                  │                  │                 │   │
│  │         └──────────────────┼──────────────────┘                 │   │
│  │                            ▼                                      │   │
│  │              虚拟防火墙规则 (Firewall Rules)                      │   │
│  │                            ▼                                      │   │
│  │              虚拟路由 (Routes)                                   │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  优势：                                                                │
│  - 无需物理设备                                                       │
│  - 即时创建和扩展                                                     │
│  - 精细隔离                                                           │
│  - 配置简单                                                           │
│  - 按使用付费                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 VPC核心概念详解

```
VPC网络架构

┌─────────────────────────────────────────────────────────────────────────┐
│                        VPC网络层次                                       │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    VPC网络 (Virtual Private Cloud)               │   │
│  │   - 全局资源（跨所有区域）                                       │   │
│  │   - IP地址范围（CIDR块）                                        │   │
│  │   - DNS配置                                                      │   │
│  │   - 路由表                                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    子网 (Subnet)                                  │   │
│  │   - 区域级资源                                                  │   │
│  │   - 指定IP范围                                                  │   │
│  │   - 可配置访问Google服务                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    资源 (Instances)                              │   │
│  │   - VM、容器、负载均衡器等                                      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    网络策略 (Policy)                              │   │
│  │   - 防火墙规则                                                  │   │
│  │   - 路由规则                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.3 VPC操作 - Windows PowerShell

```powershell
# ============================================================
# VPC网络操作 - Windows PowerShell
# ============================================================

# ========== 1. 创建VPC网络 ==========

# 创建自动模式VPC（推荐，简单）
# 自动模式：Google自动在每个区域创建子网
gcloud compute networks create auto-vpc `
    --subnet-mode=auto

# 创建自定义模式VPC（推荐生产环境）
# 自定义模式：完全控制子网
gcloud compute networks create custom-vpc `
    --subnet-mode=custom `
    --bgp-routing-mode=regional

# 查看VPC列表
gcloud compute networks list

# 查看VPC详情
gcloud compute networks describe custom-vpc

# ========== 2. 创建子网 ==========

# 在自定义VPC中创建子网
gcloud compute networks subnets create subnet-us-central1 `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24 `
    --enable-private-ip-google-access

# 创建带次要IP范围的子网
gcloud compute networks subnets create subnet-with-secondary `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.2.0/24 `
    --secondary-range=range1=10.0.100.0/24

# 查看子网
gcloud compute networks subnets list

# 查看特定子网
gcloud compute networks subnets describe subnet-us-central1 --region=us-central1

# ========== 3. 防火墙规则 ==========

# 创建防火墙规则允许SSH/RDP
gcloud compute firewall-rules create allow-ssh `
    --network=custom-vpc `
    --allow=tcp:22 `
    --source-ranges=0.0.0.0/0 `
    --description="Allow SSH"

# 创建防火墙规则允许内部通信
gcloud compute firewall-rules create allow-internal `
    --network=custom-vpc `
    --allow=tcp:0-65535,udp:0-65535,icmp `
    --source-ranges=10.0.0.0/16 `
    --description="Allow internal traffic"

# 创建防火墙规则允许HTTP/HTTPS
gcloud compute firewall-rules create allow-http `
    --network=custom-vpc `
    --allow=tcp:80,tcp:443 `
    --source-ranges=0.0.0.0/0 `
    --target-tags=http-server,https-server

# 创建防火墙规则允许健康检查
gcloud compute firewall-rules create allow-health-check `
    --network=custom-vpc `
    --allow=tcp:80,tcp:443 `
    --source-ranges=130.211.0.0/22,35.191.0.0/16 `
    --description="Allow GCP health checks"

# 列出防火墙规则
gcloud compute firewall-rules list --filter="network:custom-vpc"

# ========== 4. 路由 ==========

# 查看路由
gcloud compute routes list

# 创建自定义路由
gcloud compute routes create custom-route `
    --network=custom-vpc `
    --destination-range=192.168.0.0/24 `
    --next-hop-gateway=default-internet-gateway `
    --priority=1000

# ========== 5. VPC对等互连 ==========

# 创建VPC网络对等互连（两个VPC之间私有通信）
# 步骤1：发起方配置
gcloud compute networks peerings create peer-to-shared-vpc `
    --network=custom-vpc `
    --peer-network=shared-host-vpc `
    --import-custom-routes `
    --export-custom-routes

# 查看对等互连
gcloud compute networks peerings list --network=custom-vpc
```

---

## 2. IAM权限管理 - 核心原理

### 2.1 理解IAM的工作原理

**为什么需要IAM？**

```
IAM解决的问题

┌─────────────────────────────────────────────────────────────────────────┐
│                         IAM核心概念                                       │
│                                                                         │
│  问题：谁可以访问什么资源？做什么操作？                                    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    IAM核心组件                                   │   │
│  │                                                                  │   │
│  │  身份 (Who)                                                      │   │
│  │  ├── 用户账户（个人）                                           │   │
│  │  ├── 服务账号（程序/机器）                                      │   │
│  │  └── Google Groups（组）                                        │   │
│  │                                                                  │   │
│  │  角色 (Role)                                                     │   │
│  │  ├── 基本角色（Owner/Editor/Viewer）                            │   │
│  │  ├── 预定义角色（细分权限）                                      │   │
│  │  └── 自定义角色（精确控制）                                      │   │
│  │                                                                  │   │
│  │  资源 (What)                                                      │   │
│  │  ├── 项目                                                        │   │
│  │  ├── 服务                                                        │   │
│  │  └── 具体资源（VM、存储桶等）                                    │   │
│  │                                                                  │   │
│  │  权限 (Action)                                                    │   │
│  │  └── 细粒度操作（read、write、delete等）                        │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 理解Role和Permission

```
角色层次结构

┌─────────────────────────────────────────────────────────────────────────┐
│                         角色类型                                         │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    基本角色 (Primitive Roles)                     │   │
│  │   (不推荐生产环境使用，权限过大)                                  │   │
│  │                                                                  │   │
│  │  Viewer (查看者) ─── 只读，所有资源                              │   │
│  │  Editor (编辑者) ─── 读写，所有资源（不能管理权限）              │   │
│  │  Owner (所有者) ─── 完全控制，包括管理权限和计费                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    预定义角色 (Predefined Roles)                  │   │
│  │   (推荐使用，细粒度控制)                                         │   │
│  │                                                                  │   │
│  │  例：                                                            │   │
│  │  roles/compute.instanceAdmin ─── VM管理权限                     │   │
│  │  roles/storage.objectAdmin ─── 存储完全管理                     │   │
│  │  roles/bigquery.dataEditor ─── BigQuery数据编辑                │   │
│  │  roles/secretmanager.secretAccessor ─── 密钥读取                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    自定义角色 (Custom Roles)                      │   │
│  │   (最精确，满足特殊需求)                                         │   │
│  │                                                                  │   │
│  │  例：                                                            │   │
│  │  创建只读存储+只读计算+编辑BigQuery的角色                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 IAM操作 - Windows PowerShell

```powershell
# ============================================================
# IAM操作 - Windows PowerShell
# ============================================================

# ========== 1. 查看当前权限 ==========

# 查看当前用户身份
gcloud auth list

# 查看当前用户权限
gcloud projects get-iam-policy PROJECT_ID

# 查看具体资源权限
gcloud compute instances get-iam-policy INSTANCE_NAME --zone=ZONE

# ========== 2. 管理服务账号 ==========

# 创建服务账号
gcloud iam service-accounts create my-app-sa `
    --display-name="My Application SA" `
    --description="Service account for my application"

# 创建带邮箱的服务账号
gcloud iam service-accounts create "my-app-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# 查看服务账号
gcloud iam service-accounts list

# 给服务账号添加角色
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/storage.objectViewer"

# 移除角色
gcloud projects remove-iam-policy-binding PROJECT_ID `
    --member="serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/storage.objectViewer"

# ========== 3. 管理用户权限 ==========

# 添加用户到项目
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="user:alice@example.com" `
    --role="roles/viewer"

# 添加组到项目
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="group:developers@example.com" `
    --role="roles/editor"

# 添加域到项目
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="domain:example.com" `
    --role="roles/viewer"

# ========== 4. 创建自定义角色 ==========

# 查看权限列表
gcloud iam permissions list

# 创建自定义角色
gcloud iam roles create custom.appViewer `
    --project=PROJECT_ID `
    --title="Custom App Viewer" `
    --description="Can view app resources" `
    --permissions=compute.instances.get,compute.instances.list,storage.objects.get

# 更新自定义角色
gcloud iam roles update custom.appViewer `
    --project=PROJECT_ID `
    --add-permissions=storage.buckets.get

# ========== 5. 服务账号密钥管理 ==========

# 创建服务账号密钥（不推荐，用于测试）
gcloud iam service-accounts keys create key.json `
    --iam-account=my-app-sa@PROJECT_ID.iam.gserviceaccount.com

# 列出服务账号密钥
gcloud iam service-accounts keys list `
    --iam-account=my-app-sa@PROJECT_ID.iam.gserviceaccount.com

# 删除服务账号密钥
gcloud iam service-accounts keys delete KEY_ID `
    --iam-account=my-app-sa@PROJECT_ID.iam.gserviceaccount.com

# ========== 6. 条件角色绑定 ==========

# 基于属性的条件访问
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member="user:alice@example.com" `
    --role="roles/compute.instanceAdmin" `
    --condition="resource.name.startsWith('projects/PROJECT_ID/zones/us-central1-a/instances/prod-')"
```

---

## 3. Secret Manager - 敏感信息管理

### 3.1 为什么需要Secret Manager？

```
敏感信息管理的重要性

┌─────────────────────────────────────────────────────────────────────────┐
│                    敏感信息管理最佳实践                                   │
│                                                                         │
│  常见敏感信息：                                                         │
│  ├── 数据库密码                                                          │
│  ├── API密钥                                                            │
│  ├── OAuth令牌                                                          │
│  ├── TLS证书                                                            │
│  ├── SSH密钥                                                            │
│  └── 加密密钥                                                          │
│                                                                         │
│  不安全的做法：                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  1. 硬编码在代码中                                              │   │
│  │     ├── 代码仓库泄露                                            │   │
│  │     └── 无法轮换                                                │   │
│  │                                                                  │   │
│  │  2. 环境变量                                                    │   │
│  │     ├── 容器镜像可能包含                                        │   │
│  │     └── 日志可能暴露                                            │   │
│  │                                                                  │   │
│  │  3. 配置文件                                                    │   │
│  │     ├── 可能提交到Git                                           │   │
│  │     └── 难以审计                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  Secret Manager解决方案：                                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  集中存储 ─── 一个地方管理所有敏感信息                           │   │
│  │  版本控制 ─── 支持多个版本，轻松回滚                            │   │
│  │  访问控制 ─── IAM精确控制谁能访问                               │   │
│  │  审计日志 ─── 谁在什么时候访问了一目了然                        │   │
│  │  自动轮换 ─── 简化密钥更新                                      │   │
│  │  加密存储 ─── 默认加密，安全可靠                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Secret Manager操作

```powershell
# ============================================================
# Secret Manager操作 - Windows PowerShell
# ============================================================

# ========== 1. 启用Secret Manager ==========

gcloud services enable secretmanager.googleapis.com

# ========== 2. 创建Secret ==========

# 创建简单的secret
gcloud secrets create db-password `
    --replication-policy=automatic

# 创建带值的secret
echo "my-secret-password" | gcloud secrets create db-password `
    --replication-policy=automatic `
    --data-file=-

# 创建带标签的secret
gcloud secrets create api-key `
    --replication-policy=automatic `
    --labels=environment=production,team=backend

# ========== 3. 版本管理 ==========

# 添加新版本
echo "new-password-v2" | gcloud secrets versions add db-password `
    --data-file=-

# 列出所有版本
gcloud secrets versions list db-password

# 获取最新版本的值
gcloud secrets versions access latest --secret=db-password

# 获取特定版本的值
gcloud secrets versions access 1 --secret=db-password

# 禁用版本
gcloud secrets versions disable 1 --secret=db-password

# 销毁版本（不可恢复）
gcloud secrets versions destroy 1 --secret=db-password

# ========== 4. 访问控制 ==========

# 授予服务账号访问权限
gcloud secrets add-iam-policy-binding db-password `
    --member="serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/secretmanager.secretAccessor"

# 撤销访问权限
gcloud secrets remove-iam-policy-binding db-password `
    --member="serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/secretmanager.secretAccessor"

# ========== 5. 自动轮换 ==========

# 配置自动轮换（需要Cloud Scheduler）
# 步骤1：创建Cloud Scheduler job
gcloud scheduler jobs create http rotate-secret `
    --schedule="0 0 1 * *" `
    --uri="https://secretmanager.googleapis.com/v1/projects/PROJECT_ID/secrets/db-password:rotate" `
    --http-method=POST

# ========== 6. 审计 ==========

# 查看审计日志
gcloud logging read "resource.type=secret_manager"
```

### 3.3 Secret Manager Python SDK

```python
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
```

---

## 4. Cloud Armor - 安全防护

### 4.1 理解Cloud Armor的作用

```
多层安全防护架构

┌─────────────────────────────────────────────────────────────────────────┐
│                        安全防护层次                                       │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第一层：边界防护                               │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Cloud Armor ─── WAF/DDoS防护                         │    │   │
│  │  │  ├── SQL注入防护                                        │    │   │
│  │  │  ├── XSS防护                                            │    │   │
│  │  │  ├── DDoS攻击防护                                       │    │   │
│  │  │  ├── IP黑名单/白名单                                   │    │   │
│  │  │  └── Geo限制                                            │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第二层：应用防护                               │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  IAM ─── 身份验证和授权                                │    │   │
│  │  │  ├── 谁可以访问                                         │    │   │
│  │  │  └── 可以做什么                                         │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    第三层：数据防护                               │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Secret Manager / KMS ─── 敏感数据加密                 │    │   │
│  │  │  Cloud Storage ─── 存储加密                            │    │   │
│  │  │  Cloud SQL ─── 数据库加密                              │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Cloud Armor操作

```powershell
# ============================================================
# Cloud Armor操作 - Windows PowerShell
# ============================================================

# ========== 1. 创建安全策略 ==========

# 创建安全策略
gcloud compute security-policies create my-security-policy `
    --description="My web application security policy"

# ========== 2. 配置规则 ==========

# 阻止特定IP
gcloud compute security-policies rules create 1000 `
    --security-policy=my-security-policy `
    --action=deny(403) `
    --description="Block malicious IP" `
    --src-ip-ranges="192.0.2.0/24"

# 允许健康检查
gcloud compute security-policies rules create 1001 `
    --security-policy=my-security-policy `
    --action=allow `
    --description="Allow health checks" `
    --src-ip-ranges="130.211.0.0/22,35.191.0.0/16"

# 阻止SQL注入
gcloud compute security-policies rules create 1002 `
    --security-policy=my-security-policy `
    --action=deny-valid-response `
    --description="Block SQL injection" `
    --expression="evaluatePreconfiguredExpr('xss-v33-stable')"

# 阻止XSS攻击
gcloud compute security-policies rules create 1003 `
    --security-policy=my-security-policy `
    --action=deny-valid-response `
    --description="Block XSS attacks" `
    --expression="evaluatePreconfiguredExpr('xss-v33-stable')"

# 地理限制（阻止特定国家）
gcloud compute security-policies rules create 1004 `
    --security-policy=my-security-policy `
    --action=deny(403) `
    --description="Block specific countries" `
    --expression="origin.region_code in (CN, RU)"

# 速率限制
gcloud compute security-policies rules create 1005 `
    --security-policy=my-security-policy `
    --action=throttle `
    --description="Rate limit" `
    --expression="request.method == 'POST'" `
    --rate-limit-threshold=1000 `
    --conform-action=allow `
    --exceed-action=deny(429) `
    --enforce-on-key=IP

# 优先级（数字越小优先级越高）
gcloud compute security-policies rules create 65534 `
    --security-policy=my-security-policy `
    --action=allow `
    --description="Default allow" `
    --src-ip-ranges="*"

# ========== 3. 附加到后端服务 ==========

# 创建后端服务
gcloud compute backend-services create my-backend-service `
    --protocol=HTTPS `
    --port-name=https `
    --health-checks=my-health-check

# 附加安全策略
gcloud compute backend-services update my-backend-service `
    --security-policy=my-security-policy

# ========== 4. 查看和管理 ==========

# 列出安全策略
gcloud compute security-policies list

# 查看策略详情
gcloud compute security-policies describe my-security-policy

# 列出规则
gcloud compute security-policies describe my-security-policy --format="get(name)"

# 更新规则描述
gcloud compute security-policies rules update 1000 `
    --security-policy=my-security-policy `
    --description="Updated description"

# 删除规则
gcloud compute security-policies rules delete 1000 `
    --security-policy=my-security-policy
```

---

## 5. 网络安全最佳实践

### 5.1 零信任网络架构

```
零信任网络原则

┌─────────────────────────────────────────────────────────────────────────┐
│                    零信任网络核心原则                                    │
│                                                                         │
│  1. 永不信任，始终验证                                                  │
│     ├── 每次访问都需要认证                                             │
│     ├── 每次访问都需要授权                                             │
│     └── 持续监控和验证                                                 │
│                                                                         │
│  2. 最小权限原则                                                        │
│     ├── 只授予必要的权限                                               │
│     ├── 定期审查权限                                                   │
│     └── 及时撤销不再需要的权限                                         │
│                                                                         │
│  3. 微分段                                                              │
│     ├── 精细的网络隔离                                                 │
│     ├── 限制横向移动                                                   │
│     └── 东西向流量控制                                                 │
│                                                                         │
│  4. 假设被入侵                                                          │
│     ├── 保护关键资源                                                   │
│     ├── 限制爆炸半径                                                   │
│     └── 快速检测和响应                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Windows PowerShell命令速查

```powershell
# ============================================================
# 网络与安全命令速查
# ============================================================

# ---------- VPC操作 ----------
# 创建VPC
gcloud compute networks create NAME --subnet-mode=auto

# 创建子网
gcloud compute networks subnets create NAME --network=NAME --region=REGION --range=CIDR

# 创建防火墙规则
gcloud compute firewall-rules create NAME --network=NAME --allow=PROTOCOL --source-ranges=RANGES

# ---------- IAM操作 ----------
# 添加IAM策略绑定
gcloud projects add-iam-policy-binding PROJECT --member=MEMBER --role=ROLE

# 创建服务账号
gcloud iam service-accounts create NAME --display-name=DISPLAY_NAME

# 列出服务账号
gcloud iam service-accounts list

# ---------- Secret Manager ----------
# 创建secret
gcloud secrets create NAME --replication-policy=automatic

# 访问secret
gcloud secrets versions access latest --secret=NAME

# 添加版本
gcloud secrets versions add NAME --data-file=FILE

# ---------- Cloud Armor ----------
# 创建安全策略
gcloud compute security-policies create NAME

# 创建规则
gcloud compute security-policies rules create PRIORITY --security-policy=NAME --action=ACTION

# 附加到后端服务
gcloud compute backend-services update NAME --security-policy=NAME
```

---

## 7. 知识检测

### 选择题

1. VPC的子网是什么级别的资源？
   - A. 全球级
   - B. 区域级 ✓
   - C. 项目级
   - D. 资源级

2. 服务账号主要用于什么场景？
   - A. 开发人员登录
   - B. 程序/机器身份认证 ✓
   - C. 客户访问
   - D. 管理员权限

3. Secret Manager的主要优势是什么？
   - A. 完全免费
   - B. 集中管理敏感信息 ✓
   - C. 只支持文本
   - D. 无法版本管理

---

## 学习进度

- [ ] 理解VPC网络原理
- [ ] 掌握IAM权限管理
- [ ] 掌握Secret Manager
- [ ] 学会Cloud Armor防护
- [ ] 理解零信任架构
- [ ] 完成实战项目
