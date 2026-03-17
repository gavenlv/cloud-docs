# Docker容器技术

## 本章概述

容器技术是云原生的核心基础。本章将深入学习Docker，掌握容器化应用的开发、部署和管理。

## 学习目标

- 理解Docker架构原理
- 掌握Dockerfile最佳实践
- 学会镜像优化与安全
- 理解Docker网络模式
- 掌握Docker存储管理
- 熟练使用Docker Compose

---

## 1. Docker架构原理

### 1.1 Docker架构

```
Docker架构

┌─────────────────────────────────────────────────────────────┐
│                      Docker Client                           │
│                    (docker CLI)                              │
└───────────────────────────┬─────────────────────────────────┘
                            │ REST API
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Daemon                             │
│                     (dockerd)                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  containerd │ │   buildkit  │ │  network    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└───────────────────────────┬─────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│    Images     │   │  Containers   │   │   Networks    │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│   Registry    │   │   Volumes     │
│ (Docker Hub)  │   │               │
└───────────────┘   └───────────────┘
```

### 1.2 核心概念

| 概念 | 说明 |
|-----|------|
| Image | 只读模板，包含创建容器的指令 |
| Container | 镜像的运行实例 |
| Registry | 存储和分发镜像的仓库 |
| Dockerfile | 构建镜像的文本文件 |
| Volume | 持久化数据存储 |
| Network | 容器间通信网络 |

### 1.3 底层技术

```
Docker底层技术

Namespaces（命名空间）
├── PID namespace    进程隔离
├── NET namespace    网络隔离
├── IPC namespace    进程间通信隔离
├── MNT namespace    文件系统挂载隔离
├── UTS namespace    主机名隔离
└── USER namespace   用户隔离

Cgroups（控制组）
├── CPU限制
├── 内存限制
├── IO限制
└── 网络带宽限制

UnionFS（联合文件系统）
├── 镜像分层
├── 写时复制（Copy-on-Write）
└── 存储驱动：overlay2, aufs, devicemapper
```

---

## 2. Dockerfile最佳实践

### 2.1 基本结构

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000

USER node

CMD ["node", "dist/main.js"]
```

### 2.2 最佳实践

```dockerfile
FROM python:3.11-slim

LABEL maintainer="dev@example.com"
LABEL version="1.0"
LABEL description="Python web application"

ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["python", "src/main.py"]
```

### 2.3 指令详解

| 指令 | 说明 | 最佳实践 |
|-----|------|---------|
| FROM | 基础镜像 | 使用官方镜像，指定版本标签 |
| ARG | 构建参数 | 用于版本等可变参数 |
| ENV | 环境变量 | 设置运行时环境变量 |
| COPY | 复制文件 | 优于ADD，语义更清晰 |
| RUN | 执行命令 | 合并多层，清理缓存 |
| WORKDIR | 工作目录 | 使用绝对路径 |
| EXPOSE | 暴露端口 | 仅作文档说明 |
| USER | 运行用户 | 非root用户运行 |
| HEALTHCHECK | 健康检查 | 设置合理的检查间隔 |
| CMD | 启动命令 | 使用exec格式 |

### 2.4 多阶段构建

```dockerfile
FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:3.18

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

COPY --from=builder /app/main .
COPY --from=builder /app/config ./config

ENV TZ=Asia/Shanghai

EXPOSE 8080

CMD ["./main"]
```

---

## 3. 镜像优化

### 3.1 镜像分层原理

```
镜像分层结构

┌─────────────────────────────────────────┐
│           Container Layer               │  可写层
│         (运行时修改)                     │
├─────────────────────────────────────────┤
│           Image Layer 4                 │  CMD/ENTRYPOINT
├─────────────────────────────────────────┤
│           Image Layer 3                 │  COPY文件
├─────────────────────────────────────────┤
│           Image Layer 2                 │  RUN安装依赖
├─────────────────────────────────────────┤
│           Image Layer 1                 │  基础镜像
└─────────────────────────────────────────┘

特点：
- 只读层共享
- 写时复制
- 分层缓存加速构建
```

### 3.2 优化技巧

```dockerfile
FROM alpine:3.18

