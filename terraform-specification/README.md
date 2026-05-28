# Terraform专题

## 概述

本专题提供从基础到专家级的Terraform教程，涵盖Terraform基础、状态管理、模块化设计、工作空间、GCP集成、高级特性、最佳实践和故障排除。

## 目录结构

```
terraform-specification/
├── README.md                              # 本文件
├── 01-terraform-fundamentals/            # Terraform基础
│   ├── 01-terraform-fundamentals.md
│   └── codes/
│       ├── bash-01.sh ~ bash-06.sh
│       ├── hcl-01.hcl ~ hcl-04.hcl
│       └── json-01.json
├── 02-state-management/                  # 状态管理
│   ├── 02-state-management.md
│   └── codes/
│       ├── bash-01.sh ~ bash-20.sh
│       ├── hcl-01.hcl ~ hcl-10.hcl
│       └── json-01.json ~ json-02.json
├── 03-modular-design/                    # 模块化设计
│   ├── 03-modular-design.md
│   └── codes/
│       ├── bash-01.sh ~ bash-05.sh
│       └── hcl-01.hcl ~ hcl-16.hcl
├── 04-workspaces-environments/           # 工作空间和环境
│   ├── 04-workspaces-environments.md
│   └── codes/
│       ├── bash-01.sh ~ bash-20.sh
│       └── hcl-01.hcl ~ hcl-07.hcl
├── 05-gcp-integration/                   # GCP集成
│   ├── 05-gcp-integration.md
│   ├── 06-gcp-authentication.md           # GCP认证配置
│   └── codes/
│       ├── bash-01.sh ~ bash-05.sh
│       ├── hcl-01.hcl ~ hcl-15.hcl
│       └── yaml-01.yaml ~ yaml-02.yaml
├── 06-advanced-features/                  # 高级特性
│   ├── 06-advanced-features.md
│   └── codes/
│       ├── bash-01.sh ~ bash-02.sh
│       └── hcl-01.hcl ~ hcl-13.hcl
├── 07-best-practices/                    # 最佳实践
│   ├── 07-best-practices.md
│   └── codes/
│       ├── bash-01.sh ~ bash-08.sh
│       ├── hcl-01.hcl ~ hcl-13.hcl
│       └── yaml-01.yaml ~ yaml-02.yaml
├── 08-troubleshooting/                   # 故障排除
│   ├── 08-troubleshooting.md
│   └── codes/
│       └── bash-01.sh ~ bash-26.sh
├── VERIFICATION.md                        # 代码验证说明
├── verify-code.ps1                        # Windows验证脚本
└── verify-code.sh                         # Linux/macOS验证脚本
```

## 快速开始

### 初始化Terraform

```bash
terraform init
```

### 验证配置

```bash
terraform validate
```

### 计划变更

```bash
terraform plan
```

### 应用配置

```bash
terraform apply
```

## 章节运行指南

### 01-terraform-fundamentals - Terraform基础

**运行命令：**
```bash
cd 01-terraform-fundamentals/codes
terraform init
terraform validate
terraform plan
```

### 02-state-management - 状态管理

**运行命令：**
```bash
cd 02-state-management/codes
terraform init
terraform plan
terraform show
```

### 03-modular-design - 模块化设计

**运行命令：**
```bash
cd 03-modular-design/codes
terraform init
terraform get
terraform plan
```

### 04-workspaces-environments - 工作空间

**运行命令：**
```bash
cd 04-workspaces-environments/codes
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
```

### 05-gcp-integration - GCP集成

**运行命令：**
```bash
cd 05-gcp-integration/codes
gcloud auth application-default login
terraform init
terraform plan
```

### 06-advanced-features - 高级特性

**运行命令：**
```bash
cd 06-advanced-features/codes
terraform init
terraform validate
```

### 07-best-practices - 最佳实践

**运行命令：**
```bash
cd 07-best-practices/codes
terraform fmt
terraform validate
terraform plan
```

### 08-troubleshooting - 故障排除

**运行命令：**
```bash
cd 08-troubleshooting/codes
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-terraform-fundamentals | bash, hcl, json | 11 |
| 02-state-management | bash, hcl, json | 32 |
| 03-modular-design | bash, hcl | 21 |
| 04-workspaces-environments | bash, hcl | 27 |
| 05-gcp-integration | bash, hcl, yaml | 22 |
| 06-advanced-features | bash, hcl | 15 |
| 07-best-practices | bash, hcl, yaml | 23 |
| 08-troubleshooting | bash | 26 |

## 学习路径

### 初级路径

1. [01-terraform-fundamentals](./01-terraform-fundamentals/) - 掌握Terraform基础
2. [02-state-management](./02-state-management/) - 掌握状态管理

### 中级路径

1. [03-modular-design](./03-modular-design/) - 掌握模块化设计
2. [04-workspaces-environments](./04-workspaces-environments/) - 掌握工作空间
3. [05-gcp-integration](./05-gcp-integration/) - 掌握GCP集成
   - [GCP集成指南](./05-gcp-integration/05-gcp-integration.md)
   - [GCP认证配置](./05-gcp-integration/06-gcp-authentication.md)

### 高级路径

1. [06-advanced-features](./06-advanced-features/) - 掌握高级特性
2. [07-best-practices](./07-best-practices/) - 实施最佳实践
3. [08-troubleshooting](./08-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Terraform >= 1.0
- GCP SDK (用于GCP集成章节)

## 常见问题

### Q: Terraform状态锁定？

A: 解锁状态：
```bash
terraform force-unlock LOCK_ID
```

### Q: 计划和应用失败？

A: 检查配置文件语法：
```bash
terraform validate
terraform plan
```

### Q: 模块无法下载？

A: 初始化下载：
```bash
terraform init
terraform get
```
