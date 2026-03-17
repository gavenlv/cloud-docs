# GCP基础入门

## 本章概述

Google Cloud Platform（GCP）是Google提供的云计算服务平台。本章将介绍GCP基础概念、核心服务架构和开发环境配置。本章从零开始，详细解释每个概念背后的原理，帮助你理解"为什么"要这样做。

## 学习目标

- 理解GCP架构体系和核心概念
- 掌握GCP核心服务及其适用场景
- 学会GCP命令行工具gcloud
- 配置GCP开发环境
- 理解GCP计费模型
- 掌握服务账号(Service Account)原理和实践

---

## 1. 理解云计算基础

### 1.1 什么是云计算？

**云计算**本质上是将计算资源（如服务器、存储、数据库、网络、软件等）作为服务通过互联网提供给用户。想象一下：

- **传统IT**：你需要自己购买服务器、配置网络、安装软件、维护硬件
- **云计算**：你只需要按需租用服务，其他事情云服务商帮你处理

**为什么云计算是革命性的？**
- 传统模式：投资大量资金购买硬件，然后大部分时间硬件闲置
- 云模式：按使用付费，像用水电一样使用计算资源

### 1.2 云计算服务模型

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      云计算服务模型对比                                  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    SaaS (软件即服务)                              │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │ 用户：使用服务商提供的应用程序                          │   │   │
│  │  │ 例：Gmail, Google Workspace, Salesforce                 │   │   │
│  │  │ 优点：无需管理，即开即用                                │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    PaaS (平台即服务)                            │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │ 用户：部署自己的代码，使用服务商提供的运行平台           │   │   │
│  │  │ 例：Cloud Run, Heroku, App Engine                      │   │   │
│  │  │ 优点：专注开发，无需管理基础设施                         │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    IaaS (基础设施即服务)                        │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │ 用户：租用服务器/存储/网络，完全控制操作系统以上        │   │   │
│  │  │ 例：Compute Engine, EC2, Azure VM                      │   │   │
│  │  │ 优点：最大灵活性，但需要更多管理                         │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. GCP核心概念详解

### 2.1 为什么需要Project（项目）？

**项目是GCP中最重要的组织单位**。你创建的所有资源（虚拟机、存储桶、数据库等）都必须属于某个项目。

**为什么不能直接使用资源，而要先创建项目？**
1. **资源隔离**：不同应用、不同环境（生产/开发/测试）可以分开管理
2. **权限控制**：可以精确控制谁可以访问哪些项目
3. **计费分离**：每个项目可以单独计费，方便成本分析
4. **配额管理**：每个项目有独立的资源配额，防止意外超支

```
项目结构示例：

组织 (Organization)
├── 开发部门
│   ├── 项目: web-app-dev      # 开发环境
│   │   ├── Compute Engine VM
│   │   └── Cloud Storage桶
│   └── 项目: api-dev         # API开发
│       └── Cloud Run服务
├── 测试部门
│   └── 项目: integration-test # 集成测试
└── 生产部门
    └── 项目: production       # 生产环境
        ├── GKE集群
        ├── Cloud SQL
        └── BigQuery数据集
```

### 2.2 Region（区域）和Zone（可用区）- 地理位置的原理

**为什么GCP要在全球这么多地方建数据中心？**

1. **降低延迟**：用户访问距离最近的数据中心，响应更快
2. **容灾备份**：一个数据中心出问题，其他位置可以接管
3. **数据合规**：某些国家要求数据必须存储在本地

```
Region（区域）和Zone（可用区）的关系：

Region: us-central1 (美国中部)
├── Zone: us-central1-a  (数据中心A)
├── Zone: us-central1-b  (数据中心B)
└── Zone: us-central1-c  (数据中心C)

特点：
- 同一Region内的Zone之间网络延迟 < 2ms
- 不同Region之间延迟通常在50-150ms
- Zone是独立的故障域，一个Zone故障不影响其他Zone
```

