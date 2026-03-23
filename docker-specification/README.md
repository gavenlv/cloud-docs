# Docker专题

## 概述

本专题提供从基础到专家级的Docker教程，涵盖Docker核心概念、镜像管理、容器管理、网络配置、存储管理、Docker Compose、最佳实践和故障排除。

## 目录结构

```
docker-specification/
├── README.md                              # 本文件
├── 01-fundamentals/                       # Docker基础和核心原理
│   ├── 01-fundamentals.md
│   └── codes/
│       └── bash-01.sh ~ bash-04.sh
├── 02-image-management/                   # Docker镜像管理
│   ├── 02-image-management.md
│   └── codes/
│       ├── bash-01.sh ~ bash-04.sh
│       └── dockerfile-01.dockerfile ~ dockerfile-04.dockerfile
├── 03-container-management/               # 容器生命周期管理
│   ├── 03-container-management.md
│   └── codes/
│       └── bash-01.sh ~ bash-12.sh
├── 04-networking/                         # Docker网络
│   ├── 04-networking.md
│   └── codes/
│       └── bash-01.sh ~ bash-08.sh
├── 05-storage/                           # Docker存储
│   ├── 05-storage.md
│   └── codes/
│       └── bash-01.sh ~ bash-08.sh
├── 06-docker-compose/                    # Docker Compose
│   ├── 06-docker-compose.md
│   └── codes/
│       ├── bash-01.sh ~ bash-02.sh
│       ├── compose-01.yaml ~ compose-10.yaml
│       ├── script-01.sh ~ script-02.sh
│       └── yaml-01.yaml ~ yaml-10.yaml
├── 07-best-practices/                    # Docker最佳实践
│   ├── 07-best-practices.md
│   └── codes/
│       ├── bash-01.sh ~ bash-02.sh
│       ├── dockerfile-01.dockerfile ~ dockerfile-03.dockerfile
│       └── yaml-01.yaml ~ yaml-02.yaml
├── 08-troubleshooting/                   # Docker故障排除
│   ├── 08-troubleshooting.md
│   └── codes/
│       └── bash-01.sh ~ bash-07.sh
├── VERIFICATION.md                        # 代码验证说明
├── verify-code.ps1                        # Windows验证脚本
└── verify-code.sh                         # Linux/macOS验证脚本
```

## 快速开始

### 运行第一个容器

```bash
docker run hello-world
docker ps -a
```

### 构建自定义镜像

```bash
cd 02-image-management/codes
docker build -t myapp -f dockerfile-01.dockerfile .
```

### 使用Docker Compose

```bash
cd 06-docker-compose/codes
docker-compose up -d
```

## 章节运行指南

### 01-fundamentals - Docker基础

**运行命令：**
```bash
cd 01-fundamentals/codes
bash bash-01.sh
```

### 02-image-management - 镜像管理

**运行命令：**
```bash
cd 02-image-management/codes
docker build -t myapp -f dockerfile-01.dockerfile .
docker images
```

### 03-container-management - 容器管理

**运行命令：**
```bash
cd 03-container-management/codes
docker run -d nginx
docker ps
docker stop $(docker ps -aq)
```

### 04-networking - 网络配置

**运行命令：**
```bash
cd 04-networking/codes
docker network create mynet
docker run --network mynet nginx
```

### 05-storage - 存储管理

**运行命令：**
```bash
cd 05-storage/codes
docker volume create myvol
docker run -v myvol:/data nginx
```

### 06-docker-compose - Docker Compose

**运行命令：**
```bash
cd 06-docker-compose/codes
docker-compose up -d
docker-compose ps
```

### 07-best-practices - 最佳实践

**运行命令：**
```bash
cd 07-best-practices/codes
docker build -t myapp -f dockerfile-01.dockerfile .
```

### 08-troubleshooting - 故障排除

**运行命令：**
```bash
cd 08-troubleshooting/codes
docker logs container_name
docker inspect container_name
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-fundamentals | bash | 4 |
| 02-image-management | bash, dockerfile | 8 |
| 03-container-management | bash | 12 |
| 04-networking | bash | 8 |
| 05-storage | bash | 8 |
| 06-docker-compose | bash, compose, yaml, script | 24 |
| 07-best-practices | bash, dockerfile, yaml | 7 |
| 08-troubleshooting | bash | 7 |

## 学习路径

### 初级路径

1. [01-fundamentals](./01-fundamentals/) - 掌握Docker基础
2. [02-image-management](./02-image-management/) - 掌握镜像构建
3. [03-container-management](./03-container-management/) - 掌握容器管理

### 中级路径

1. [04-networking](./04-networking/) - 掌握网络配置
2. [05-storage](./05-storage/) - 掌握存储管理
3. [06-docker-compose](./06-docker-compose/) - 掌握Compose编排

### 高级路径

1. [07-best-practices](./07-best-practices/) - 实施最佳实践
2. [08-troubleshooting](./08-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Docker >= 20.10
- Docker Compose >= 2.0

## 常见问题

### Q: Docker镜像构建失败？

A: 检查Dockerfile语法和上下文路径：
```bash
docker build -t myapp -f dockerfile-01.dockerfile --no-cache .
```

### Q: 容器无法启动？

A: 检查容器日志：
```bash
docker logs container_name
docker inspect container_name
```

### Q: 端口冲突？

A: 检查端口占用：
```bash
netstat -tuln | grep PORT
```
