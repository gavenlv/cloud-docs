# Jenkins专题

## 概述

本专题提供从基础到专家级的Jenkins教程，涵盖Jenkins的核心概念、Pipeline开发、分布式构建、安全配置、插件管理、CI/CD集成、最佳实践和故障排除。

## 目录结构

```
jenkins-specification/
├── README.md                              # 本文件
├── 01-jenkins-fundamentals/              # Jenkins基础
│   ├── 01-jenkins-fundamentals.md
│   └── codes/
│       ├── bash-01.sh ~ bash-02.sh
│       ├── groovy-01.groovy
│       └── yaml-01.yaml
├── 02-pipeline-basics/                   # Pipeline基础
│   ├── 02-pipeline-basics.md
│   └── codes/
│       └── groovy-01.groovy ~ groovy-13.groovy
├── 03-pipeline-advanced/                 # Pipeline高级
│   ├── 03-pipeline-advanced.md
│   └── codes/
│       └── groovy-01.groovy ~ groovy-19.groovy
├── 04-distributed-build/                 # 分布式构建
│   ├── 04-distributed-build.md
│   └── codes/
│       ├── bash-01.sh ~ bash-04.sh
│       ├── dockerfile-01.dockerfile
│       ├── groovy-01.groovy ~ groovy-05.groovy
│       └── yaml-01.yaml
├── 05-security-configuration/            # 安全配置
│   ├── 05-security-configuration.md
│   └── codes/
│       ├── bash-01.sh
│       └── groovy-01.groovy ~ groovy-09.groovy
├── 06-plugin-management/                 # 插件管理
│   ├── 06-plugin-management.md
│   └── codes/
│       ├── bash-01.sh ~ bash-07.sh
│       ├── dockerfile-01.dockerfile
│       └── groovy-01.groovy ~ groovy-04.groovy
├── 07-cicd-integration/                  # CI/CD集成
│   ├── 07-cicd-integration.md
│   └── codes/
│       ├── dockerfile-01.dockerfile
│       └── groovy-01.groovy ~ groovy-12.groovy
├── 08-best-practices/                   # 最佳实践
│   ├── 08-best-practices.md
│   └── codes/
│       ├── bash-01.sh ~ bash-03.sh
│       └── groovy-01.groovy ~ groovy-14.groovy
├── 09-troubleshooting/                  # 故障排除
│   ├── 09-troubleshooting.md
│   └── codes/
│       ├── bash-01.sh ~ bash-05.sh
│       └── groovy-01.groovy ~ groovy-03.groovy
├── docker/                              # Docker部署
│   ├── README.md
│   └── docker-compose.yml
├── k8s/                                 # Kubernetes部署
│   ├── README.md
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   └── rbac.yaml
├── sample-projects/                     # 示例项目
│   ├── backend/
│   └── frontend/
├── VERIFICATION.md                       # 代码验证说明
├── verify-jenkins.ps1                    # Windows验证脚本
└── verify-jenkins.sh                    # Linux/macOS验证脚本
```

## 快速开始

### 启动Jenkins

```bash
cd docker
docker-compose up -d
```

### 创建第一个Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
```

## 章节运行指南

### 01-jenkins-fundamentals - Jenkins基础

**运行命令：**
```bash
cd 01-jenkins-fundamentals/codes
groovy groovy-01.groovy
```

### 02-pipeline-basics - Pipeline基础

**运行命令：**
```bash
cd 02-pipeline-basics/codes
# 在Jenkins中创建Pipeline并粘贴groovy内容
```

### 03-pipeline-advanced - Pipeline高级

**运行命令：**
```bash
cd 03-pipeline-advanced/codes
# 查看高级Pipeline示例
```

### 04-distributed-build - 分布式构建

**运行命令：**
```bash
cd 04-distributed-build/codes
# 配置Jenkins Agent
```

### 05-security-configuration - 安全配置

**运行命令：**
```bash
cd 05-security-configuration/codes
groovy groovy-01.groovy
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-jenkins-fundamentals | bash, groovy, yaml | 4 |
| 02-pipeline-basics | groovy | 13 |
| 03-pipeline-advanced | groovy | 19 |
| 04-distributed-build | bash, dockerfile, groovy, yaml | 10 |
| 05-security-configuration | bash, groovy | 10 |
| 06-plugin-management | bash, dockerfile, groovy | 12 |
| 07-cicd-integration | dockerfile, groovy | 13 |
| 08-best-practices | bash, groovy | 17 |
| 09-troubleshooting | bash, groovy | 8 |

## 学习路径

### 初级路径

1. [01-jenkins-fundamentals](./01-jenkins-fundamentals/) - 掌握Jenkins基础
2. [02-pipeline-basics](./02-pipeline-basics/) - 掌握Pipeline基础

### 中级路径

1. [03-pipeline-advanced](./03-pipeline-advanced/) - 掌握Pipeline高级特性
2. [04-distributed-build](./04-distributed-build/) - 掌握分布式构建
3. [05-security-configuration](./05-security-configuration/) - 掌握安全配置

### 高级路径

1. [06-plugin-management](./06-plugin-management/) - 掌握插件管理
2. [07-cicd-integration](./07-cicd-integration/) - 掌握CI/CD集成
3. [08-best-practices](./08-best-practices/) - 实施最佳实践
4. [09-troubleshooting](./09-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Jenkins >= 2.387.3
- Docker
- Java >= 11

## 常见问题

### Q: Jenkins无法启动？

A: 检查Docker日志：`docker-compose logs jenkins`

### Q: 如何配置Agent？

A: 在Jenkins管理界面添加节点，然后使用JNLP连接。
