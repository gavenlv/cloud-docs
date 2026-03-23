# Docker专家之路：从原理到实战

## 本章导学

**这不是一本入门手册。**

市面上99%的Docker教程都在告诉你"怎么用"——写什么命令、输什么参数。但如果你不知道"为什么"，你永远只能照猫画虎，遇到实际问题就束手无策。

**学完本章后，你将能够：**

- 从**底层原理**理解Docker的容器化机制
- 从**内核特性**理解Namespace和Cgroups
- 从**文件系统**理解Union File System
- 从**网络协议**理解容器网络通信
- 从**存储驱动**理解数据持久化
- 从**编排原理**理解Docker Compose

**学习方法：**

每一节都会按照这个结构展开：
```
原理 → 架构 → 协议细节 → 实际代码 → 验证 → 常见误区
```

让我们开始。

---

# 第一部分：Docker核心原理

## 1.1 Docker为什么需要容器化？

当你运行`docker run`时，Docker如何隔离不同应用的资源？如何保证容器之间互不干扰？如何实现资源限制？

### 1.1.1 容器化的本质

```
容器化解决的问题：

┌─────────────────────────────────────────────────────────────────┐
│  问题：传统虚拟机的资源浪费                             │
└─────────────────────────────────────────────────────────────────┘

传统虚拟机架构：
┌─────────────────────────────────────────────────────────────────┐
│  物理服务器                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Hypervisor (VMware/KVM)                        │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │    │
│  │  │ VM1     │  │ VM2     │  │ VM3     │  │    │
│  │  │ Linux    │  │ Linux    │  │ Linux    │  │    │
│  │  │ App      │  │ App      │  │ App      │  │    │
│  │  └─────────┘  └─────────┘  └─────────┘  │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

问题：
├── 每个VM需要完整的操作系统
├── 启动时间长（分钟级）
├── 资源占用大（GB级内存）
├── 性能损耗高（10-20%）
└── 管理复杂

┌─────────────────────────────────────────────────────────────────┐
│  解决方案：容器化                                         │
└─────────────────────────────────────────────────────────────────┘

容器化架构：
┌─────────────────────────────────────────────────────────────────┐
│  物理服务器                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker Engine                                   │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │    │
│  │  │ 容器1   │  │ 容器2   │  │ 容器3   │  │    │
│  │  │ App      │  │ App      │  │ App      │  │    │
│  │  └─────────┘  └─────────┘  └─────────┘  │    │
│  │  共享：Linux内核、库、二进制文件                │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

优势：
├── 共享宿主机内核
├── 启动时间短（秒级）
├── 资源占用小（MB级内存）
├── 性能损耗低（<5%）
└── 管理简单
```

### 1.1.2 Linux Namespace隔离原理

```
Namespace隔离机制：

┌─────────────────────────────────────────────────────────────────┐
│  Namespace类型和作用                                      │
└─────────────────────────────────────────────────────────────────┘

1. PID Namespace
   ├── 隔离进程ID
   ├── 容器内PID从1开始
   ├── 宿主机看不到容器内进程
   └── 容器看不到宿主机进程

2. NET Namespace
   ├── 隔离网络栈
   ├── 容器有独立的网络接口
   ├── 容器有独立的路由表
   └── 容器有独立的防火墙规则

3. MNT Namespace
   ├── 隔离文件系统挂载点
   ├── 容器有独立的文件系统视图
   ├── 容器看不到宿主机挂载
   └── 支持容器间文件系统隔离

4. UTS Namespace
   ├── 隔离主机名和域名
   ├── 容器可以设置自己的主机名
   ├── 容器不影响宿主机主机名
   └── 支持容器间主机名隔离

5. IPC Namespace
   ├── 隔离进程间通信
   ├── 容器有独立的IPC资源
   ├── 容器间无法通信
   └── 支持容器间IPC隔离

6. USER Namespace
   ├── 隔离用户和用户组
   ├── 容器内的root不是真正的root
   ├── 容器内用户ID映射到宿主机非特权用户
   └── 支持容器间用户隔离

7. CGROUP Namespace (cgroup v2)
   ├── 隔离控制组
   ├── 容器有独立的资源限制
   ├── 容器间资源互不影响
   └── 支持容器间资源隔离
```

### 1.1.3 Cgroups资源限制原理

