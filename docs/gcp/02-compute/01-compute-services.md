# GCP计算服务

## 本章概述

GCP提供多种计算服务以满足不同场景需求。本章从原理出发，详细讲解每种计算服务的适用场景、底层原理，以及在Windows环境下的操作方法。通过本章学习，你将能够根据业务需求选择最合适的计算服务，并掌握实际操作技能。

## 学习目标

- 掌握Compute Engine虚拟机的原理和操作
- 深入理解GKE Kubernetes集群的管理
- 掌握Cloud Run无服务器容器的使用
- 理解服务选择策略和场景分析
- 能够在Windows环境下完成所有操作

---

## 1. 深入理解计算服务家族

### 1.1 为什么GCP提供这么多种计算服务？

在深入学习具体服务之前，我们需要理解一个根本问题：**为什么需要这么多不同的计算服务？**

**核心原因：不同的工作负载需要不同的计算模型**

```
工作负载类型与计算服务匹配

┌─────────────────────────────────────────────────────────────────────────┐
│                    计算服务选择矩阵                                       │
│                                                                         │
│  工作负载类型              推荐服务          关键优势                    │
│  ─────────────────────────────────────────────────────────────────────  │
│                                                                         │
│  长时间运行的服务器         Compute Engine    完全控制，灵活配置          │
│  │                                                                     │
│  ├── 传统Web应用           │                便于迁移遗留应用             │
│  ├── 数据库服务器          │                可运行任意软件              │
│  └── 批处理任务            │                完全root权限               │
│                                                                         │
│  容器化微服务              Cloud Run        简单高效，自动扩缩            │
│  │                                                                     │
│  ├── REST API             │                只需关注代码                 │
│  ├── 后端服务              │                按请求数付费                │
│  └── 事件驱动应用          │                零基础设施管理              │
│                                                                         │
│  Kubernetes工作负载        GKE              强大的容器编排                │
│  │                                                                     │
│  ├── 复杂微服务架构        │                丰富的K8s生态                │
│  ├── 需要精细控制          │                多云/混合云支持             │
│  └── 需要高级调度          │                高度可定制                   │
│                                                                         │
│  事件驱动函数              Cloud Functions  最极致的Serverless          │
│  │                                                                     │
│  ├── Webhook处理          │                按调用次数计费              │
│  ├── 数据处理管道          │                事件触发                    │
│  └── 轻量级后台任务        │                毫秒级启动                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Compute Engine虚拟机 - 原理详解

**什么是虚拟机？**

虚拟机(VM)是物理服务器的虚拟化模拟。你可以把它理解为在云上运行的"电脑"，这台电脑有自己独立的CPU、内存、硬盘、网络，你可以远程登录、安装软件、运行服务。

**为什么需要虚拟机？**

```
虚拟机 vs 其他计算服务

┌─────────────────────────────────────────────────────────────────────────┐
│                        虚拟机的独特价值                                  │
│                                                                         │
│  1. 完全控制权                                                          │
│     ├── 可以安装任意操作系统                                            │
│     ├── 可以安装任意软件                                                │
│     ├── 可以修改内核参数                                                │
│     └── root/管理员权限                                                │
│                                                                         │
│  2. 灵活的配置选项                                                      │
│     ├── CPU: 1核到416核任意选择                                        │
│     ├── 内存: 0.6GB到8TB                                              │
│     ├── 磁盘: HDD/SSD，本地/网络                                        │
│     └── GPU: 可选配NVIDIA T4/V100/A100                                 │
│                                                                         │
│  3. 便于迁移                                                            │
│     ├── 现有应用可以直接迁移                                            │
│     ├── 无需重构代码                                                    │
│     └── 可以运行遗留系统                                                │
│                                                                         │
│  适用场景：                                                             │
│  - 传统Web应用服务器                                                   │
│  - 数据库服务器                                                        │
│  - 需要特殊软件的企业应用                                               │
│  - 批处理和计算密集型任务                                               │
│  - 开发/测试环境                                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.3 实例类型详解 - 如何选择正确的配置

**为什么虚拟机有这么多类型？**

因为不同工作负载对资源的需求不同：
- Web服务器：需要均衡的CPU和内存
- 数据库：需要大量内存和快速磁盘
- AI训练：需要GPU加速
- 开发测试：需要低成本

