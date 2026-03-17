# 云平台核心服务对比

## 本章概述

本章将对比主流云平台的核心服务，帮助学习者建立多云认知，为后续深入学习打下基础。

## 学习目标

- 了解主流云平台及其特点
- 掌握各平台核心服务的对应关系
- 理解云服务的通用概念
- 能够在不同云平台间进行服务映射

---

## 1. 主流云平台概览

### 1.1 全球云市场格局

```
全球公有云市场份额（2024）

AWS        ████████████████████████  32%
Azure      ████████████████          23%
GCP        ████████                   10%
阿里云      ███████                    9%
腾讯云      ███                        4%
其他        ████████                  22%
```

### 1.2 各平台特点

| 云平台 | 所属公司 | 优势领域 | 特点 |
|-------|---------|---------|------|
| AWS | Amazon | 全栈服务、生态系统 | 服务最全、市场最大、文档丰富 |
| Azure | Microsoft | 企业服务、混合云 | 与Windows生态集成、企业友好 |
| GCP | Google | 大数据、AI/ML | 技术领先、K8s原生、数据分析强 |
| 阿里云 | 阿里巴巴 | 国内市场、电商 | 国内第一、合规完善、生态丰富 |
| 腾讯云 | 腾讯 | 游戏、社交 | 游戏解决方案、微信生态 |

### 1.3 区域与可用区

```
云平台全球部署架构

Region（区域）
├── Availability Zone 1（可用区1）
│   ├── Data Center A
│   └── Data Center B
├── Availability Zone 2（可用区2）
│   ├── Data Center C
│   └── Data Center D
└── Availability Zone 3（可用区3）
    ├── Data Center E
    └── Data Center F

高可用设计：跨可用区部署
灾难恢复：跨区域部署
```

**各平台区域命名**：

| 平台 | 区域命名示例 | 说明 |
|-----|-------------|------|
| AWS | us-east-1, ap-northeast-1 | 区域-方向-编号 |
| Azure | East US, Southeast Asia | 方向+地区 |
| GCP | us-central1, asia-east1 | 地区-方向编号 |
| 阿里云 | cn-hangzhou, us-west-1 | 国家-城市 |

---

## 2. 计算服务对比

### 2.1 虚拟机服务

| 特性 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| 服务名称 | EC2 | Virtual Machines | Compute Engine | ECS | CVM |
| 按需计费 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 预留实例 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 竞价实例 | Spot | Spot | Preemptible | 抢占式 | 竞价实例 |
| 自动伸缩 | Auto Scaling | VM Scale Sets | MIG | 弹性伸缩 | 弹性伸缩 |

### 2.2 实例类型对比

```
实例类型分类

通用型
├── AWS: T3, M5, M6
├── Azure: B, D, A series
├── GCP: e2, n1, n2
├── 阿里云: g系列, ecs.g6
└── 腾讯云: S系列

计算优化型
├── AWS: C5, C6
├── Azure: F series
├── GCP: c2
├── 阿里云: c系列
└── 腾讯云: C系列

内存优化型
├── AWS: R5, X1
├── Azure: E, M series
├── GCP: m1, m2
├── 阿里云: r系列
└── 腾讯云: M系列

存储优化型
├── AWS: I3, D2
├── Azure: Ls series
├── GCP: n2d
├── 阿里云: i系列
└── 腾讯云: I系列

GPU计算型
├── AWS: P4, P3, G4
├── Azure: NC, NV series
├── GCP: a2
├── 阿里云: gn系列
└── 腾讯云: GN系列
```

### 2.3 容器服务

| 服务类型 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|---------|-----|-------|-----|--------|--------|
| 托管K8s | EKS | AKS | GKE | ACK | TKE |
| 容器实例 | Fargate | Container Instances | Cloud Run | ECI | EKSCI |
| 容器注册 | ECR | Container Registry | Artifact Registry | ACR | TCR |

### 2.4 无服务器计算

| 特性 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| 服务名称 | Lambda | Azure Functions | Cloud Functions | 函数计算 | 云函数 |
| 运行时 | 多语言 | 多语言 | 多语言 | 多语言 | 多语言 |
| 触发器 | 丰富 | 丰富 | 丰富 | 丰富 | 丰富 |
| 最大执行时间 | 15分钟 | 10分钟 | 9分钟 | 10分钟 | 15分钟 |

---

## 3. 存储服务对比

### 3.1 对象存储

