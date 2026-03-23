# Jenkins基础和架构

## 本章导学

**学完本章后，你将能够：**

- 理解Jenkins的核心架构和组件
- 掌握Jenkins的安装和配置方法
- 理解Jenkins的工作原理

**学习方法：**

```
Jenkins架构 → 安装配置 → 工作原理 → 核心概念
```

---

# 1. Jenkins概述

## 1.1 Jenkins是什么

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins                                      │
└─────────────────────────────────────────────────────────────────┘

# Jenkins是开源的持续集成/持续交付(CI/CD)自动化服务器
# 由Hudson项目分支而来
# 使用Java编写

# 核心功能:
# 1. 持续集成 (CI): 自动化构建和测试
# 2. 持续交付 (CD): 自动化部署
# 3. 自动化任务: 各种自动化工作流

# 优势:
# - 开源免费
# - 插件丰富 (1800+ 插件)
# - 跨平台 (Windows, Linux, macOS)
# - 配置灵活
# - 分布式构建
```

## 1.2 Jenkins历史

```
# Jenkins vs Hudson
# 2011年: Oracle收购Sun后，Hudson社区分裂
# 2011年: Jenkins fork诞生
# 现在: Jenkins是主流，Hudson几乎停更

# 版本历史:
# Jenkins 1.x: 传统Freestyle项目
# Jenkins 2.x: Pipeline as Code
# Jenkins LTS: 长期支持版本
```

---

# 2. Jenkins架构

## 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins架构                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Jenkins Master                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Web UI (Jenkins管理界面)                  ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │                    调度器 (Build Scheduler)                  ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │                    插件管理 (Plugin Manager)                ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │                    认证授权 (Security)                      ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                    构建任务分发                                  │
└──────────────────────────────┼───────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Jenkins Agent  │  │  Jenkins Agent  │  │  Jenkins Agent  │
│    (Node 1)     │  │    (Node 2)     │  │    (Node N)     │
│  ┌───────────┐  │  ┌───────────┐  │  ┌───────────┐  │
│  │ Executor  │  │  │ Executor  │  │  │ Executor  │  │
│  │  (执行器)  │  │  │  (执行器)  │  │  │  (执行器)  │  │
│  └───────────┘  │  └───────────┘  │  └───────────┘  │
└─────────────────┘  └─────────────────┘  └─────────────────┘

# Master: 负责调度、管理界面、插件、认证
# Agent: 实际执行构建任务的节点
```

## 2.2 核心组件

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins核心组件                               │
└─────────────────────────────────────────────────────────────────┘

Master组件:
┌─────────────────────────────────────────────────────────────────┐
│ 组件                │ 功能                                      │
├─────────────────────┼───────────────────────────────────────────┤
│ Jenkins Core        │ 核心引擎，处理请求和调度                   │
│ Web Server          │ 提供Web界面，端口默认8080                 │
│ Build Queue         │ 构建任务队列，管理等待中的构建            │
│ Plugin Manager      │ 插件安装、更新、卸载                      │
│ Security Realm      │ 用户认证 (Jenkins自己的用户数据库/LDAP) │
│ Authorization       │ 权限控制 (矩阵权限/项目矩阵权限)          │
│ Master-Slave        │ 与Agent通信，管理构建分发                  │
└─────────────────────────────────────────────────────────────────┘

Agent组件:
┌─────────────────────────────────────────────────────────────────┐
│ 组件                │ 功能                                      │
├─────────────────────┼───────────────────────────────────────────┤
│ Agent进程           │ 与Master保持长连接，接收任务               │
│ Workspace          │ 工作目录，存放源代码和构建产物             │
│ Executor           │ 执行器，并行执行构建任务                   │
│ Launcher           │ 启动器，-launch-method选项指定             │
└─────────────────────────────────────────────────────────────────┘
```

## 2.3 Jenkins工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins工作流程                               │
└─────────────────────────────────────────────────────────────────┘

1. 源码管理 (Source Control)
   └─ 从Git/SVN等仓库拉取代码

2. 触发构建 (Build Trigger)
   ├─ 定时构建 (Cron)
   ├─ Webhook触发 (代码提交)
   └─ 上游构建完成触发

3. 任务调度 (Scheduling)
   └─ Master分配构建任务到Agent

4. 执行构建 (Execution)
   └─ Agent执行具体的构建步骤

5. 记录日志 (Logging)
   └─ 实时记录构建输出

6. 通知 (Notification)
   └─ 邮件/Slack等方式通知结果
```

---

# 3. Jenkins安装

## 3.1 Docker安装

```bash
# Docker安装Jenkins

# 1. 拉取镜像 (LTS版本)
docker pull jenkins/jenkins:lts

# 2. 运行容器
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# 3. 查看日志获取初始密码
docker logs jenkins
# 或
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# 4. 访问Web界面
# http://localhost:8080

# 常用Docker选项:
# -v jenkins_home:/var/jenkins_home  # 数据持久化
# -p 8080:8080                        # Web界面端口
# -p 50000:50000                      # Agent通信端口
# --restart unless-stopped            # 自动重启
```