```
Compute Engine实例类型

┌─────────────────────────────────────────────────────────────────────────┐
│                           实例家族                                       │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐      │
│  │    通用型 (E/N)  │    │   计算优化型 (C) │    │  内存优化型 (M)  │      │
│  ├─────────────────┤    ├─────────────────┤    ├─────────────────┤      │
│  │ E2: 经济实惠    │    │ C2: 极致性能    │    │ M2: 超大内存    │      │
│  │ N2: 均衡        │    │ C2D: AMD EPYC  │    │ M1: 大内存      │      │
│  │ N1: 标准        │    │ T2D: AMD       │    │ M3: 平衡        │      │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘      │
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐                            │
│  │  GPU优化型 (G/L) │    │  加速器优化      │                            │
│  ├─────────────────┤    ├─────────────────┤                            │
│  │ G2: NVIDIA L4   │    │ A2: GPU优化     │                            │
│  │ T4: 推理优化   │    │ H1: 内存带宽    │                            │
│  │ V100: 训练     │    │                 │                            │
│  └─────────────────┘    └─────────────────┘                            │
└─────────────────────────────────────────────────────────────────────────┘

实例命名规则：
  [家族][代数]-[CPU数量]-[内存]
  例: n2-standard-4
     ├── n2: 第二代通用型
     ├── standard: 标准类型
     └── 4: 4个vCPU

常见配置示例：
  e2-medium  = 2 vCPU, 4 GB 内存   (约$0.034/小时，最便宜)
  n2-standard-4 = 4 vCPU, 16 GB 内存
  n2-standard-8 = 8 vCPU, 32 GB 内存
  c2-standard-16 = 16 vCPU, 64 GB 内存 (最高性能)
  m2-megamem-416 = 416 vCPU, 8 TB 内存 (最大内存)
```

---

## 2. Compute Engine深度实践 - Windows PowerShell命令

### 2.1 虚拟机创建的原理分析

```
创建虚拟机的底层原理：

┌─────────────────────────────────────────────────────────────────────────┐
│                    虚拟机创建流程                                        │
│                                                                         │
│  1. 用户发起创建请求                                                    │
│     └── gcloud compute instances create ...                            │
│                                                                         │
│  2. GCP控制器分配资源                                                  │
│     ├── 从选定Zone分配IP地址                                            │
│     ├── 从可用存储分配磁盘空间                                          │
│     └── 选择物理服务器                                                  │
│                                                                         │
│  3. 创建虚拟化层                                                        │
│     ├── 在物理服务器上创建虚拟交换机                                   │
│     ├── 分配vCPU和内存                                                  │
│     └── 配置启动磁盘                                                    │
│                                                                         │
│  4. 启动虚拟机                                                          │
│     ├── 从镜像启动                                                      │
│     ├── 运行启动脚本（如果指定）                                        │
│     └── 配置SSH密钥                                                    │
│                                                                         │
│  5. 返回结果                                                            │
│     └── 返回IP地址、状态等信息                                          │
│                                                                         │
│  整个过程通常在30-60秒内完成                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 虚拟机创建命令 - Windows PowerShell详解

```powershell
# ============================================================
# Windows PowerShell GCP Compute Engine命令
# ============================================================

# ========== 基本概念说明 ==========

# 在Windows PowerShell中使用反引号 ` 进行换行
# 这相当于Linux中的反斜杠 \

# ========== 1. 基础虚拟机创建 ==========

# 说明：以下命令参数详解
#   my-first-vm    : 虚拟机名称（必须唯一）
#   --zone         : 数据中心位置（影响延迟和价格）
#   --machine-type : 虚拟机规格（CPU和内存）
#   --image-family : 操作系统镜像（类似ISO）
#   --image-project : 镜像来源项目
#   --boot-disk-size: 启动盘大小

gcloud compute instances create my-first-vm `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB

# ========== 2. 自定义配置创建 ==========

# 创建Ubuntu虚拟机（常用）
gcloud compute instances create ubuntu-vm `
    --zone=us-central1-a `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=50GB `
    --boot-disk-type=pd-ssd

# ========== 3. 带启动脚本的虚拟机 ==========

# 启动脚本的作用：
# - 自动安装软件
# - 配置环境
# - 拉取代码
# - 避免手动配置

# 创建启动脚本文件
$startupScript = @"
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "Hello from GCP VM - Created at $(date)" > /var/www/html/index.html
systemctl restart nginx
"@

# 保存到文件
$startupScript | Out-File -FilePath startup.sh -Encoding utf8

