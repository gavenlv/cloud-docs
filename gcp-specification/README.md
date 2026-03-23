# GCP专题

## 概述

本专题提供GCP（Google Cloud Platform）的全面教程，涵盖GCP基础、计算服务、数据服务、网络安全、开发运维、架构最佳实践、存储服务和成本优化。

## 目录结构

```
gcp-specification/
├── README.md                              # 本文件
├── 00-command-reference/                 # 命令参考
│   ├── 01-gcp-command-cheatsheet.md
│   ├── 02-gcp-commands.md
│   └── codes/
│       └── bash-01.sh ~ bash-51.sh
├── 01-fundamentals/                      # GCP基础
│   └── 01-gcp-intro.md
├── 02-compute/                           # 计算服务
│   ├── 01-compute-services.md
│   └── codes/
│       └── yaml-01.yaml
├── 03-data-services/                     # 数据服务
│   ├── 01-data-services.md
│   └── codes/
│       └── python-01.py ~ python-03.py
├── 04-networking-security/               # 网络安全
│   ├── 01-network-security.md
│   └── codes/
│       └── python-01.py
├── 05-devops/                            # 开发运维
│   ├── 01-devops-practices.md
│   └── codes/
│       └── yaml-01.yaml
├── 06-architecture/                      # 架构
│   └── 01-architecture-best-practices.md
├── 07-storage/                           # 存储服务
│   └── 01-storage-services.md
└── 08-cost-optimization/                 # 成本优化
    ├── 01-cost-optimization.md
    └── codes/
        ├── json-01.json
        └── python-01.py
```

## 快速开始

### 初始化GCP项目

```bash
gcloud init
gcloud config set project PROJECT_ID
```

### 列出当前配置

```bash
gcloud config list
```

### 验证认证

```bash
gcloud auth login
gcloud auth application-default login
```

## 章节运行指南

### 00-command-reference - 命令参考

**运行命令：**
```bash
cd 00-command-reference/codes
# 查看GCP命令示例
gcloud compute instances list
gcloud storage ls
gcloud container clusters list
```

### 01-fundamentals - GCP基础

**运行命令：**
```bash
gcloud info
gcloud version
gcloud config list
```

### 02-compute - 计算服务

**运行命令：**
```bash
cd 02-compute/codes
# 查看计算服务配置示例
kubectl apply -f yaml-01.yaml
```

### 03-data-services - 数据服务

**运行命令：**
```bash
cd 03-data-services/codes
python python-01.py
python python-02.py
```

### 04-networking-security - 网络安全

**运行命令：**
```bash
cd 04-networking-security/codes
python python-01.py
```

### 05-devops - 开发运维

**运行命令：**
```bash
cd 05-devops/codes
kubectl apply -f yaml-01.yaml
```

### 08-cost-optimization - 成本优化

**运行命令：**
```bash
cd 08-cost-optimization/codes
python python-01.py
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 00-command-reference | bash | 51 |
| 02-compute | yaml | 1 |
| 03-data-services | python | 3 |
| 04-networking-security | python | 1 |
| 05-devops | yaml | 1 |
| 08-cost-optimization | json, python | 2 |

## 学习路径

### 初级路径

1. [00-command-reference](./00-command-reference/) - 掌握GCP命令
2. [01-fundamentals](./01-fundamentals/) - 掌握GCP基础

### 中级路径

1. [02-compute](./02-compute/) - 掌握计算服务
2. [03-data-services](./03-data-services/) - 掌握数据服务
3. [04-networking-security](./04-networking-security/) - 掌握网络安全

### 高级路径

1. [05-devops](./05-devops/) - 掌握开发运维
2. [06-architecture](./06-architecture/) - 掌握架构设计
3. [07-storage](./07-storage/) - 掌握存储服务
4. [08-cost-optimization](./08-cost-optimization/) - 掌握成本优化

## 前置要求

### 必备工具

- Google Cloud SDK (gcloud)
- Python >= 3.8
- Docker (用于容器示例)
- kubectl (用于Kubernetes)

## 常见问题

### Q: 如何认证GCP？

A: 使用以下命令：
```bash
gcloud auth login
gcloud auth application-default login
```

### Q: 如何查看当前项目？

A: 使用以下命令：
```bash
gcloud config get-value project
```

### Q: 如何设置默认区域和区域？

A: 使用以下命令：
```bash
gcloud config set compute/zone us-central1-a
gcloud config set compute/region us-central1
```