| 特性 | AWS S3 | Azure Blob | GCP Cloud Storage | 阿里云 OSS | 腾讯云 COS |
|-----|--------|------------|-------------------|-----------|-----------|
| 存储层级 | Standard/Glacier | Hot/Cool/Archive | Standard/Nearline/Coldline | 标准/低频/归档 | 标准/低频/归档 |
| 最大文件 | 5TB | 4.75TB | 5TB | 48.8TB | 5TB |
| 版本控制 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 生命周期 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 静态网站 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 跨区域复制 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 3.2 块存储

| 特性 | AWS EBS | Azure Disk | GCP PD | 阿里云 云盘 | 腾讯云 CBS |
|-----|---------|------------|--------|------------|-----------|
| 类型 | gp3, io2 | Premium, Ultra | pd-ssd, pd-balanced | ESSD, SSD | SSD, Premium |
| 最大容量 | 16TB | 32TB | 64TB | 32TB | 32TB |
| 最大IOPS | 256,000 | 160,000 | 100,000 | 1,000,000 | 50,000 |
| 快照 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 加密 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 3.3 文件存储

| 服务 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| 文件存储 | EFS | Azure Files | Filestore | NAS | CFS |
| 协议 | NFS | SMB/NFS | NFS | NFS/SMB | NFS |
| 用途 | 共享存储 | 共享存储 | 共享存储 | 共享存储 | 共享存储 |

---

## 4. 数据库服务对比

### 4.1 关系型数据库

| 特性 | AWS RDS | Azure SQL | GCP Cloud SQL | 阿里云 RDS | 腾讯云 TencentDB |
|-----|---------|-----------|---------------|-----------|-----------------|
| MySQL | ✓ | ✓ | ✓ | ✓ | ✓ |
| PostgreSQL | ✓ | ✓ | ✓ | ✓ | ✓ |
| SQL Server | ✓ | ✓ | ✓ | ✓ | ✓ |
| Oracle | ✓ | ✓ | - | ✓ | ✓ |
| 主从复制 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 只读副本 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 自动备份 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 时间点恢复 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 4.2 云原生数据库

| 特性 | AWS Aurora | Azure Cosmos DB | GCP Spanner | 阿里云 PolarDB | 腾讯云 TDSQL |
|-----|-----------|-----------------|-------------|---------------|-------------|
| 类型 | 关系型 | 多模型 | 分布式关系 | 关系型 | 分布式关系 |
| 兼容性 | MySQL/PG | MongoDB/Cassandra等 | PostgreSQL | MySQL/PG/Oracle | MySQL |
| 全球分布 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 水平扩展 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 4.3 NoSQL数据库

| 类型 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| 键值 | DynamoDB | Table Storage | Datastore | Table Store | TcaplusDB |
| 文档 | DocumentDB | Cosmos DB | Firestore | MongoDB | MongoDB |
| 缓存 | ElastiCache | Redis Cache | Memorystore | Redis | Redis |
| 时序 | Timestream | Data Explorer | Bigtable | TSDB | CTSDB |

---

## 5. 网络服务对比

### 5.1 虚拟网络

| 特性 | AWS VPC | Azure VNet | GCP VPC | 阿里云 VPC | 腾讯云 VPC |
|-----|---------|------------|---------|-----------|-----------|
| 私有网络 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 子网 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 路由表 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 安全组 | ✓ | NSG | 防火墙 | 安全组 | 安全组 |
| 网络ACL | NACL | NSG | 防火墙规则 | 网络ACL | 网络ACL |
| 对等连接 | ✓ | ✓ | ✓ | ✓ | ✓ |
| VPN网关 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 5.2 负载均衡

| 类型 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| 四层 | NLB | Load Balancer (Basic) | TCP Proxy | SLB (TCP/UDP) | CLB |
| 七层 | ALB | Application Gateway | HTTP(S) Load Balancer | SLB (HTTP/HTTPS) | CLB |
| 全球 | Global Accelerator | Front Door | Cloud CDN | GA | GA |

### 5.3 CDN服务

| 特性 | AWS CloudFront | Azure CDN | GCP Cloud CDN | 阿里云 CDN | 腾讯云 CDN |
|-----|---------------|-----------|---------------|-----------|-----------|
| 全球节点 | 400+ | 200+ | 200+ | 2800+ | 2800+ |
| HTTPS | ✓ | ✓ | ✓ | ✓ | ✓ |
| 边缘计算 | Lambda@Edge | Edge Functions | Cloud Functions | EdgeRoutine | EdgeFunctions |