# 使用启动脚本创建虚拟机
gcloud compute instances create web-server `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --metadata-from-file startup-script=startup.sh

# ========== 4. Windows虚拟机 ==========

# Windows虚拟机需要特殊处理
# - 使用Windows镜像
# - 需要设置初始密码
# - 使用RDP连接

# 创建Windows虚拟机
gcloud compute instances create windows-vm `
    --zone=us-central1-a `
    --machine-type=n2-standard-4 `
    --image-family=windows-2022 `
    --image-project=windows-cloud `
    --boot-disk-size=100GB `
    --boot-disk-type=pd-ssd

# 生成Windows密码
gcloud compute reset-windows-password windows-vm `
    --zone=us-central1-a `
    --user=admin

# ========== 5. 抢占式虚拟机（降低成本80%） ==========

# 抢占式虚拟机的原理：
# - GCP的闲置资源出售
# - 价格极低（最多80%折扣）
# - 随时可能被终止（最长24小时）
# - 适合容错工作负载

gcloud compute instances create spot-vm `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --preemptible `
    --image-family=debian-11 `
    --maintenance-policy=TERMINATE

# ========== 6. 带GPU的虚拟机 ==========

# GPU虚拟机的用途：
# - 深度学习训练
# - 图形渲染
# - 视频转码
# - 科学计算

gcloud compute instances create gpu-vm `
    --zone=us-central1-a `
    --machine-type=n1-standard-8 `
    --accelerator=type=nvidia-tesla-v100,count=2 `
    --image-family=pytorch-latest-gpu `
    --image-project=deeplearning-platform-release `
    --boot-disk-size=100GB `
    --boot-disk-type=pd-ssd

# ========== 7. 自定义机器类型 ==========

# 当预设类型不满足需求时使用
# 可以精确配置vCPU和内存组合

gcloud compute instances create custom-vm `
    --zone=us-central1-a `
    --machine-type=n2-custom-4-4096 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud

# 说明：n2-custom-4-4096 = 4 vCPU, 4096 MB (4GB) 内存
```

### 2.3 虚拟机管理命令

```powershell
# ============================================================
# 虚拟机管理命令
# ============================================================

# ========== 查看和列表操作 ==========

# 列出所有虚拟机（当前项目）
gcloud compute instances list

# 列出特定区域的虚拟机
gcloud compute instances list --filter="zone:us-central1-a"

# 查看虚拟机详细信息
gcloud compute instances describe my-first-vm --zone=us-central1-a

# 查看虚拟机IP地址
gcloud compute instances describe my-first-vm --zone=us-central1-a `
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

# ========== 启动和停止操作 ==========

# 启动虚拟机
gcloud compute instances start my-first-vm --zone=us-central1-a

# 停止虚拟机（停止计费，但磁盘仍收费）
gcloud compute instances stop my-first-vm --zone=us-central1-a

# 重启虚拟机
gcloud compute instances reset my-first-vm --zone=us-central1-a

# ========== 远程连接 ==========

# SSH连接（Linux）
gcloud compute ssh my-first-vm --zone=us-central1-a

# SSH带特定用户
gcloud compute ssh user@my-first-vm --zone=us-central1-a

# 远程桌面（RDP）- Windows虚拟机
gcloud compute instances get-windows-password windows-vm `
    --zone=us-central1-a

# ========== 修改操作 ==========

# 调整机器类型（需要先停止虚拟机）
gcloud compute instances set-machine-type my-first-vm `
    --zone=us-central1-a `
    --machine-type=n2-standard-8

# 添加标签
gcloud compute instances add-tags my-first-vm `
    --zone=us-central1-a `
    --tags=http-server,https-server

# 添加元数据
gcloud compute instances add-metadata my-first-vm `
    --zone=us-central1-a `
    --metadata=env=production,team=backend

# ========== 删除操作 ==========

# 删除虚拟机（注意：会删除关联的启动磁盘）
gcloud compute instances delete my-first-vm --zone=us-central1-a

# 强制删除（不询问确认）
gcloud compute instances delete my-first-vm --zone=us-central1-a --quiet

# ========== 磁盘操作 ==========

# 创建新磁盘
gcloud compute disks create my-disk `
    --zone=us-central1-a `
    --size=50GB `
    --type=pd-ssd

# 将磁盘附加到虚拟机
gcloud compute instances attach-disk my-first-vm `
    --zone=us-central1-a `
    --disk=my-disk `
    --mode=rw

# 从虚拟机分离磁盘
gcloud compute instances detach-disk my-first-vm `
    --zone=us-central1-a `
    --disk=my-disk

# 调整磁盘大小
gcloud compute disks resize my-disk `
    --zone=us-central1-a `
    --size=100GB
```

### 2.4 启动脚本深度解析

**为什么需要启动脚本？**

想象一下：你需要创建100台Web服务器。手动一台台配置会累死，而且容易出错。启动脚本让每台机器自动完成配置，保证一致性。

