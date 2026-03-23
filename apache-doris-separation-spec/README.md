# Apache Doris 存算分离专题

本专题详细介绍Apache Doris存算分离架构的部署、配置和最佳实践，涵盖云端（GKE + GCS）和本地（Docker + Minikube）两种部署方案。

## 目录结构

```
apache-doris-separation-spec/
├── README.md                              # 本文件
├── 01-architecture-design/                # 架构设计
│   ├── 01-architecture-design.md
│   └── codes/
├── 02-cloud-deployment-gke/               # 云端部署 (GKE + GCS)
│   ├── 02-cloud-deployment-gke.md
│   └── codes/
│       └── gke-values.yaml
├── 03-local-deployment-docker/            # 本地Docker部署
│   ├── 03-local-deployment-docker.md
│   └── codes/
│       ├── docker-compose.yaml
│       ├── .env.minio
│       └── deploy.sh
├── 04-local-deployment-minikube/          # 本地Minikube部署
│   ├── 04-local-deployment-minikube.md
│   └── codes/
│       ├── minio.yaml
│       ├── fe.yaml
│       └── compute.yaml
├── 05-verification-scripts/               # 验证脚本
│   ├── 05-verification-scripts.md
│   └── codes/
│       ├── verify-doris-separation.sh
│       └── verify-doris-separation.ps1
└── 06-troubleshooting/                    # 故障排除
    └── 06-troubleshooting.md
```

## 快速开始

### 本地Docker部署（推荐开发测试）

```bash
cd 03-local-deployment-docker/codes

# 一键部署
chmod +x deploy.sh
./deploy.sh

# 或使用docker-compose
docker-compose up -d

# 等待服务启动
sleep 60

# 连接Doris
mysql -h 127.0.0.1 -P 9030 -uroot -p''
```

### Minikube本地集群部署

```bash
cd 04-local-deployment-minikube/codes

# 启动Minikube
minikube start --cpus=8 --memory=16g --disk-size=100g

# 部署MinIO
kubectl apply -f minio.yaml -n doris

# 部署FE
kubectl apply -f fe.yaml -n doris

# 部署计算节点
kubectl apply -f compute.yaml -n doris

# 端口转发
kubectl port-forward -n doris svc/doris-fe 9030:9030 &

# 连接Doris
mysql -h 127.0.0.1 -P 9030 -uroot -p''
```

### GKE云端部署

```bash
cd 02-cloud-deployment-gke/codes

# 配置GCP项目
gcloud config set project YOUR_PROJECT_ID

# 创建GKE集群
gcloud container clusters create doris-cluster --region us-central1

# 安装Doris
helm install doris apache-doris/doris -n doris -f gke-values.yaml

# 连接Doris
kubectl port-forward -n doris svc/doris-fe 9030:9030 &
mysql -h 127.0.0.1 -P 9030 -uroot -p''
```

## 章节运行指南

### 01 - 架构设计

了解存算分离架构的基本原理和设计思路。

**运行方式**: 阅读 [01-architecture-design.md](01-architecture-design/01-architecture-design.md)

### 02 - GKE云端部署

在Google Cloud Platform上使用GKE和GCS部署生产级集群。

**前置要求**:
- GCP账号和项目
- gcloud CLI已安装
- kubectl已安装

**运行方式**:
```bash
cd 02-cloud-deployment-gke
# 按照文档步骤执行
```

### 03 - 本地Docker部署

使用Docker Compose在本地机器上快速部署Doris存算分离集群，配合MinIO模拟对象存储。

**前置要求**:
- Docker >= 20.10
- Docker Compose >= 2.0
- 8GB+ 内存

**运行方式**:
```bash
cd 03-local-deployment-docker/codes
./deploy.sh
```

### 04 - Minikube本地集群部署

使用Minikube在本地Kubernetes集群上部署，更接近生产环境。

**前置要求**:
- Minikube已安装
- kubectl已安装
- 8核16GB内存

**运行方式**:
```bash
cd 04-local-deployment-minikube/codes
kubectl apply -f minio.yaml -n doris
kubectl apply -f fe.yaml -n doris
kubectl apply -f compute.yaml -n doris
```

### 05 - 验证脚本

提供自动化验证脚本，验证集群功能是否正常。

**运行方式**:
```bash
# Linux/Mac
./05-verification-scripts/codes/verify-doris-separation.sh

# Windows PowerShell
./05-verification-scripts/codes/verify-doris-separation.ps1
```

### 06 - 故障排除

查看常见问题及解决方案。

**运行方式**: 阅读 [06-troubleshooting.md](06-troubleshooting/06-troubleshooting.md)

## 学习路径

```
1. 架构设计
   └── 了解存算分离原理

2. 本地Docker部署（快速入门）
   └── 快速验证功能

3. 本地Minikube部署（进阶）
   └── 学习K8s部署

4. GKE云端部署（生产）
   └── 掌握生产环境部署

5. 验证脚本
   └── 验证集群功能

6. 故障排除
   └── 解决问题
```

## 前置要求

### 通用要求

| 组件 | 最低要求 | 推荐配置 |
|------|----------|----------|
| CPU | 4核 | 8核+ |
| 内存 | 8GB | 16GB+ |
| 磁盘 | 50GB | 100GB+ |
| Docker | 20.10 | 最新版本 |

### 云端部署额外要求

| 组件 | 要求 |
|------|------|
| GCP账号 | 已注册账号 |
| gcloud CLI | 已安装配置 |
| kubectl | 已安装 |
| Helm | 已安装 |

## 常见问题

### Q: 计算节点无法注册到FE？

A: 检查以下几点：
1. 网络连通性：`docker exec doris-compute1 ping fe1`
2. FE是否正常运行：`docker logs doris-fe1`
3. 对象存储配置是否正确

### Q: 对象存储访问失败？

A: 验证MinIO/GCS配置：
1. 检查endpoint地址是否正确
2. 验证access_key和secret_key
3. 确认存储桶已创建且有访问权限

### Q: 缓存命中率低？

A: 可以通过以下方式优化：
1. 增加本地缓存大小
2. 调整缓存TTL
3. 预热热点数据

## 相关专题

- [apache-doris-specification](../apache-doris-specification/) - Doris基础专题
- [kubernetes-specification](../kubernetes-specification/) - Kubernetes专题
- [docker-specification](../docker-specification/) - Docker专题
