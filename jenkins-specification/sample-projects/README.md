# Jenkins CI/CD 示例项目

本目录包含用于演示Jenkins CI/CD流程的前端和后端示例项目。

## 项目结构

```
sample-projects/
├── frontend/          # 前端项目 (Node.js + Express)
│   ├── src/
│   │   └── index.js   # 主应用
│   ├── build.js       # 构建脚本
│   ├── package.json   # 依赖配置
│   ├── Dockerfile     # Docker镜像
│   └── Jenkinsfile    # Pipeline配置
│
└── backend/           # 后端项目 (Spring Boot)
    ├── src/
    │   └── main/
    │       ├── java/
    │       │   └── com/example/Application.java
    │       └── resources/
    │           └── application.properties
    ├── pom.xml         # Maven配置
    ├── Dockerfile      # Docker镜像
    └── Jenkinsfile     # Pipeline配置
```

## 前端项目 (Frontend)

### 技术栈
- Node.js 18
- Express 4.x
- Jest 测试框架
- Alpine Linux

### 快速开始

```bash
cd frontend

# 本地运行
npm install
npm start

# Docker构建
docker build -t frontend:latest .
docker run -p 3000:3000 frontend:latest
```

### API端点
- `GET /health` - 健康检查
- `GET /api/data` - 获取数据
- `POST /api/data` - 提交数据

## 后端项目 (Backend)

### 技术栈
- Java 17
- Spring Boot 3.1.4
- Maven 3.9
- JUnit 5

### 快速开始

```bash
cd backend

# 本地运行
mvn spring-boot:run

# Docker构建 (多阶段构建)
docker build -t backend:latest .
docker run -p 8080:8080 backend:latest
```

### API端点
- `GET /api/health` - 健康检查
- `GET /api/data` - 获取数据
- `POST /api/data` - 提交数据

## Jenkins Pipeline

两个项目都包含完整的Jenkinsfile，支持:

- 代码拉取
- 依赖安装/下载
- 代码检查 (Lint)
- 单元测试
- 构建
- Docker镜像构建
- 多环境部署 (Dev/Staging/Production)
- 邮件通知
- 工作空间清理

## CI/CD流程

```
代码提交 → Git Hook触发 → Jenkins Pipeline启动
    │
    ├─ Checkout (拉取代码)
    ├─ Install Dependencies (安装依赖)
    ├─ Lint (代码检查)
    ├─ Test (运行测试)
    ├─ Build (构建应用)
    ├─ Docker Build (构建镜像)
    ├─ Deploy to Dev (部署到开发环境)
    ├─ Smoke Test (冒烟测试)
    ├─ Deploy to Staging (部署到预发环境)
    └─ Deploy to Production (部署到生产环境)
```

## 前置要求

- Jenkins 2.x 已安装
- Docker插件已安装
- Kubernetes CLI插件已安装 (用于部署)
- kubectl已配置 (用于K8s部署)
- Docker Registry凭证已配置