```powershell
# ============================================================
# 启动脚本实战
# ============================================================

# 方案1：内联启动脚本（简单场景）
# 适用于：安装简单软件、快速测试

gcloud compute instances create web-server `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx php-fpm
systemctl enable nginx
systemctl start nginx
echo "Web Server Ready" > /var/www/html/index.html'

# 方案2：外部启动脚本文件（复杂场景）
# 适用于：复杂配置、需要版本控制

# 创建完整的启动脚本
$scriptContent = @"
#!/bin/bash
set -e

echo "========== 开始配置Web服务器 =========="
echo "时间: $(date)"

# 更新系统
echo "1. 更新系统包..."
apt-get update -y

# 安装Nginx
echo "2. 安装Nginx..."
apt-get install -y nginx

# 安装PHP
echo "3. 安装PHP..."
apt-get install -y php-fpm php-mysql

# 配置Nginx
echo "4. 配置Nginx..."
cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

# 启动服务
echo "5. 启动服务..."
systemctl restart nginx
systemctl restart php-fpm

# 创建测试页面
echo "6. 创建测试页面..."
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>GCP Web Server</title>
</head>
<body>
    <h1>Web Server is Ready!</h1>
    <p>Created at: HTML
    echo $(date) >> /var/www/html/index.html
    echo "</p></body></html>" >> /var/www/html/index.html

echo "========== 配置完成 =========="
"@

# 保存脚本
$scriptContent | Out-File -FilePath startup.sh -Encoding utf8

# 使用脚本创建虚拟机
gcloud compute instances create configured-web `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --metadata-from-file startup-script=startup.sh

# 方案3：使用云存储存储启动脚本（大规模场景）
# 适用于：脚本很大、需要共享、经常更新

# 1. 先上传脚本到GCS
gsutil cp startup.sh gs://your-bucket/scripts/

# 2. 让虚拟机从GCS下载并执行
gcloud compute instances create web-from-gcs `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --metadata=startup-script='#!/bin/bash
gsutil cp gs://your-bucket/scripts/startup.sh /tmp/
bash /tmp/startup.sh'

# 查看启动日志（排查问题）
gcloud compute instances get-serial-port-output my-first-vm --zone=us-central1-a
```

### 2.5 实例组和自动扩缩容

**为什么需要实例组？**

单台虚拟机有单点故障风险。实例组可以：
- 多台机器同时运行
- 自动健康检查
- 自动替换故障机器
- 自动扩缩容

```powershell
# ============================================================
# 实例组和自动扩缩容
# ============================================================

# ========== 1. 创建实例模板 ==========

# 实例模板 = 虚拟机的"模具"
# 定义：用什么样的镜像、什么样的配置创建虚拟机

gcloud compute instance-templates create web-template `
    --machine-type=e2-medium `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=20GB `
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx
echo "Hello from Instance Group - $(hostname)" > /var/www/html/index.html
systemctl start nginx'

# 查看实例模板
gcloud compute instance-templates list

# ========== 2. 创建托管实例组 ==========

# 托管实例组 (Managed Instance Group, MIG)
# - 自动维护指定数量的实例
# - 自动替换不健康的实例
# - 支持自动扩缩

# 区域级托管实例组（推荐）
gcloud compute instance-groups managed create web-mig `
    --region=us-central1 `
    --size=3 `
    --template=web-template

# ========== 3. 配置自动扩缩 ==========

# 自动扩缩原理：
# - 根据CPU使用率/内存/负载均衡器请求数自动调整实例数
# - 设置最小和最大实例数
# - 有冷却时间防止抖动

gcloud compute instance-groups managed set-autoscaling web-mig `
    --region=us-central1 `
    --max-num-replicas=10 `
    --min-num-replicas=2 `
    --target-cpu-utilization=0.7 `
    --cool-down-period=60

# 基于负载均衡器请求数的扩缩
gcloud compute instance-groups managed set-autoscaling web-mig `
    --region=us-central1 `
    --max-num-replicas=10 `
    --min-num-replicas=2 `
    --target-load-balancing-utilization=0.8

# ========== 4. 配置健康检查 ==========

# 健康检查 = 检查实例是否正常工作
# 不健康的实例会被自动替换

# 创建HTTP健康检查
gcloud compute health-checks create http web-health-check `
    --port=80 `
    --request-path=/health `
    --check-interval=10 `
    --timeout=5 `
    --healthy-threshold=2 `
    --unhealthy-threshold=3

# 创建TCP健康检查
gcloud compute health-checks create tcp tcp-health-check `
    --port=80 `
    --check-interval=10 `
    --timeout=5