**如何选择Region？**
- 目标用户所在位置（选择最近的Region）
- 数据合规要求（某些数据必须存储在特定地区）
- 服务可用性（不是所有服务在所有Region可用）
- 价格差异（不同Region价格可能不同）

### 2.3 什么是Service Account（服务账号）？

**服务账号是GCP中最重要的安全概念之一。**

**为什么需要Service Account？**

想象一下场景：你的应用程序需要读取GCS存储桶中的文件。
- 方案A：把用户名密码写进代码 → 不安全，密码泄露后别人可以随便用
- 方案B：使用Service Account → 安全，程序使用特定身份访问，可以精确控制权限

**Service Account的本质：**
- 不是给"人"用的，而是给"程序"或"机器"用的账号
- 相当于给服务器/容器/函数一个"身份证"
- 可以精确控制这个"身份证"能做什么、不能做什么

```
服务账号工作原理：

┌─────────────────────────────────────────────────────────────────────────┐
│                        Service Account工作流程                           │
│                                                                         │
│  1. 创建Service Account                                                │
│     ┌─────────────────────────────────────────────────────────────┐    │
│     │  名称: my-app-sa                                             │    │
│     │  邮箱: my-app-sa@project.iam.gserviceaccount.com           │    │
│     │  用途: 应用程序访问GCS                                       │    │
│     └─────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  2. 赋予权限 (IAM Role)                                                │
│     ┌─────────────────────────────────────────────────────────────┐    │
│     │  给 my-app-sa 赋予 "Storage Object Viewer" 角色           │    │
│     │  (只读GCS对象的权限)                                        │    │
│     └─────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  3. 应用使用Service Account                                            │
│     ┌─────────────────────────────────────────────────────────────┐    │
│     │  应用运行时                                                   │    │
│     │  1. 自动获取Service Account身份                             │    │
│     │  2. GCP验证身份                                              │    │
│     │  3. 检查是否有权限                                           │    │
│     │  4. 允许/拒绝访问                                            │    │
│     └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

**三种获取Service Account凭证的方式：**

1. **密钥文件**（传统方式）：
```bash
# 下载密钥文件
gcloud iam service-accounts keys create key.json \
    --iam-account=my-sa@project.iam.gserviceaccount.com

# 设置环境变量
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\key.json"
```

2. **Workload Identity**（推荐方式，GKE/Cloud Run）：
```yaml
# 给K8s ServiceAccount绑定GCP Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
---
apiVersion: v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app
```

3. **默认Service Account**（默认选项）：
- GCE VM默认使用 "Compute Engine default service account"
- 自动获得一定权限，但生产环境建议创建专用的

---

## 3. GCP架构体系

### 3.1 GCP全球基础设施

```
GCP全球基础设施

┌─────────────────────────────────────────────────────────────────────────┐
│                          GCP 全球区域分布                                 │
│                                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   美洲      │  │   欧洲      │  │   亚太      │  │   中东      │   │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤  ├─────────────┤   │
│  │ us-central1 │  │ europe-west1│  │ asia-east1 │  │ me-west1   │   │
│  │ us-east1   │  │ europe-west4│  │ asia-south1│  │ me-central1│   │
│  │ us-west1   │  │ europe-north│  │ asia-northe│  │             │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│                                                                         │
│  Region (区域): 独立的地理区域，包含多个Zone                             │
│  Zone (可用区): 独立的数据中心，同一Region内Zone间延迟<2ms              │
│  Edge Location: CDN边缘节点，全球300+个位置                              │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 GCP服务层次