## 3.2 Linux安装

```bash
# 在Ubuntu/Debian上安装

# 1. 添加Jenkins仓库
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# 2. 安装
sudo apt-get update
sudo apt-get install jenkins

# 3. 启动服务
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 4. 查看状态
sudo systemctl status jenkins

# 5. 访问
# http://your_server:8080

# 配置文件位置:
# /etc/default/jenkins          # 配置参数
# /var/lib/jenkins/             # 主目录 (Home)
# /var/log/jenkins/             # 日志
```

## 3.3 Windows安装

```powershell
# Windows安装Jenkins

# 1. 下载war包
# https://jenkins.io/download/

# 2. 使用Java运行
java -jar jenkins.war

# 3. 或作为Windows服务安装
# 下载Windows安装包 (.exe)
# 运行安装向导

# 4. 默认路径:
# C:\Program Files\Jenkins\    # 安装目录
# C:\Jenkins\                   # 数据目录
```

## 3.4 Kubernetes部署

```yaml
# Jenkins Kubernetes部署

apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: jenkins
```

---

# 4. Jenkins配置

## 4.1 初始配置

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins初始配置向导                           │
└─────────────────────────────────────────────────────────────────┘

# 1. 解锁Jenkins
# - 访问 http://localhost:8080
# - 输入初始管理员密码 (在/var/jenkins_home/secrets/initialAdminPassword)
# - 或 docker logs jenkins 查看

# 2. 安装插件
# - 选择"安装推荐插件"
# - 或手动选择需要的插件

# 3. 创建管理员用户
# - 用户名、密码、邮箱

# 4. 配置实例URL
# - 用于Webhook回调等
```

## 4.2 配置界面

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins管理界面                               │
└─────────────────────────────────────────────────────────────────┘

系统配置 (Manage Jenkins → System Configuration):
┌─────────────────────────────────────────────────────────────────┐
│ 系统                                  │ 说明                    │
├───────────────────────────────────────┼────────────────────────┤
│ 系统消息 (System Message)              │ 首页显示的消息          │
│ # of executors                        │ Master上的执行器数量     │
│  Labels                               │ Master标签              │
│ 用法 (Usage)                          │ 何时使用此Master        │
│ 工作目录 (Workspace Root Directory)   │ 构建工作目录            │
│ 日志记录 (Logging)                    │ 日志配置                │
└─────────────────────────────────────────────────────────────────┘

工具配置 (Manage Jenkins → Tools):
┌─────────────────────────────────────────────────────────────────┐
│ 工具                                    │ 说明                    │
├───────────────────────────────────────┼────────────────────────┤
│ JDK                                   │ Java版本管理            │
│ Git                                   │ Git安装                 │
│ Maven                                 │ Maven配置               │
│ Gradle                                │ Gradle配置              │
│ Docker                                │ Docker配置              │
└─────────────────────────────────────────────────────────────────┘
```

## 4.3 配置即代码

```groovy
# Jenkins配置文件 (init.groovy.d/)

# 示例: 设置执行器数量
import jenkins.model.Jenkins

Jenkins.instance.setNumExecutors(2)
Jenkins.instance.setLabel(null)

// 设置系统消息
Jenkins.instance.setSystemMessage("Welcome to Jenkins CI/CD Platform")

// 禁用旧版API token
Jenkins.instance.getActiveRealm().setUseSecurity(true)

// 设置SMTP服务器
import hudson.tasks.Mailer
Mailer.descriptor().setSmtpHost("smtp.example.com")
```

---

# 5. Jenkins核心概念

## 5.1 Job/Item

```
┌─────────────────────────────────────────────────────────────────┐
│                    Job/Item (构建任务)                          │
└─────────────────────────────────────────────────────────────────┘

# Jenkins 2.x中使用"Item"替代"Job"
# Item类型:
┌─────────────────────────────────────────────────────────────────┐
│ 类型                  │ 说明                                    │
├───────────────────────┼────────────────────────────────────────┤
│ Freestyle Project     │ 传统自由式项目，图形化配置              │
│ Pipeline              │ Pipeline项目，代码化配置                │
│ Multi-configuration   │ 多配置项目，矩阵式构建                  │
│ Folder                │ 文件夹，组织项目                        │
│ Organization Folder   │ 组织文件夹，扫描GitHub/Gitea等          │
└─────────────────────────────────────────────────────────────────┘
```

## 5.2 Build/Run

```
┌─────────────────────────────────────────────────────────────────┐
│                    Build (构建)                                  │
└─────────────────────────────────────────────────────────────────┘

# Build是Job的一次执行
# 每次构建产生一个Build Number (如 #42)

# Build状态:
# - SUCCESS: 构建成功
# - FAILURE: 构建失败
# - UNSTABLE: 不稳定 (测试失败等)
# - ABORTED: 被中止
# - NOT BUILT: 未执行 (前置条件不满足)

# Build记录:
# - 控制台输出 (Console Output)
# - 工作空间 (Workspace)
# - 工件 (Artifacts)
# - 变更历史 (Changes)
```