# 将健康检查附加到实例组
gcloud compute instance-groups managed update-web-mig `
    --region=us-central1 `
    --health-check=web-health-check `
    --initial-delay=120

# ========== 5. 查看和管理实例组 ==========

# 查看实例组
gcloud compute instance-groups managed list

# 查看实例组详情
gcloud compute instance-groups managed describe web-mig --region=us-central1

# 手动调整实例数
gcloud compute instance-groups managed resize web-mig `
    --region=us-central1 `
    --size=5

# 查看实例列表
gcloud compute instance-groups managed list-instances web-mig --region=us-central1
```

---

## 3. GKE Kubernetes集群 - 原理与实践

### 3.1 Kubernetes核心概念

**为什么需要Kubernetes？**

在容器化时代，你需要管理大量容器：
- 容器需要互相通信
- 需要负载均衡
- 需要自动扩缩
- 需要滚动更新
- 需要健康检查

Kubernetes（K8s）就是来解决这些问题的。

```
Kubernetes核心概念图解

┌─────────────────────────────────────────────────────────────────────────┐
│                    Kubernetes架构概览                                   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Control Plane (控制平面)                      │   │
│  │                                                                  │   │
│  │  API Server    ─── 集群的"大脑"，接受所有请求                    │   │
│  │  etcd          ─── 集群的"数据库"，存储所有状态                  │   │
│  │  Scheduler     ─── 决定Pod应该放在哪个节点                        │   │
│  │  Controller    ─── 维护期望状态（如副本数）                       │   │
│  │                                                                  │   │
│  │  ☁️ 由GCP完全托管，高可用                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Node (工作节点)                               │   │
│  │                                                                  │   │
│  │  Kubelet     ─── 节点上的"代理人"，管理容器                      │   │
│  │  Kube-proxy  ─── 网络代理，处理负载均衡                          │   │
│  │  Container Runtime ─── 运行容器（Docker/Containerd）           │   │
│  │                                                                  │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                        │   │
│  │  │  Pod 1  │  │  Pod 2  │  │  Pod 3  │  ← 最小部署单元       │   │
│  │  └─────────┘  └─────────┘  └─────────┘                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  核心资源：                                                            │
│  - Pod: 最小部署单元（1或多个容器）                                    │
│  - Deployment: 管理Pod的声明式更新                                   │
│  - Service: 为Pod提供稳定的网络入口                                    │
│  - Ingress: HTTP/HTTPS路由                                           │
│  - ConfigMap/Secret: 配置管理                                        │
│  - Volume: 持久化存储                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 GKE集群创建

```powershell
# ============================================================
# GKE集群创建和管理 - Windows PowerShell
# ============================================================

# ========== 1. GKE集群类型选择 ==========

# GKE提供两种集群模式：
# - Standard（标准模式）：你管理节点，需要手动扩缩
# - Autopilot（自动驾驶）：GCP自动管理所有节点，按Pod付费

# ========== 2. 创建Standard集群 ==========

# Standard模式 = 自己管理节点池
# 适用：需要精细控制、已知工作负载、成本敏感

gcloud container clusters create my-standard-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --disk-type=pd-ssd `
    --disk-size=100GB `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10 `
    --enable-autorepair `
    --enable-autoupgrade `
    --release-channel=regular

# ========== 3. 创建Autopilot集群 ==========

# Autopilot模式 = 完全托管
# 适用：简化运维、按Pod付费、弹性工作负载

gcloud container clusters create my-autopilot-cluster `
    --region=us-central1 `
    --enable-autopilot

# ========== 4. 高级选项 ==========

# 启用私有集群（节点不暴露公网IP）
gcloud container clusters create private-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --enable-ip-alias `
    --enable-private-nodes `
    --master-ipv4-cidr=10.128.0.0/28

# 启用网络策略
gcloud container clusters create secure-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --enable-network-policy

# 启用Shielded Nodes（安全加固）
gcloud container clusters create shielded-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --enable-shielded-nodes

# ========== 5. 获取凭证和验证 ==========

# 获取集群凭证（配置kubectl）
gcloud container clusters get-credentials my-standard-cluster `
    --zone=us-central1-a

# 验证连接
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看集群信息
gcloud container clusters describe my-standard-cluster --zone=us-central1-a

# ========== 6. 节点池管理 ==========

# 添加节点池
gcloud container node-pools create my-node-pool `
    --cluster=my-standard-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-8

# 查看节点池
gcloud container node-pools list --cluster=my-standard-cluster --zone=us-central1-a

# 自动扩缩节点池
gcloud container node-pools update my-node-pool `
    --cluster=my-standard-cluster `
    --zone=us-central1-a `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=5