```
Cgroups控制机制：

┌─────────────────────────────────────────────────────────────────┐
│  Cgroups子系统                                            │
└─────────────────────────────────────────────────────────────────┘

1. CPU子系统
   ├── 限制CPU使用率
   ├── 限制CPU核心数
   ├── 设置CPU优先级
   └── 支持CPU配额

2. 内存子系统
   ├── 限制内存使用量
   ├── 限制交换空间
   ├── 设置内存优先级
   └── 支持内存配额

3. Block I/O子系统
   ├── 限制磁盘读取速度
   ├── 限制磁盘写入速度
   ├── 设置I/O优先级
   └── 支持I/O配额

4. 网络子系统 (cgroup v2)
   ├── 限制网络带宽
   ├── 限制网络包数
   ├── 设置网络优先级
   └── 支持网络配额
```

### 1.1.4 Union File System原理

```
Union File System分层机制：

┌─────────────────────────────────────────────────────────────────┐
│  镜像分层结构                                            │
└─────────────────────────────────────────────────────────────────┘

Docker镜像分层：
┌─────────────────────────────────────────────────────────────────┐
│  容器层（可写层）                                    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ /app/data.txt (新增文件)                      │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ 镜像层3（应用层）                            │    │
│  │ /app/app.py                                   │    │
│  │ /app/requirements.txt                          │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ 镜像层2（运行时层）                          │    │
│  │ /usr/local/bin/python3                          │    │
│  │ /usr/local/lib/python3.9/                       │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ 镜像层1（基础层）                            │    │
│  │ /bin/bash                                     │    │
│  │ /usr/bin/ls                                   │    │
│  │ /usr/bin/cat                                   │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

Union File System工作原理：

1. 只读层（镜像层）
   ├── 所有镜像层都是只读的
   ├── 多个镜像可以共享基础层
   ├── 节省存储空间
   └── 提高构建效率

2. 可写层（容器层）
   ├── 容器启动时创建可写层
   ├── 所有修改都在可写层
   ├── 不影响镜像层
   └── 容器删除时可写层删除

3. Copy-on-Write (CoW)
   ├── 读取时从只读层读取
   ├── 修改时复制到可写层
   ├── 只存储修改的部分
   └── 节省存储空间

存储驱动类型：

1. Overlay2（推荐）
   ├── 性能最好
   ├── 支持inode限制
   ├── 支持page cache
   └── 适合生产环境

2. Btrfs
   ├── 支持快照
   ├── 支持子卷
   ├── 支持压缩
   └── 需要特殊文件系统

3. ZFS
   ├── 支持快照
   ├── 支持压缩
   ├── 支持加密
   └── 需要特殊文件系统

4. VFS（Virtual File System）
   ├── 简单可靠
   ├── 不需要特殊文件系统
   ├── 性能较差
   └── 适合开发环境
```

---

## 1.2 Docker架构详解

### 1.2.1 Docker架构组件

```
Docker架构：

┌─────────────────────────────────────────────────────────────────┐
│  Docker架构图                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  用户层                                                  │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker CLI (docker命令)                        │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker API (REST API)                          │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Docker Engine层                                          │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker Daemon (dockerd)                         │    │
│  │  ├── 镜像管理                                  │    │
│  │  ├── 容器管理                                  │    │
│  │  ├── 网络管理                                  │    │
│  │  ├── 存储管理                                  │    │
│  │  └── 卷管理                                    │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Containerd (容器运行时)                       │    │
│  │  ├── 容器生命周期管理                          │    │
│  │  ├── 镜像管理                                  │    │
│  │  └── 存储管理                                  │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ runc (OCI运行时)                             │    │
│  │  ├── Namespace隔离                             │    │
│  │  ├── Cgroups限制                               │    │
│  │  └── 文件系统管理                              │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  内核层                                                  │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Linux内核                                        │    │
│  │  ├── Namespace                                  │    │
│  │  ├── Cgroups                                    │    │
│  │  ├── Capability                                 │    │
│  │  └── Seccomp                                   │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

组件说明：

1. Docker CLI
   ├── 用户交互接口
   ├── 发送REST API请求
   ├── 支持多种命令
   └── 提供友好的命令行界面

2. Docker Daemon
   ├── 核心守护进程
   ├── 管理Docker对象
   ├── 处理API请求
   └── 协调各组件

3. Containerd
   ├── 容器运行时
   ├── 管理容器生命周期
   ├── 管理镜像存储
   └── 实现OCI规范

4. runc
   ├── OCI兼容运行时
   ├── 创建容器
   ├── 启动容器
   └── 管理容器进程
```

### 1.2.2 Docker对象模型

