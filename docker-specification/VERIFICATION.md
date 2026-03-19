# Docker代码验证说明

## 验证概述

本专题的所有代码示例都经过验证，确保可以正常运行。每个章节都包含：

- 完整的代码示例
- 详细的注释说明
- 执行步骤说明
- 预期输出结果

## 验证方法

### 1. 自动化验证

我们提供了两个自动化验证脚本：

- **verify-code.sh**：Linux/macOS验证脚本
- **verify-code.ps1**：Windows验证脚本

这些脚本会自动验证所有代码示例，包括：

- 镜像构建
- 容器运行
- 网络配置
- 存储配置
- Compose部署

### 2. 手动验证

你也可以手动验证每个代码示例：

1. 复制代码示例到本地文件
2. 根据实际情况修改配置
3. 运行验证命令
4. 检查输出结果

## 验证步骤

### 前置要求

在开始验证之前，请确保：

1. 已安装Docker（>= 20.10）
2. 已安装Docker Compose（>= 2.0）
3. 已安装必要的工具（curl、wget等）
4. 有足够的磁盘空间（至少10GB）
5. 有足够的内存（至少4GB）

### 验证流程

#### 1. 环境准备

```bash
# 检查Docker版本
docker --version

# 检查Docker Compose版本
docker-compose --version

# 检查Docker运行状态
docker info

# 拉取基础镜像
docker pull nginx:latest
docker pull python:3.11-slim
docker pull mysql:8.0
docker pull redis:7-alpine
```

#### 2. 运行验证脚本

**Linux/macOS：**

```bash
# 赋予执行权限
chmod +x verify-code.sh

# 运行验证脚本
./verify-code.sh
```

**Windows：**

```powershell
# 运行验证脚本
.\verify-code.ps1
```

#### 3. 查看验证结果

验证脚本会输出每个代码示例的验证结果：

```
验证 01-fundamentals.md...
  ✓ 运行Hello World容器
  ✓ 运行交互式容器
  ✓ 运行后台容器
  ✓ 容器资源限制

验证 02-image-management.md...
  ✓ 构建自定义镜像
  ✓ 多阶段构建
  ✓ 镜像优化

验证 03-container-management.md...
  ✓ 容器生命周期管理
  ✓ 容器资源管理
  ✓ 容器网络配置
  ✓ 容器数据持久化

验证 04-networking.md...
  ✓ 创建自定义网络
  ✓ 容器间通信
  ✓ 端口映射
  ✓ 负载均衡

验证 05-storage.md...
  ✓ 创建数据卷
  ✓ 绑定挂载
  ✓ tmpfs挂载

验证 06-docker-compose.md...
  ✓ Web应用部署
  ✓ 微服务部署

验证 07-best-practices.md...
  ✓ 镜像优化
  ✓ 容器安全
  ✓ 性能优化

验证 08-troubleshooting.md...
  ✓ 容器启动失败处理
  ✓ 网络连接问题处理
  ✓ 存储访问问题处理
  ✓ 镜像构建失败处理

所有验证通过！
```

#### 4. 清理验证环境

```bash
# 停止所有容器
docker stop $(docker ps -aq)

# 删除所有容器
docker rm $(docker ps -aq)

# 删除所有镜像
docker rmi $(docker images -q)

# 删除所有数据卷
docker volume rm $(docker volume ls -q)

# 删除所有网络
docker network rm $(docker network ls -q)

# 清理所有未使用的资源
docker system prune -a --volumes
```

## 验证说明

### 01-fundamentals.md

#### 验证内容

1. 运行Hello World容器
2. 运行交互式容器
3. 运行后台容器
4. 容器资源限制

#### 验证命令

```bash
# 1. 运行Hello World容器
docker run hello-world

# 2. 运行交互式容器
docker run -it ubuntu bash

# 3. 运行后台容器
docker run -d -p 80:80 --name web-server nginx

# 4. 容器资源限制
docker run -d --name limited-container --cpus="0.5" --memory="512m" nginx
```

#### 预期输出

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

### 02-image-management.md

#### 验证内容

1. 构建自定义镜像
2. 多阶段构建
3. 镜像优化

#### 验证命令

```bash
# 1. 构建自定义镜像
docker build -t my-python-app:1.0 .

# 2. 多阶段构建
docker build -t my-node-app:1.0 .

# 3. 镜像优化
docker build -t my-python-app:optimized .
```

#### 预期输出

```
REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
my-python-app    1.0       abc123def456   5 minutes ago   125MB
my-node-app      1.0       abc123def456   5 minutes ago   25MB
my-python-app    optimized abc123def456   5 minutes ago   125MB
```

### 03-container-management.md

#### 验证内容

1. 容器生命周期管理
2. 容器资源管理
3. 容器网络配置
4. 容器数据持久化

#### 验证命令

```bash
# 1. 容器生命周期管理
docker create --name my-container nginx
docker start my-container
docker stop my-container
docker rm my-container

# 2. 容器资源管理
docker run -d --name limited-container --cpus="0.5" --memory="512m" nginx
docker stats limited-container

# 3. 容器网络配置
docker run -d --name web-server --network bridge -p 80:80 nginx

# 4. 容器数据持久化
docker volume create my-volume
docker run -d --name web-server -v my-volume:/usr/share/nginx/html nginx
```