# 删除节点池
gcloud container node-pools delete my-node-pool `
    --cluster=my-standard-cluster `
    --zone=us-central1-a
```

### 3.3 Kubernetes资源管理 - 深入解析

**为什么需要Deployment、Service这些概念？**

直接管理容器很麻烦。K8s提供了抽象层：
- Deployment：管理"我要运行几个Pod"
- Service：管理"如何访问这些Pod"
- Ingress：管理HTTP路由

```yaml
# ============================================================
# Kubernetes资源详解
# ============================================================

# ========== 1. Deployment - 应用部署 ==========

# Deployment = 声明式管理Pod
# 告诉K8s：我需要运行3个nginx容器，如果挂了请重启

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
    version: v1
spec:
  # 副本数
  replicas: 3
  
  # 选择器
  selector:
    matchLabels:
      app: my-app
  
  # Pod模板
  template:
    metadata:
      labels:
        app: my-app
        version: v1
    spec:
      containers:
      - name: my-app
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        
        # 资源限制（重要：生产环境必须设置）
        resources:
          requests:
            cpu: 100m        # 100毫核 = 0.1核
            memory: 128Mi   # 128兆字节
          limits:
            cpu: 500m
            memory: 512Mi
        
        # 健康检查 - 存活探针
        # 检查容器是否活着，失败会重启
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        
        # 健康检查 - 就绪探针
        # 检查容器是否准备好接收流量
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # 环境变量
        env:
        - name: NODE_ENV
          value: production
        - name: LOG_LEVEL
          value: info
        
        # 配置挂载
        volumeMounts:
        - name: config
          mountPath: /etc/config
        - name: secret
          mountPath: /etc/secret
          readOnly: true
      
      # 存储卷
      volumes:
      - name: config
        configMap:
          name: my-app-config
      - name: secret
        secret:
          secretName: my-app-secret

---

# ========== 2. Service - 服务发现和负载均衡 ==========

# Service = 稳定的网络入口
# 无论Pod在哪里、是否重启，访问地址不变

apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  labels:
    app: my-app
spec:
  # Service类型
  # - ClusterIP: 仅集群内部访问（默认）
  # - NodePort: 每个节点开放一个端口
  # - LoadBalancer: 使用云负载均衡器
  # - ExternalName: DNS别名
  type: LoadBalancer
  
  selector:
    app: my-app
  
  ports:
  - name: http
    port: 80        # Service端口
    targetPort: 80  # Pod端口
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  
  # 会话亲和性
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800

---

# ========== 3. Ingress - HTTP/HTTPS路由 ==========

# Ingress = HTTP路由
# 基于路径或域名路由到不同的Service

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-secret
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80

---

# ========== 4. ConfigMap - 配置管理 ==========

# ConfigMap = 非敏感配置
# 数据库连接地址、API端点、功能开关等

apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  DATABASE_HOST: "10.0.0.1"
  DATABASE_PORT: "5432"
  API_ENDPOINT: "https://api.example.com"
  LOG_LEVEL: "info"
  FEATURE_NEW_UI: "true"

---

# ========== 5. Secret - 敏感配置 ==========

# Secret = 敏感数据
# 密码、API密钥、证书等

apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
type: Opaque
stringData:
  # Base64编码的值（自动转换）
  database-password: cGFzc3dvcmQxMjM=
  api-key: c2VjcmV0LWtleS0xMjM=
  # 或者直接写（不编码）
  # mysql-root-password: "password123"

---

# ========== 6. HorizontalPodAutoscaler - 自动扩缩 ==========

# HPA = 基于指标的自动扩缩
# 根据CPU/内存使用率自动调整副本数

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

---

# ========== 7. PersistentVolumeClaim - 持久化存储 ==========

# PVC = 持久化存储请求
# 数据不会因Pod重启而丢失

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard-rwo

# 使用PVC
# 在Deployment中添加：
# volumeMounts:
# - name: data
#   mountPath: /var/data
# volumes:
# - name: data
#   persistentVolumeClaim:
#     claimName: my-app-pvc
```

### 3.4 常用kubectl命令速查

```powershell
# ============================================================
# kubectl命令速查 - Windows PowerShell
# ============================================================

# ========== 1. 集群信息 ==========

# 查看集群信息
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看节点详情
kubectl get nodes -o wide

# 查看集群事件
kubectl get events --sort-by='.lastTimestamp'

# ========== 2. Pod管理 ==========