```
GCP服务层次

┌─────────────────────────────────────────────────────────────────────────┐
│                           应用层 (SaaS)                                  │
│  Workspace (Docs, Sheets, Slides), Gmail, Google Maps API              │
├─────────────────────────────────────────────────────────────────────────┤
│                           平台层 (PaaS)                                  │
│  Cloud Run, App Engine, Cloud Functions, GKE, Cloud SQL                │
├─────────────────────────────────────────────────────────────────────────┤
│                           基础设施层 (IaaS)                              │
│  Compute Engine, Cloud Storage, Cloud VPC, Cloud Load Balancing         │
├─────────────────────────────────────────────────────────────────────────┤
│                           基础层                                         │
│  物理硬件、网络、存储设备                                               │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. GCP核心服务

### 4.1 计算服务家族

```
GCP计算服务

┌─────────────────────────────────────────────────────────────────────────┐
│                           计算服务对比                                    │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │  Compute Engine │    │    Cloud Run    │    │   Cloud Func    │    │
│  │  (虚拟机)       │    │  (容器服务)      │    │  (无服务器函数) │    │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤    │
│  │ 完全控制        │    │ 容器化应用       │    │ 事件驱动        │    │
│  │ 灵活配置        │    │ 自动扩缩        │    │ 按调用付费      │    │
│  │ 适合迁移        │    │ 无服务器体验    │    │ 快速构建        │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │       GKE       │    │   App Engine    │    │    Vertex AI    │    │
│  │ (Kubernetes)   │    │   (PaaS平台)    │    │   (AI/ML平台)  │    │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤    │
│  │ 容器编排        │    │ 完全托管        │    │ 机器学习        │    │
│  │ 自动运维        │    │ 自动扩缩        │    │ 预训练模型      │    │
│  │ 多云支持        │    │ 多种语言        │    │ MLOps支持       │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 存储服务家族

```
GCP存储服务

┌─────────────────────────────────────────────────────────────────────────┐
│                           存储服务对比                                    │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │ Cloud Storage   │    │   Cloud SQL     │    │    Firestore    │    │
│  │ (对象存储)      │    │ (关系型数据库)  │    │  (NoSQL文档)    │    │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤    │
│  │ 静态网站托管    │    │ MySQL/PostgreSQL│    │ 实时同步        │    │
│  │ CDN集成        │    │ 自动备份        │    │ 离线支持        │    │
│  │ 版本控制       │    │ 高可用          │    │ 脱机支持        │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │     BigQuery    │    │   Cloud Spanner │    │    Bigtable     │    │
│  │  (数据仓库)     │    │  (全球分布式SQL)│    │   (时序数据库)  │    │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤    │
│  │ PB级分析        │    │ 全球强一致性     │    │ 高吞吐写入      │    │
│  │ SQL查询        │    │ 99.999%可用性    │    │ 低延迟读取      │    │
│  │ 机器学习集成   │    │ 水平扩展        │    │ AD/CT/Ml工作负载│   │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. GCP开发环境 - Windows系统详细指南

### 5.1 安装Google Cloud SDK（Windows）

**为什么需要gcloud CLI？**
- gcloud是GCP的官方命令行工具
- 可以完成Web控制台能做的所有事情
- 适合自动化脚本和CI/CD流水线
- 比Web控制台更高效

**Windows安装步骤：**

```
方法1：使用安装程序（推荐新手）

1. 下载GoogleCloudSDKInstaller.exe
   访问: https://cloud.google.com/sdk/docs/install-windows

2. 双击运行安装程序

3. 按照向导完成安装
   - 选择安装目录
   - 选择是否安装Buntools（推荐安装）
   - 选择是否设置PATH环境变量（勾选）

4. 安装完成后，打开新的PowerShell或CMD
   运行: gcloud version

方法2：使用PowerShell（适合高级用户）

# 使用 winget 安装（推荐）
winget install GoogleCloudSDK

# 或使用 Chocolatey
choco install google-cloud-sdk
```

### 5.2 初始化gcloud

**安装完成后，必须执行的初始化步骤：**

```powershell
# 打开PowerShell或CMD，运行以下命令

# 1. 初始化gcloud（会打开浏览器让你登录）
gcloud init