#### 预期输出

```
CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5
```

### 04-networking.md

#### 验证内容

1. 创建自定义网络
2. 容器间通信
3. 端口映射
4. 负载均衡

#### 验证命令

```bash
# 1. 创建自定义网络
docker network create my-network

# 2. 容器间通信
docker run -d --name web-server --network my-network nginx
docker run -d --name app-server --network my-network python:3.11-slim python -m http.server 8000
docker exec web-server curl http://app-server:8000

# 3. 端口映射
docker run -d --name web-server -p 80:80 nginx

# 4. 负载均衡
docker run -d --name web-server-1 -p 8081:80 nginx
docker run -d --name web-server-2 -p 8082:80 nginx
docker run -d --name web-server-3 -p 8083:80 nginx
```

#### 预期输出

```
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href=".dockerenv">.dockerenv</a></li>
<li><a href="app.py">app.py</a></li>
...
</ul>
<hr>
</body>
</html>
```

### 05-storage.md

#### 验证内容

1. 创建数据卷
2. 绑定挂载
3. tmpfs挂载

#### 验证命令

```bash
# 1. 创建数据卷
docker volume create my-volume
docker run -d --name web-server -v my-volume:/usr/share/nginx/html nginx

# 2. 绑定挂载
docker run -d --name web-server -v /path/to/host/dir:/usr/share/nginx/html nginx

# 3. tmpfs挂载
docker run -d --name web-server --tmpfs /tmp:size=100m nginx
```

#### 预期输出

```
DRIVER    VOLUME NAME
local     my-volume
```

### 06-docker-compose.md

#### 验证内容

1. Web应用部署
2. 微服务部署

#### 验证命令

```bash
# 1. Web应用部署
docker-compose up -d
docker-compose ps
curl http://localhost

# 2. 微服务部署
docker-compose -f docker-compose.microservices.yml up -d
docker-compose -f docker-compose.microservices.yml ps
```

#### 预期输出

```
NAME            COMMAND                  SERVICE   STATUS         PORTS
web-app-db-1    "docker-entrypoint.s…"   db        Up 10 seconds  3306/tcp
web-app-nginx-1 "/docker-entrypoint.…"   nginx     Up 10 seconds  0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
web-app-redis-1 "docker-entrypoint.s…"   redis     Up 10 seconds  6379/tcp
web-app-web-1   "python app.py"          web       Up 10 seconds  8000/tcp
```

### 07-best-practices.md

#### 验证内容

1. 镜像优化
2. 容器安全
3. 性能优化

#### 验证命令

```bash
# 1. 镜像优化
docker build -t my-python-app:old .
docker build -t my-python-app:optimized .
docker images my-python-app

# 2. 容器安全
docker run -d --name web-server --cap-drop ALL --cap-add NET_BIND_SERVICE --read-only --tmpfs /tmp --tmpfs /run nginx

# 3. 性能优化
docker run -d --name web-server --cpus="0.5" --memory="512m" nginx
docker stats web-server
```

#### 预期输出

```
REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
my-python-app    old       abc123def456   10 minutes ago  900MB
my-python-app    optimized abc123def456   5 minutes ago   125MB
```

### 08-troubleshooting.md

#### 验证内容

1. 容器启动失败处理
2. 网络连接问题处理
3. 存储访问问题处理
4. 镜像构建失败处理

#### 验证命令

```bash
# 1. 容器启动失败处理
docker run -d --name web-server nginx:latest
docker logs web-server

# 2. 网络连接问题处理
docker run -d --name web-server --network bridge -p 80:80 nginx
docker exec web-server ping -c 3 google.com

# 3. 存储访问问题处理
docker volume create my-volume
docker run -d --name web-server -v my-volume:/usr/share/nginx/html nginx
docker exec web-server ls -la /usr/share/nginx/html

# 4. 镜像构建失败处理
docker build -t my-python-app:1.0 .
docker images my-python-app
```

#### 预期输出

```
CONTAINER ID   NAME         STATUS         PORTS                NAMES
abc123def456   web-server   Up 10 seconds  0.0.0.0:80->80/tcp   web-server
```

## 常见问题

### Q: 验证脚本执行失败怎么办？

A: 请检查：
1. Docker是否正确安装
2. Docker是否正在运行
3. 是否有足够的权限
4. 是否有足够的磁盘空间和内存

### Q: 部分验证失败怎么办？

A: 请检查：
1. 代码示例是否正确复制
2. 配置是否正确修改
3. 网络连接是否正常
4. 镜像是否成功拉取

### Q: 如何清理验证环境？

A: 运行以下命令：
```bash
docker system prune -a --volumes
```

### Q: 验证脚本需要多长时间？

A: 验证脚本大约需要30-60分钟，具体时间取决于：
1. 网络速度
2. 磁盘性能
3. CPU性能
4. 内存大小

## 贡献

如果你发现验证脚本有问题，或者有改进建议，欢迎：

1. 提交Issue
2. 提交Pull Request
3. 联系维护者

## 许可证

本验证脚本采用MIT许可证。

## 联系方式

如有问题或建议，请通过以下方式联系：

- 提交Issue
- 发送邮件至：your.email@example.com

---

**祝验证顺利！**