```
Docker对象层次：

┌─────────────────────────────────────────────────────────────────┐
│  Docker对象类型                                          │
└─────────────────────────────────────────────────────────────────┘

1. 镜像 (Image)
   ├── 只读模板
   ├── 包含应用和依赖
   ├── 分层存储
   └── 不可修改

2. 容器 (Container)
   ├── 镜像的运行实例
   ├── 可写层
   ├── 生命周期管理
   └── 可以删除重建

3. 服务 (Service)
   ├── 容器的抽象
   ├── 支持扩缩容
   ├── 支持负载均衡
   └── 支持滚动更新

4. 网络 (Network)
   ├── 容器间通信
   ├── 外部访问配置
   ├── 隔离网络
   └── 支持多种驱动

5. 卷 (Volume)
   ├── 数据持久化
   ├── 容器间共享
   ├── 独立于容器生命周期
   └── 支持多种驱动

6. 配置 (Config)
   ├── 容器配置模板
   ├── 支持参数化
   ├── 支持环境变量
   └── 支持资源限制
```

---

## 1.3 Docker实战：运行第一个容器

### 1.3.1 运行Hello World

```bash
# 运行Hello World容器
docker run hello-world

# 输出：
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
#
# To generate this message, Docker took the following steps:
#  1. The Docker client contacted the Docker daemon.
#  2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
#  3. The Docker daemon created a new container from that image which runs the
#    executable that produces the output you are currently reading.
# 4. The Docker daemon streamed that output to the Docker client, which sent it
#    to your terminal.
```

### 1.3.2 运行交互式容器

```bash
# 运行Ubuntu容器并进入交互式shell
docker run -it ubuntu bash

# 参数说明：
# -i: 交互式模式（interactive）
# -t: 分配伪终端（pseudo-TTY）
# ubuntu: 镜像名称
# bash: 要运行的命令

# 在容器内执行命令
root@container-id:/# cat /etc/os-release
# PRETTY_NAME="Ubuntu 22.04.3 LTS"
# NAME="Ubuntu"
# VERSION_ID="22.04"
# VERSION="22.04.3 LTS (Jammy Jellyfish)"
# ID=ubuntu
# ID_LIKE=debian
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# VERSION_CODENAME=jammy
# UBUNTU_CODENAME=jammy

# 退出容器
root@container-id:/# exit
```

### 1.3.3 运行后台容器

```bash
# 运行Nginx容器（后台模式）
docker run -d -p 80:80 --name web-server nginx

# 参数说明：
# -d: 后台模式（detached）
# -p 80:80: 端口映射（宿主机端口:容器端口）
# --name web-server: 容器名称
# nginx: 镜像名称

# 查看运行中的容器
docker ps

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 seconds ago   Up 4 seconds   0.0.0.0:80->80/tcp   web-server

# 访问Nginx
curl http://localhost

# 输出：
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# html { color-scheme: light dark; }
# body { width: 35em; margin: 0 auto;
# font-family: Tahoma, Verdana, Arial, sans-serif; }
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# <p>If you see this page, the nginx web server is successfully installed and
# working. Further configuration is required.</p>
#
# <p>For online documentation and support please refer to
# <a href="http://nginx.org/">nginx.org</a>.<br/>
# Commercial support is available at
# <a href="http://nginx.com/">nginx.com</a>.</p>
# <p><em>Thank you for using nginx.</em></p>
# </body>
# </html>

# 查看容器日志
docker logs web-server

# 输出：
# /docker-entrypoint.sh: /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# /docker-entrypoint.sh: Listening on IPv6, address '::', port 80, http server: /
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 29
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 30
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 31
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 32
```

### 1.3.4 容器资源限制

```bash
# 运行容器并限制资源
docker run -d \
  --name limited-container \
  --cpus="0.5" \
  --memory="512m" \
  --memory-swap="512m" \
  nginx

# 参数说明：
# --cpus="0.5": 限制CPU使用率为50%
# --memory="512m": 限制内存为512MB
# --memory-swap="512m": 限制交换空间为512MB

# 查看容器资源使用
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container

# 输出（部分）：
# [
#     {
#         "Id": "abc123def456789",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Path": "/var/lib/docker/containers/abc123def456789/json",
#         "Config": {
#             "Hostname": "limited-container",
#             "CpuShares": 512,
#             "Memory": 536870912,
#             "MemorySwap": 536870912,
#             "CpuPeriod": 100000,
#             "CpuQuota": 50000
#         },
#         "HostConfig": {
#             "CpuShares": 512,
#             "Memory": 536870912,
#             "MemorySwap": 536870912,
#             "CpuPeriod": 100000,
#             "CpuQuota": 50000
#         }
#     }
# ]
```

---

## 本章小结

- 容器化比虚拟机更轻量、启动更快
- Namespace提供资源隔离
- Cgroups提供资源限制
- Union File System提供分层存储
- Docker Engine由多个组件组成
- Docker对象包括镜像、容器、服务、网络、卷
- 可以通过CLI、API、SDK管理Docker

---

**下一章：Docker镜像管理**
