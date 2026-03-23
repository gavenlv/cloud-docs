# Cloud学习路径专题

## 概述

本专题提供从基础到专家级的云计算学习路径，涵盖云基础、进阶技能、中级技能、高级技能、专家技能和大师级技能。每个章节都包含详细的代码示例和验证步骤。

## 目录结构

```
cloud-pathway/
├── README.md                              # 本文件
├── 01-foundation/                        # 基础阶段
│   ├── 01-cloud-concepts.md
│   ├── 02-networking-basics.md
│   ├── 03-linux-basics.md
│   ├── 04-cloud-services-comparison.md
│   └── codes/
│       └── bash-01.sh ~ bash-06.sh
├── 02-advanced/                         # 进阶阶段
│   ├── 01-aws-deep-dive.md
│   ├── 02-database-technology.md
│   ├── 03-terraform-iac.md
│   └── codes/
│       ├── bash-01.sh ~ bash-06.sh
│       ├── yaml-01.yaml ~ yaml-04.yaml
│       ├── json-01.json ~ json-02.json
│       └── python-01.py ~ python-03.py
├── 03-intermediate/                      # 中级阶段
│   ├── 01-docker-containers.md
│   ├── 02-docker-commands.md
│   ├── 02-kubernetes-core.md
│   ├── 03-cicd-pipeline.md
│   ├── 03-kubectl-commands.md
│   └── 04-microservices.md
│   └── codes/
│       ├── bash-01.sh ~ bash-03.sh
│       ├── yaml-01.yaml ~ yaml-13.yaml
│       └── dockerfile-01.dockerfile ~ dockerfile-04.dockerfile
├── 04-senior/                           # 高级阶段
│   ├── 01-cloud-architecture.md
│   ├── 02-cloud-security.md
│   └── 03-performance-cost-optimization.md
│   └── codes/
│       ├── yaml-01.yaml ~ yaml-07.yaml
│       ├── json-01.json
│       └── python-01.py ~ python-02.py
├── 05-expert/                           # 专家阶段
│   ├── 01-multi-cloud-strategy.md
│   ├── 02-hybrid-cloud.md
│   └── 03-devsecops.md
│   └── codes/
│       ├── yaml-01.yaml ~ yaml-08.yaml
│       ├── python-01.py
│       └── dockerfile-01.dockerfile
├── 06-master/                           # 大师阶段
│   ├── 01-cloud-native-architecture.md
│   ├── 02-platform-engineering.md
│   └── 03-technical-leadership.md
│   └── codes/
│       └── yaml-01.yaml ~ yaml-09.yaml
```

## 快速开始

### Linux基础

```bash
uname -a
cat /etc/os-release
```

### Docker入门

```bash
docker run hello-world
docker ps -a
```

### Kubernetes基础

```bash
kubectl get nodes
kubectl get pods
```

## 章节运行指南

### 01-foundation - 基础阶段

**运行命令：**
```bash
cd 01-foundation/codes
bash bash-01.sh
```

### 02-advanced - 进阶阶段

**运行命令：**
```bash
cd 02-advanced/codes
python python-01.py
```

### 03-intermediate - 中级阶段

**运行命令：**
```bash
cd 03-intermediate/codes
docker build -t myapp .
kubectl apply -f yaml-01.yaml
```

## 学习路径

### 初级路径

1. [01-foundation](./01-foundation/) - 云基础概念
2. [02-advanced](./02-advanced/) - AWS深入和数据库技术

### 中级路径

1. [03-intermediate](./03-intermediate/) - Docker和Kubernetes
2. [04-senior](./04-senior/) - 云架构和安全

### 高级路径

1. [05-expert](./05-expert/) - 多云和混合云策略
2. [06-master](./06-master/) - 云原生架构和平台工程

## 前置要求

### 必备工具

- Linux系统或WSL
- Docker
- Kubernetes (kubectl)
- Python >= 3.8
- Terraform (用于IaC章节)

## 常见问题

### Q: 如何学习云计算？

A: 建议从Linux基础和网络基础开始，然后学习容器技术（Docker和Kubernetes）。

### Q: 需要多少时间成为云计算专家？

A: 这取决于个人的背景和学习投入，建议按照本学习路径系统性地学习和实践。