# 2. 如果在中国大陆，可能需要设置代理
# 方法：设置环境变量
$env:HTTP_PROXY="http://your-proxy:port"
$env:HTTPS_PROXY="http://your-proxy:port"

# 3. 登录（打开浏览器）
gcloud auth login

# 4. 列出当前登录的账户
gcloud auth list

# 5. 设置默认项目（替换为你的项目ID）
gcloud config set project YOUR_PROJECT_ID

# 6. 设置默认区域和可用区
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# 7. 查看当前配置
gcloud config list

# 8. 安装额外组件（kubectl等）
gcloud components install kubectl
gcloud components update
```

**常见问题：**

```
问题1：gcloud命令找不到
解决：重新打开PowerShell，确保SDK安装目录在PATH中

问题2：认证失败
解决：运行 gcloud auth login 重新登录

问题3：项目不存在
解决：运行 gcloud projects list 确认项目ID正确
```

### 5.3 Python开发环境配置

```powershell
# 1. 检查Python是否已安装
python --version

# 2. 如果没有，安装Python
# 下载: https://www.python.org/downloads/
# 安装时勾选 "Add Python to PATH"

# 3. 安装GCP Python客户端库
pip install google-cloud-storage
pip install google-cloud-bigquery
pip install google-cloud-logging
pip install google-cloud-secret-manager

# 4. 安装所有依赖（requirements.txt）
pip install -r requirements.txt
```

---

## 6. Hands-On: 第一个GCP应用

### 6.1 创建第一个项目（详细步骤）

```powershell
# ========== 第一步：创建项目 ==========

# 方法1：使用gcloud命令
# 项目ID必须全局唯一，建议使用公司缩写+项目名
gcloud projects create my-first-gcp-project-12345 --name="My First Project"

# 方法2：先设置当前项目（如果项目已存在）
# 直接设置当前项目
gcloud config set project YOUR_PROJECT_ID

# ========== 第二步：启用必要的API ==========

# GCP的API默认是关闭的，需要手动启用
# 就像你要用某个功能，需要先"打开"它

# 启用Compute Engine API（虚拟机）
gcloud services enable compute.googleapis.com

# 启用Cloud Storage API
gcloud services enable storage.googleapis.com

# 启用Cloud Functions API
gcloud services enable cloudfunctions.googleapis.com

# 启用BigQuery API
gcloud services enable bigquery.googleapis.com

# 查看所有可用的服务
gcloud services list --available | Select-String "compute"
```

### 6.2 创建虚拟机实例

**什么是虚拟机？**
虚拟机就是在云上运行的"电脑"。你可以远程控制它，就像控制一台物理电脑一样。

**为什么需要虚拟机？**
- 完全控制：可以安装任何软件，配置任何环境
- 灵活：可以随时调整配置（CPU、内存）
- 可重现：随时可以创建相同配置的机器

```powershell
# ========== 创建虚拟机 ==========

# 基本创建命令
# 说明：
#   my-first-vm    : 虚拟机名称
#   --zone         : 创建在哪个数据中心
#   --machine-type : 虚拟机配置（CPU和内存）
#   --image-family : 操作系统镜像

gcloud compute instances create my-first-vm `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB

# ========== 自定义配置创建 ==========

# 创建带SSH密钥的虚拟机
gcloud compute instances create my-secure-vm `
    --zone=us-central1-a `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=50GB `
    --boot-disk-type=pd-ssd `
    --tags=http-server,https-server `
    --metadata=startup-script='#!/bin/bash
echo "Hello from GCP" > /var/www/html/index.html'

# ========== 查看和管理虚拟机 ==========

# 列出所有虚拟机
gcloud compute instances list

# 查看虚拟机详情
gcloud compute instances describe my-first-vm --zone=us-central1-a

# 启动虚拟机
gcloud compute instances start my-first-vm --zone=us-central1-a

# 停止虚拟机
gcloud compute instances stop my-first-vm --zone=us-central1-a