### 5.4 DNS服务

| 服务 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|-----|-----|-------|-----|--------|--------|
| DNS | Route 53 | Azure DNS | Cloud DNS | 云解析 | DNSPod |
| 健康检查 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 故障转移 | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## 6. 安全与身份服务对比

### 6.1 身份与访问管理

| 特性 | AWS IAM | Azure AD | GCP IAM | 阿里云 RAM | 腾讯云 CAM |
|-----|---------|----------|---------|-----------|-----------|
| 用户管理 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 角色管理 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 策略管理 | ✓ | ✓ | ✓ | ✓ | ✓ |
| MFA | ✓ | ✓ | ✓ | ✓ | ✓ |
| 联合身份 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 服务账号 | ✓ | ✓ | ✓ | ✓ | ✓ |

### 6.2 安全服务

| 服务类型 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|---------|-----|-------|-----|--------|--------|
| WAF | WAF | WAF | Cloud Armor | WAF | WAF |
| DDoS防护 | Shield | DDoS Protection | Cloud Armor | Anti-DDoS | 大禹 |
| 密钥管理 | KMS | Key Vault | KMS | KMS | KMS |
| 安全中心 | Security Hub | Security Center | Security Command Center | 安全中心 | 安全中心 |
| 漏洞扫描 | Inspector | Security Center | Container Analysis | 漏洞扫描 | 漏洞扫描 |

---

## 7. 监控与日志服务对比

| 服务类型 | AWS | Azure | GCP | 阿里云 | 腾讯云 |
|---------|-----|-------|-----|--------|--------|
| 监控 | CloudWatch | Azure Monitor | Cloud Monitoring | 云监控 | 云监控 |
| 日志 | CloudWatch Logs | Log Analytics | Cloud Logging | 日志服务 | 日志服务 |
| 链路追踪 | X-Ray | Application Insights | Cloud Trace | 链路追踪 | 应用性能观测 |
| 告警 | CloudWatch Alarms | Alerts | Alerting | 告警 | 告警 |

---

## 8. 实操练习

### 练习1：创建虚拟机

**任务**：在各云平台创建一台Linux虚拟机

**配置要求**：
- 实例类型：2核4G
- 操作系统：Ubuntu 22.04
- 存储：50GB SSD
- 网络：允许SSH访问

**AWS CLI示例**：
```bash
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t3.medium \
    --key-name my-key-pair \
    --security-group-ids sg-12345678 \
    --subnet-id subnet-12345678 \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]'
```

**Azure CLI示例**：
```bash
az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image UbuntuLTS \
    --size Standard_B2s \
    --admin-username azureuser \
    --ssh-key-value ~/.ssh/id_rsa.pub
```

**GCP CLI示例**：
```bash
gcloud compute instances create my-instance \
    --machine-type=e2-medium \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=50GB
```

### 练习2：对象存储操作

**任务**：创建存储桶并上传文件

**AWS S3**：
```bash
aws s3 mb s3://my-unique-bucket-name
aws s3 cp file.txt s3://my-unique-bucket-name/
aws s3 ls s3://my-unique-bucket-name/
```

**阿里云OSS**：
```bash
ossutil mb oss://my-bucket
ossutil cp file.txt oss://my-bucket/
ossutil ls oss://my-bucket/
```

### 练习3：配置安全组

**任务**：配置安全组允许HTTP/HTTPS/SSH访问

**AWS安全组规则**：
```bash
aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

---

## 9. 知识检测

### 选择题

1. AWS的托管Kubernetes服务名称是什么？
   - A. AKS
   - B. EKS
   - C. GKE
   - D. TKE

2. 以下哪个是Azure的对象存储服务？
   - A. S3
   - B. OSS
   - C. Blob Storage
   - D. Cloud Storage

3. 阿里云的身份认证服务名称是什么？
   - A. IAM
   - B. Azure AD
   - C. RAM
   - D. CAM

### 思考题

1. 为什么企业会选择多云策略？
2. 如何选择合适的云平台？
3. 不同云平台的服务如何进行映射？

---

## 10. 扩展阅读

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [阿里云文档](https://help.aliyun.com/)

---

## 学习进度

- [ ] 了解主流云平台特点
- [ ] 掌握计算服务对比
- [ ] 掌握存储服务对比
- [ ] 掌握数据库服务对比
- [ ] 掌握网络服务对比
- [ ] 掌握安全服务对比
- [ ] 完成实操练习