RUN apk add --no-cache \
    curl \
    nginx \
    && rm -rf /var/cache/apk/*

COPY --chown=nginx:nginx . /app

RUN find /app -type f -name "*.test" -delete

FROM scratch

COPY --from=0 /app /app
COPY --from=0 /etc/ssl/certs /etc/ssl/certs
```

**优化清单**：

```
镜像优化策略

1. 选择合适的基础镜像
   ├── alpine (5MB) - 最小化
   ├── distroless - 无shell，更安全
   └── scratch - 空镜像

2. 减少层数
   └── 合并RUN指令

3. 利用缓存
   ├── 先复制依赖文件
   ├── 后复制源代码
   └── 变化频繁的放后面

4. 清理缓存
   ├── apt: rm -rf /var/lib/apt/lists/*
   ├── pip: --no-cache-dir
   └── npm: npm cache clean --force

5. 使用.dockerignore
   ├── 排除不需要的文件
   └── 减少构建上下文

6. 多阶段构建
   ├── 构建阶段：编译环境
   └── 运行阶段：最小运行环境
```

### 3.3 .dockerignore

```
.git
.gitignore
.env
.env.*
node_modules
npm-debug.log
Dockerfile
docker-compose*.yml
README.md
coverage
.nyc_output
*.test.js
*.spec.js
dist
build
```

---

## 4. Docker网络

### 4.1 网络模式

```
Docker网络模式

┌─────────────────────────────────────────────────────────────┐
│                      Bridge (默认)                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                     │
│  │Container│  │Container│  │Container│                     │
│  │ 172.17  │  │ 172.17  │  │ 172.17  │                     │
│  └────┬────┘  └────┬────┘  └────┬────┘                     │
│       └────────────┼────────────┘                          │
│                    │                                        │
│              ┌─────┴─────┐                                  │
│              │   docker0 │                                  │
│              │ 172.17.0.1│                                  │
│              └─────┬─────┘                                  │
└────────────────────┼────────────────────────────────────────┘
                     │
              ┌──────┴──────┐
              │   Host NIC  │
              └─────────────┘

Host模式：共享主机网络栈
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Host Network Stack                   │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │Container│  │Container│  │ Host    │             │   │
│  │  │ :8080   │  │ :3000   │  │ :80     │             │   │
│  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

None模式：无网络
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────┐                                               │
│  │Container│  完全隔离，仅loopback                          │
│  │  none   │                                               │
│  └─────────┘                                               │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 网络操作

```bash
docker network create --driver bridge my-network

docker network create \
    --driver bridge \
    --subnet=172.20.0.0/16 \
    --gateway=172.20.0.1 \
    my-custom-network

docker network ls

docker network inspect my-network

docker run -d --name web --network my-network nginx

docker run -d --name api --network my-network my-api

docker network connect my-network existing-container

docker network disconnect my-network container-name

docker network rm my-network
```

### 4.3 服务发现

```yaml
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
    depends_on:
      - api

  api:
    image: my-api
    networks:
      - frontend
      - backend
    environment:
      - DB_HOST=db

  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
  backend:
    internal: true
```

---

## 5. Docker存储

### 5.1 存储类型

```
Docker存储类型

Volumes（卷）
├── Docker管理
├── 存储在/var/lib/docker/volumes/
├── 可以命名或匿名
└── 最佳持久化方案

Bind Mounts（绑定挂载）
├── 绑定主机路径
├── 主机路径必须存在
└── 开发环境常用

tmpfs（临时文件系统）
├── 存储在内存中
├── 容器停止后消失
└── 敏感数据存储
```

### 5.2 Volume操作

```bash
docker volume create my-volume

docker volume ls

docker volume inspect my-volume

docker run -d \
    --name web \
    -v my-volume:/app/data \
    nginx

docker run -d \
    --name web \
    --mount source=my-volume,target=/app/data \
    nginx

docker run -d \
    --name dev \
    -v $(pwd)/src:/app/src \
    nginx

docker volume rm my-volume

docker volume prune
```

### 5.3 存储驱动

```yaml
version: '3.8'

services:
  db:
    image: postgres
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
      - type: tmpfs
        target: /tmp

  redis:
    image: redis
    volumes:
      - redis-data:/data

  app:
    image: my-app
    volumes:
      - .:/app
      - /app/node_modules

volumes:
  db-data:
    driver: local
  redis-data:
    driver: local
```

---

## 6. Docker Compose

### 6.1 基本语法

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - NODE_ENV=production
    image: my-web:latest
    container_name: web-server
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - API_URL=http://api:8000
    env_file:
      - .env.production
    volumes:
      - ./data:/app/data
    networks:
      - frontend
    depends_on:
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  api:
    build: ./api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - REDIS_URL=redis://redis:6379
    networks:
      - frontend
      - backend
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - backend

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  postgres-data:
  redis-data:
```

### 6.2 常用命令

```bash
docker-compose up -d

docker-compose up -d --build

docker-compose down

docker-compose down -v

docker-compose logs -f

docker-compose logs -f web

docker-compose ps

docker-compose exec web bash

docker-compose stop

docker-compose start

docker-compose restart web

docker-compose scale web=3

docker-compose config

docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 6.3 多环境配置

```yaml
docker-compose.yml (基础配置)

version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-development}
```

```yaml
docker-compose.prod.yml (生产配置)

version: '3.8'

services:
  web:
    build:
      context: .
      args:
        - NODE_ENV=production
    ports:
      - "80:3000"
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 512M
    restart: always
```

---

## 7. 实操项目

### 项目：容器化Web应用

**项目结构**：
```
project/
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
├── backend/
│   ├── Dockerfile
│   └── src/
└── scripts/
    └── deploy.sh
```

**完整配置**：

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      target: production
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - frontend

  backend:
    build:
      context: ./backend
      target: production
    environment:
      - DATABASE_URL=postgresql://app:password@db:5432/appdb
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=app
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=appdb
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  postgres-data:
  redis-data:
```

---

## 8. 知识检测

### 选择题

1. Docker使用什么技术实现容器隔离？
   - A. VirtualBox
   - B. Namespaces和Cgroups
   - C. VMware
   - D. KVM

2. 哪种网络模式让容器共享主机网络？
   - A. bridge
   - B. host
   - C. none
   - D. overlay

3. 多阶段构建的主要目的是什么？
   - A. 加快构建速度
   - B. 减小镜像体积
   - C. 增加安全性
   - D. 以上都是

---

## 9. 扩展阅读

- [Docker官方文档](https://docs.docker.com/)
- [Docker最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Hub](https://hub.docker.com/)

---

## 学习进度

- [ ] 理解Docker架构原理
- [ ] 掌握Dockerfile最佳实践
- [ ] 掌握镜像优化技术
- [ ] 理解Docker网络模式
- [ ] 掌握Docker存储管理
- [ ] 熟练使用Docker Compose
- [ ] 完成实操项目