# 删除虚拟机
gcloud compute instances delete my-first-vm --zone=us-central1-a
```

### 6.3 使用Python SDK访问GCP

```powershell
# 安装Python SDK
pip install google-cloud-storage google-cloud-bigquery
```

```python
# main.py - GCP Python示例
"""
这个示例展示如何使用Python访问GCP服务
"""

from google.cloud import storage
from google.cloud import bigquery
import os

# ============================================================
# 原理说明：
# GCP SDK会自动读取环境变量 GOOGLE_APPLICATION_CREDENTIALS
# 或者从元数据服务器获取凭证（如果在GCP虚拟机上运行）
# ============================================================

PROJECT_ID = os.environ.get('GCP_PROJECT', 'your-project-id')

def list_buckets():
    """
    列出所有Cloud Storage存储桶
    
    原理：
    - Cloud Storage是对象存储，用于存储文件
    - 存储桶是存储文件的"容器"
    - 每个存储桶有全球唯一的名称
    """
    print("\n" + "="*50)
    print("列出Cloud Storage存储桶")
    print("="*50)
    
    storage_client = storage.Client(project=PROJECT_ID)
    buckets = storage_client.list_buckets()
    
    if not buckets:
        print("没有找到存储桶")
        return
    
    print(f"找到 {len(list(buckets))} 个存储桶：")
    for bucket in buckets:
        print(f"  - {bucket.name}")
        print(f"    位置: {bucket.location}")
        print(f"    存储类: {bucket.storage_class}")

def create_bucket():
    """
    创建新的存储桶
    
    为什么需要存储桶？
    - 存储文件、图片、视频
    - 托管静态网站
    - 作为备份存储
    - 数据湖的存储层
    """
    print("\n" + "="*50)
    print("创建新的存储桶")
    print("="*50)
    
    storage_client = storage.Client(project=PROJECT_ID)
    
    # 存储桶名称必须全局唯一
    bucket_name = "my-new-bucket-demo-12345"
    
    try:
        bucket = storage_client.bucket(bucket_name)
        bucket.location = "US"  # 存储桶的物理位置
        bucket.create()
        print(f"✓ 存储桶 '{bucket_name}' 创建成功！")
    except Exception as e:
        print(f"✗ 创建失败: {e}")

def upload_file(bucket_name, source_file, destination_blob):
    """
    上传文件到GCS
    
    原理：
    - GCS使用"对象"概念存储文件
    - 每个对象由"桶名+路径"唯一标识
    - 支持版本控制、生命周期管理等高级功能
    """
    print("\n" + "="*50)
    print(f"上传文件到 {bucket_name}")
    print("="*50)
    
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob)
    
    # 上传文件
    blob.upload_from_filename(source_file)
    print(f"✓ 文件 '{source_file}' 上传到 '{destination_blob}'")

def query_bigquery():
    """
    查询BigQuery
    
    为什么使用BigQuery？
    - 传统数据库适合事务处理（OLTP）
    - BigQuery适合分析处理（OLAP）
    - 可以处理TB/PB级别的数据
    - 使用标准SQL语法
    """
    print("\n" + "="*50)
    print("查询BigQuery公开数据集")
    print("="*50)
    
    client = bigquery.Client()
    
    # 查询美国名字的公开数据集
    query = """
        SELECT 
            name, 
            count as total_count,
            state
        FROM `bigquery-public-data.usa_names.usa_1910_2013` 
        WHERE state = 'CA'
        ORDER BY count DESC 
        LIMIT 10
    """
    
    query_job = client.query(query)
    results = query_job.result()
    
    print("\n加州最常见的10个名字：")
    print("-" * 40)
    for row in results:
        print(f"  {row.name}: {row.total_count} 次 ({row.state})")