## 5.3 Agent和Executor

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent和Executor                              │
└─────────────────────────────────────────────────────────────────┘

# Agent (代理节点):
# - 实际执行构建的机器
# - 可以是物理机、虚拟机、容器
# - 通过JNLP、SSH等方式连接Master

# Executor (执行器):
# - Agent上的并行执行单元
# - 每个Executor一次执行一个构建
# - 数量可配置

# 配置示例:
# Master: 2 executors
# Agent1: 4 executors (标签: "docker", "linux")
# Agent2: 2 executors (标签: "windows")

# 节点配置:
# 节点名称
# 标签 (labels) - 用于分组
# 工作目录
# 用法模式:
#   - 尽可能使用此节点
#   - 仅限标签表达式
```

## 5.4 Workspace

```
┌─────────────────────────────────────────────────────────────────┐
│                    Workspace (工作空间)                         │
└─────────────────────────────────────────────────────────────────┘

# Workspace是Job在Agent上的工作目录
# 结构: /var/jenkins_home/workspace/[job_name]/

# 特性:
# - 每个Job在每个Agent上有独立的工作空间
# - 可以配置自定义工作目录
# - 构建完成后可以保留或删除

# WORKSPACE环境变量:
# - WORKSPACE: 工作空间根目录
# - WORKSPACE_TMP: 临时目录
```

---

# 6. Jenkins工作原理

## 6.1 请求处理流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    请求处理流程                                  │
└─────────────────────────────────────────────────────────────────┘

用户请求 (Web/API/CLI)
        │
        ▼
┌─────────────────┐
│   Web Server    │  ← Jetty处理HTTP请求
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Security Layer  │  ← 认证和授权
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Request Queue  │  ← 请求排队
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build Queue    │  ← 构建任务排队
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Scheduler     │  ← 调度器分配Executor
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Executor      │  ← 执行构建
└─────────────────┘
```

## 6.2 Master-Agent通信

```
┌─────────────────────────────────────────────────────────────────┐
│                    Master-Agent通信                             │
└─────────────────────────────────────────────────────────────────┘

通信方式:
┌─────────────────────────────────────────────────────────────────┐
│ 方式              │ 说明                                        │
├───────────────────┼────────────────────────────────────────────┤
│ JNLP (Java Web Start) │ Agent通过Java程序连接Master            │
│ SSH               │ Master通过SSH连接Agent                     │
│ 容器 (Docker/K8s) │ Agent运行在容器中                           │
└─────────────────────────────────────────────────────────────────┘

通信流程 (SSH方式):
1. Master生成SSH密钥对
2. 将公钥复制到Agent的~/.ssh/authorized_keys
3. Master通过SSH发送构建命令
4. Agent执行并返回结果

通信流程 (JNLP方式):
1. Master生成JNLP文件 (包含连接信息)
2. Agent启动时下载并执行JNLP
3. Agent主动连接到Master的TCP端口
4. 保持长连接，接收指令
```

## 6.3 构建流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    构建执行流程                                  │
└─────────────────────────────────────────────────────────────────┘

1. 准备阶段 (Preparation)
   ├─ 检查Workspace是否需要清理
   ├─ 分配Executor
   └─ 创建工作目录

2. 源码阶段 (SCM Checkout)
   ├─ 从Git/SVN拉取代码
   ├─ 切换到指定分支
   └─ 记录变更集

3. 构建阶段 (Build)
   ├─ 执行构建命令 (mvn/gradle/npm)
   ├─ 编译源代码
   └─ 生成产物

4. 测试阶段 (Test)
   ├─ 执行单元测试
   ├─ 执行集成测试
   └─ 生成测试报告

5. 部署阶段 (Deploy)
   ├─ 部署到测试环境
   ├─ 部署到预生产环境
   └─ 部署到生产环境

6. 通知阶段 (Notify)
   ├─ 发送邮件通知
   ├─ 更新Git状态
   └─ 触发下游构建
```

---

## 本章小结

- **Jenkins**是开源的CI/CD自动化服务器，核心架构是Master-Agent模式
- **Master**负责调度、管理界面、插件管理和安全认证
- **Agent**是实际执行构建任务的节点，通过Executor执行任务
- **Workspace**是构建任务的工作目录
- **Pipeline**是Jenkins 2.x的核心特性，支持代码化配置CI/CD流程

**关键概念回顾:**

| 概念 | 说明 |
|------|------|
| Master | Jenkins主节点，负责调度和管理 |
| Agent | 执行构建的代理节点 |
| Executor | 执行器，并行执行构建的单元 |
| Job/Item | 构建任务 |
| Build | Job的一次执行 |
| Workspace | 工作空间 |
| Pipeline | 管道即代码 |