# 查看Pod（所有命名空间）
kubectl get pods -A

# 查看Pod（当前命名空间）
kubectl get pods

# 查看Pod详细信息
kubectl get pods -o wide

# 查看Pod日志
kubectl logs my-app-pod-xxx

# 查看实时日志
kubectl logs -f my-app-pod-xxx

# 进入容器
kubectl exec -it my-app-pod-xxx -- /bin/sh

# 查看Pod详情
kubectl describe pod my-app-pod-xxx

# ========== 3. Deployment管理 ==========

# 查看Deployment
kubectl get deployments

# 创建Deployment
kubectl apply -f deployment.yaml

# 查看Deployment状态
kubectl rollout status deployment/my-app

# 扩缩容
kubectl scale deployment/my-app --replicas=5

# 滚动更新
kubectl set image deployment/my-app my-app=nginx:1.26

# 回滚
kubectl rollout undo deployment/my-app

# 查看历史
kubectl rollout history deployment/my-app

# ========== 4. Service管理 ==========

# 查看Service
kubectl get services

# 查看Ingress
kubectl get ingress

# 暴露Deployment为Service
kubectl expose deployment my-app --port=80 --type=LoadBalancer

# ========== 5. 调试和问题排查 ==========

# 查看资源状态
kubectl get all

# 查看Pod日志（所有副本）
kubectl logs deployment/my-app --previous

# 端口转发（本地调试）
kubectl port-forward service/my-app 8080:80

# 代理访问Dashboard
kubectl proxy

# 资源使用情况
kubectl top pods
kubectl top nodes
```

---

## 4. Cloud Run - 无服务器容器

### 4.1 为什么选择Cloud Run？

**Cloud Run = 极简的容器运行平台**

```
Cloud Run vs 其他计算服务

┌─────────────────────────────────────────────────────────────────────────┐
│                      Cloud Run 核心优势                                  │
│                                                                         │
│  1. 零基础设施管理                                                      │
│     ├── 无需预配服务器                                                   │
│     ├── 无需管理集群                                                    │
│     └── 自动扩缩到0（无请求时）                                         │
│                                                                         │
│  2. 极简的开发者体验                                                    │
│     ├── 只需提供容器镜像                                                │
│     ├── 自动获取HTTPS域名                                               │
│     └── 自动负载均衡                                                    │
│                                                                         │
│  3. 按使用付费                                                          │
│     ├── 按请求数计费                                                    │
│     ├── 按CPU/内存使用时间计费                                          │
│     └── 闲置时免费（无请求时）                                          │
│                                                                         │
│  4. 兼容性                                                              │
│     ├── 完全兼容K8s                                                    │
│     ├── 支持任何语言/框架                                              │
│     └── 轻松从GKE迁移                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Cloud Run部署

```powershell
# ============================================================
# Cloud Run部署 - Windows PowerShell
# ============================================================

# ========== 1. 部署第一个Cloud Run服务 ==========

# Cloud Run部署流程：
# 1. 准备容器镜像
# 2. 推送到Artifact Registry
# 3. 部署到Cloud Run

# 方法1：直接从源代码部署（最简单）
# 注意：需要安装Google Cloud SDK组件
gcloud components install cloud-run

# 从源代码部署（会自动构建容器）
gcloud run deploy my-service `
    --source . `
    --platform managed `
    --region us-central1 `
    --allow-unauthenticated

# 方法2：使用已有容器镜像

# 部署公开镜像
gcloud run deploy nginx-service `
    --image nginx:alpine `
    --platform managed `
    --region us-central1 `
    --allow-unauthenticated

# 部署私有镜像（需要Artifact Registry）
gcloud run deploy my-private-service `
    --image gcr.io/PROJECT_ID/my-image:latest `
    --platform managed `
    --region us-central1 `
    --service-account my-sa@PROJECT_ID.iam.gserviceaccount.com

# ========== 2. 配置部署参数 ==========

# 指定内存限制
gcloud run deploy my-service `
    --image my-image:latest `
    --platform managed `
    --region us-central1 `
    --memory 512Mi

# 指定CPU
gcloud run deploy my-service `
    --image my-image:latest `
    --platform managed `
    --region us-central1 `
    --cpu 2

# 设置环境变量
gcloud run deploy my-service `
    --image my-image:latest `
    --platform managed `
    --region us-central1 `
    --set-env-vars "ENV=production,LOG_LEVEL=info"

# 设置启动命令
gcloud run deploy my-service `
    --image my-image:latest `
    --platform managed `
    --region us-central1 `
    --command "/bin/sh" `
    --args "-c,echo Hello"