def main():
    """主函数"""
    print("\n" + "="*60)
    print("GCP Python SDK 示例程序")
    print("="*60)
    
    # 确保凭证已配置
    print("\n检查凭证配置...")
    print(f"项目ID: {PROJECT_ID}")
    print(f"凭证路径: {os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', '使用默认凭证')}")
    
    # 执行操作
    try:
        list_buckets()
    except Exception as e:
        print(f"列出存储桶时出错: {e}")
    
    # 取消注释以测试创建（注意：会创建真实资源，可能产生费用）
    # create_bucket()
    
    # 取消注释以测试BigQuery
    try:
        query_bigquery()
    except Exception as e:
        print(f"查询BigQuery时出错: {e}")

if __name__ == '__main__':
    main()
```

### 6.4 部署Cloud Function

```powershell
# ========== 创建Cloud Function ==========

# Cloud Function = 无服务器函数
# 为什么使用Cloud Function？
# - 只在调用时运行，没调用不收费
# - 无需管理服务器
# - 自动扩缩

# 1. 创建函数目录
New-Item -ItemType Directory -Force -Path "my-function"
Set-Location my-function

# 2. 创建Python函数文件
@"
import os
from datetime import datetime

def hello_world(request):
    \"\"\"HTTP触发的Cloud Function\"\"\"
    
    # 获取请求信息
    request_json = request.get_json(silent=True)
    
    # 返回响应
    return {
        'message': 'Hello from Cloud Function!',
        'input': request_json,
        'timestamp': datetime.utcnow().isoformat(),
        'region': os.environ.get('FUNCTION_REGION', 'unknown')
    }
"@ | Out-File -FilePath main.py -Encoding utf8

# 3. 创建依赖文件
"google-cloud-logging==3.6.0" | Out-File -FilePath requirements.txt -Encoding utf8

# 4. 部署函数
gcloud functions deploy hello_world `
    --runtime python311 `
    --trigger-http `
    --allow-unauthenticated `
    --region us-central1

# 5. 测试调用
gcloud functions call hello_world `
    --region us-central1 `
    --data '{\"name\":\"GCP Learner\"}'

# 6. 查看日志
gcloud functions logs read hello_world --region us-central1 --limit 50
```

---

## 7. GCP计费管理

### 7.1 计费模型详解

**为什么GCP要收费？**
- GCP需要维护全球数据中心
- 提供7x24小时的技术支持
- 持续研发新功能和改进性能
- 提供SLA保证

```
GCP计费核心概念

按需付费 (On-Demand)
├── 按秒/按毫秒计费
├── 无最低费用
├── 适合可变工作负载
└── 价格示例: e2-medium 约 $0.034/小时

承诺使用折扣 (Committed Use)
├── 1年或3年承诺
├── 最高57%折扣
├── 适合稳定工作负载
└── 适合可预测的工作负载

使用折扣 (Sustained Use)
├── 月度使用超过一定程度自动应用
├── 无需承诺
└── 无需申请

抢占式虚拟机 (Preemptible VM)
├── 最高80%折扣
├── 可能被抢占（最长24小时）
├── 适合批处理/容错工作负载
└── 价格示例: e2-medium 约 $0.008/小时
```

### 7.2 预算告警配置

```powershell
# ========== 创建预算告警 ==========

# 计费账户ID获取方法：
# 1. 访问 https://console.cloud.google.com/billing
# 2. 点击你的计费账户
# 3. 在URL中找到计费账户ID，例如: 00ABCD-123456-789ABC

# 创建预算（设置每月预算1000美元）
gcloud billing budgets create `
    --billing-account=YOUR_BILLING_ACCOUNT_ID `
    --display-name="Monthly Budget" `
    --amount=1000USD `
    --threshold-rule=percent=0.5,threshold=500USD `
    --threshold-rule=percent=0.8,threshold=800USD `
    --threshold-rule=percent=1.0,threshold=1000USD

# 查看预算
gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT_ID

# 查看详细预算信息
gcloud billing budgets describe --budget=budgets/YOUR_BUDGET_ID --billing-account=YOUR_BILLING_ACCOUNT_ID
```

---

## 8. Windows PowerShell命令速查

### 8.1 项目管理

```powershell
# ============================================================
# 项目管理命令
# ============================================================

# 列出所有可访问的项目
gcloud projects list

# 创建新项目
gcloud projects create PROJECT_ID --name="项目名称"

# 设置当前项目
gcloud config set project PROJECT_ID

# 查看当前项目
gcloud config get-value project

# 删除项目（需要先停用）
gcloud projects delete PROJECT_ID
```

### 8.2 认证和授权

```powershell
# ============================================================
# 认证管理命令
# ============================================================

# 登录（交互式，会打开浏览器）
gcloud auth login

# 列出已登录账户
gcloud auth list

# 当前激活的账户
gcloud auth print-identity-token

# 退出登录
gcloud auth revoke ACCOUNT_EMAIL

# 应用默认凭证（用于本地开发）
# 注意：在生产环境应该使用Service Account
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\credentials.json"
```

### 8.3 服务启用

```powershell
# ============================================================
# 服务/API管理命令
# ============================================================

# 列出已启用的服务
gcloud services list --enabled

# 列出可用的服务
gcloud services list --available

# 启用服务
gcloud services enable SERVICE_NAME.googleapis.com

# 禁用服务
gcloud services disable SERVICE_NAME.googleapis.com

# 常用服务名称
# - compute.googleapis.com (Compute Engine)
# - storage.googleapis.com (Cloud Storage)
# - bigquery.googleapis.com (BigQuery)
# - cloudfunctions.googleapis.com (Cloud Functions)
# - run.googleapis.com (Cloud Run)
# - container.googleapis.com (GKE)
# - sqladmin.googleapis.com (Cloud SQL)
# - pubsub.googleapis.com (Pub/Sub)
# - logging.googleapis.com (Cloud Logging)
# - monitoring.googleapis.com (Cloud Monitoring)
```

### 8.4 配置管理

```powershell
# ============================================================
# gcloud配置命令
# ============================================================

# 查看当前配置
gcloud config list

# 设置默认区域
gcloud config set compute/region REGION

# 设置默认区域
gcloud config set compute/zone ZONE

# 查看配置项
gcloud config get-value compute/region

# 创建新配置
gcloud config configurations create CONFIG_NAME

# 切换配置
gcloud config configurations activate CONFIG_NAME

# 列出所有配置
gcloud config configurations list
```

---

## 9. 知识检测

### 选择题

1. GCP的最小管理单元是什么？
   - A. Zone
   - B. Region
   - C. Project ✓
   - D. Folder

2. Service Account的主要用途是什么？
   - A. 给开发人员登录使用
   - B. 给程序/机器使用的身份凭证 ✓
   - C. 给客户使用
   - D. 给管理员使用

3. Region和Zone的关系是什么？
   - A. 一个Region包含多个Zone ✓
   - B. 一个Zone包含多个Region
   - C. Region和Zone是独立的
   - D. 没有关系

4. Cloud Storage最适合存储什么类型的数据？
   - A. 结构化数据
   - B. 对象文件（图片、视频、文档） ✓
   - C. 时序数据
   - D. 图数据

---

## 10. 扩展阅读

- [GCP官方文档](https://cloud.google.com/docs)
- [Qwiklabs GCP教程](https://www.qwiklabs.com/catalog?keywords=google+cloud)
- [Google Cloud Skills Boost](https://www.cloudskillsboost.google/)
- [GCP定价计算器](https://cloud.google.com/products/calculator)
- [GCP免费套餐](https://cloud.google.com/free)

---

## 学习进度

- [ ] 理解GCP架构体系
- [ ] 掌握GCP核心服务
- [ ] 理解Service Account原理
- [ ] 学会gcloud CLI
- [ ] 配置开发环境
- [ ] 完成第一个GCP应用
- [ ] 理解GCP计费模型