# ========== 3. 管理服务 ==========

# 查看服务
gcloud run services list

# 查看服务详情
gcloud run services describe my-service --region us-central1

# 更新服务
gcloud run deploy my-service `
    --image my-image:v2 `
    --region us-central1

# 滚动更新（逐步替换流量）
gcloud run deploy my-service `
    --image my-image:v2 `
    --region us-central1 `
    --traffic=100

# 回滚到上一个版本
gcloud run services update-traffic my-service `
    --to-revisions=my-service-00001-abc `
    --region us-central1 `
    --traffic=100

# 删除服务
gcloud run services delete my-service --region us-central1

# ========== 4. 自动扩缩配置 ==========

# 设置最小实例数（保持预热）
gcloud run services update my-service `
    --region us-central1 `
    --min-instances=0

# 设置最大实例数（控制成本）
gcloud run services update my-service `
    --region us-central1 `
    --max-instances=10

# 设置并发数（每个实例处理的请求数）
gcloud run services update my-service `
    --region us-central1 `
    --concurrency=80

# ========== 5. Cloud Run与GKE对比 ==========

# 何时使用Cloud Run：
# - 简单Web服务/API
# - 事件驱动处理
# - 想要简化运维
# - 工作负载波动大

# 何时使用GKE：
# - 需要Kubernetes高级功能
# - 需要多云部署
# - 复杂的微服务架构
# - 需要运行DaemonSet/Job
```

---

## 5. 知识检测

### 选择题

1. 如果你需要运行一个遗留的Windows应用，应该选择什么服务？
   - A. Cloud Run
   - B. Cloud Functions
   - C. Compute Engine ✓
   - D. GKE

2. 抢占式虚拟机的主要限制是什么？
   - A. 无法使用SSD
   - B. 可能被随时终止 ✓
   - C. 无法使用自定义镜像
   - D. 无法使用防火墙规则

3. GKE Autopilot模式和Standard模式的主要区别是什么？
   - A. Autopilot不支持GPU
   - B. Autopilot按Pod付费，GCP自动管理节点 ✓
   - C. Standard模式更便宜
   - D. Autopilot不支持自动扩缩

4. Cloud Run的独特优势是什么？
   - A. 支持Windows容器
   - B. 可以扩缩到0实例 ✓
   - C. 只能运行Python
   - D. 无法配置内存限制

---

## 6. Windows PowerShell命令速查表

```powershell
# ============================================================
# 计算服务命令速查
# ============================================================

# ---------- 虚拟机操作 ----------
# 创建
gcloud compute instances create NAME --zone=ZONE --machine-type=TYPE

# 列出
gcloud compute instances list

# 启动/停止
gcloud compute instances start NAME --zone=ZONE
gcloud compute instances stop NAME --zone=ZONE

# 删除
gcloud compute instances delete NAME --zone=ZONE

# SSH连接
gcloud compute ssh NAME --zone=ZONE

# ---------- 实例组操作 ----------
# 创建模板
gcloud compute instance-templates create NAME --machine-type=TYPE

# 创建托管实例组
gcloud compute instance-groups managed create NAME --region=REGION --size=SIZE

# 设置自动扩缩
gcloud compute instance-groups managed set-autoscaling NAME --region=REGION --max-num-replicas=MAX

# ---------- GKE操作 ----------
# 创建集群
gcloud container clusters create NAME --zone=ZONE

# 获取凭证
gcloud container clusters get-credentials NAME --zone=ZONE

# 列出集群
gcloud container clusters list

# 删除集群
gcloud container clusters delete NAME --zone=ZONE

# ---------- Cloud Run操作 ----------
# 部署服务
gcloud run deploy NAME --image=IMAGE --region=REGION

# 列出服务
gcloud run services list --region=REGION

# 更新服务
gcloud run deploy NAME --image=IMAGE --region=REGION

# 删除服务
gcloud run services delete NAME --region=REGION
```

---

## 7. 扩展阅读

- [Compute Engine文档](https://cloud.google.com/compute/docs)
- [GKE文档](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud Run文档](https://cloud.google.com/run/docs)
- [GCP定价计算器](https://cloud.google.com/products/calculator)
- [Kubernetes官方文档](https://kubernetes.io/docs/)

---

## 学习进度

- [ ] 理解计算服务选择原理
- [ ] 掌握Compute Engine虚拟机
- [ ] 理解实例类型选择
- [ ] 学会GKE集群管理
- [ ] 掌握Kubernetes资源
- [ ] 掌握Cloud Run
- [ ] 完成实战项目
