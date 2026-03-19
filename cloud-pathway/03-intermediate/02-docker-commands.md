# Docker常用命令参考速查表

## 本速查表说明

本速查表整理了Docker最常用的命令，按功能分类，方便快速查阅。所有命令都适配了Windows PowerShell环境。每个命令都包含详细参数说明，解释参数含义和为什么需要它。

---

## 目录

1. [镜像命令](#1-镜像命令)
2. [容器命令](#2-容器命令)
3. [网络命令](#3-网络命令)
4. [卷命令](#4-卷命令)
5. [Docker Compose命令](#5-docker-compose命令)
6. [系统命令](#6-系统命令)
7. [Dockerfile相关命令](#7-dockerfile相关命令)
8. [速查索引](#8-速查索引)

---

## 1. 镜像命令

### 1.1 镜像查看和搜索

```powershell
# ============================================================
# 查看本地镜像列表
# ============================================================
docker images

# 参数说明:
# ├── -a, --all: 显示所有镜像（包括中间层）
# ├── --format: 格式化输出（如 '{{.Repository}}:{{.Tag}}'）
# ├── --no-trunc: 显示完整镜像ID
# └── -q, --quiet: 只显示镜像ID

# 示例
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
docker images -q  # 列出所有镜像ID

# ============================================================
# 搜索镜像
# ============================================================
docker search keyword

# 参数说明:
# ├── --limit: 限制返回结果数量（默认25）
# ├── --no-trunc: 显示完整描述
# └── --filter "is-official=true": 只显示官方镜像

# 示例
docker search nginx --limit 10
docker search --filter "is-official=true" python


# ============================================================
# 查看镜像详情
# ============================================================
docker image inspect my-image

# 参数说明:
# ├── --format: 使用Go模板格式化输出
# └── 返回镜像的完整信息（层、配置、创建时间等）

# 示例：只获取镜像大小
docker image inspect my-image --format '{{.Size}}'
```

### 1.2 镜像拉取和推送

```powershell
# ============================================================
# 拉取镜像
# ============================================================
docker pull nginx

# 参数说明:
# ├── :tag: 指定版本标签（默认latest）
# ├── -a, --all-tags: 拉取所有标签
# └── 完整格式: registry/namespace/repository:tag

# 示例
docker pull nginx:latest              # 拉取最新版本
docker pull nginx:1.25-alpine         # 拉取指定版本
docker pull redis:7-alpine            # 拉取Redis Alpine版本
docker pull gcr.io/project-id/image   # 拉取GCR镜像


# ============================================================
# 推送镜像到仓库
# ============================================================
docker push my-image:latest

# 示例
docker push my-registry.com/my-image:latest
docker push gcr.io/PROJECT_ID/my-image:v1.0.0
```

### 1.3 镜像构建

```powershell
# ============================================================
# 从Dockerfile构建镜像
# ============================================================
docker build -t my-image:latest .

# 参数说明:
# ├── -t, --tag: 镜像名称和标签（格式: name:tag）
# ├── -f, --file: 指定Dockerfile名称（默认./Dockerfile）
# ├── --build-arg: 设置构建参数（可多次使用）
# ├── --no-cache: 不使用缓存
# ├── --force-rm: 始终移除中间容器
# ├── --rm: 构建成功后移除中间容器（默认）
# ├── --progress=plain: 不使用构建缓存时显示详细输出
# └── -m, --memory: 限制构建内存

# 示例
docker build -t my-app:1.0.0 .                                    # 基本构建
docker build -t my-app:latest -f Dockerfile.prod .              # 指定Dockerfile
docker build -t my-app:latest --build-arg VERSION=1.0.0 .       # 传递构建参数
docker build -t my-app:latest --no-cache .                      # 不使用缓存
docker build -t my-app:latest --build-arg HTTP_PROXY=$env:HTTP_PROXY .  # 代理


# ============================================================
# 构建并标记多个标签
# ============================================================
docker build -t my-app:latest -t my-app:v1.0.0 -t my-app:$(git rev-parse --short HEAD) .
```

### 1.4 镜像管理

```powershell
# ============================================================
# 创建镜像（从容器）
# ============================================================
docker commit my-container my-image:latest

# 参数说明:
# ├── -a, --author: 作者信息
# ├── -c, --change: 应用Dockerfile指令
# ├── -m, --message: 提交信息
# └── -p, --pause: 提交时暂停容器（默认true）

# 示例
docker commit -a "Author <email@example.com>" -m "Initial commit" my-container my-image:v1


# ============================================================
# 标记镜像（为推送做准备）
# ============================================================
docker tag my-image:latest my-registry.com/my-image:latest

# 常用场景：标记本地镜像为不同仓库
docker tag nginx:latest my-registry.com/nginx:latest
docker tag nginx:latest my-registry.com/nginx:1.25


# ============================================================
# 删除镜像
# ============================================================
docker rmi my-image:latest

# 参数说明:
# ├── -f, --force: 强制删除
# └── --no-prune: 不删除父镜像

# 示例
docker rmi nginx:latest                     # 删除单个
docker rmi $(docker images -q)              # 删除所有（危险！）
docker rmi -f $(docker images -q nginx)     # 强制删除所有nginx镜像


# ============================================================
# 清理未使用的镜像
# ============================================================
docker image prune

# 参数说明:
# ├── -a, --all: 删除所有未使用的镜像
# └── --filter: 过滤条件

# 示例
docker image prune -a                        # 删除所有悬空镜像
docker image prune --filter "until=24h"      # 删除24小时前的
```

---

## 2. 容器命令

### 2.1 创建和启动容器

```powershell
# ============================================================
# 创建并启动容器
# ============================================================
docker run -d nginx

# 参数说明:
# ├── -d, --detach: 后台运行
# ├── -i, --interactive: 保持STDIN打开
# ├── -t, --tty: 分配伪终端
# ├── --name: 指定容器名称
# ├── -p, --publish: 端口映射（宿主机:容器）
# ├── -e, --env: 设置环境变量
# ├── --env-file: 从文件加载环境变量
# ├── -v, --volume: 卷挂载
# ├── --network: 加入网络
# ├── --restart: 重启策略
# ├── --rm: 容器退出时自动删除
# ├── --privileged: 授予扩展权限
# ├── --cpus: 限制CPU核心数
# ├── --memory, -m: 限制内存
# ├── --memory-swap: 内存+Swap限制
# ├── --cpu-shares: CPU权重
# ├── --read-only: 只读文件系统
# ├── --user, -u: 指定运行用户
# ├── -w, --workdir: 工作目录
# ├── --hostname: 主机名
# ├── --dns: 自定义DNS
# ├── --add-host: 添加host映射
# ├── --cap-add: 添加Linux能力
# ├── --security-opt: 安全选项
# └── --health-cmd: 健康检查命令

# 常用示例
docker run -d --name my-nginx nginx                           # 基本运行
docker run -d -p 8080:80 --name my-nginx nginx                # 端口映射
docker run -d -e NODE_ENV=production --name my-app my-app     # 环境变量
docker run -d -v /host/path:/container/path my-app            # 卷挂载
docker run -d --network my-network my-app                     # 加入网络
docker run -d --restart=always nginx                          # 自动重启
docker run -d --rm nginx                                      # 退出删除
docker run -d -m 512m --cpus=1 nginx                           # 资源限制
docker run -d --name my-nginx -e TZ=Asia/Shanghai nginx       # 时区设置


# ============================================================
# 交互式容器（前台运行，可交互）
# ============================================================
docker run -it ubuntu /bin/bash

# 参数说明:
# ├── -i: 保持STDIN打开
# ├── -t: 分配终端
# └── /bin/bash: 要执行的命令

# 示例
docker run -it --name my-ubuntu ubuntu /bin/bash              # 进入交互式
docker run -it --rm ubuntu sh                                 # 临时交互式


# ============================================================
# 启动已存在的容器
# ============================================================
docker start my-container

# 参数说明:
# ├── -i, --interactive: 附加到容器的标准输入
# └── -a, --attach: 附加到容器的STDOUT/STDERR


# ============================================================
# 创建但不启动容器
# ============================================================
docker create --name my-nginx nginx

# 与run的区别：create只创建，run创建并启动
```

### 2.2 容器管理

```powershell
# ============================================================
# 查看运行中的容器
# ============================================================
docker ps

# 参数说明:
# ├── -a, --all: 显示所有容器（包括停止的）
# ├── -q, --quiet: 只显示容器ID
# ├── -l, --latest: 显示最新创建的容器
# ├── --filter: 过滤条件
# ├── --format: 格式化输出
# └── -n: 显示最后N个容器

# 示例
docker ps                           # 只看运行中的
docker ps -a                        # 看所有容器
docker ps -q                        # 只看容器ID
docker ps --filter "status=exited" # 过滤已停止的
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"


# ============================================================
# 查看容器详情
# ============================================================
docker inspect my-container

# 参数说明:
# ├── --format: Go模板格式化
# └── 返回完整的容器配置和状态

# 示例
docker inspect my-container --format '{{.NetworkSettings.IPAddress}}'  # 获取IP
docker inspect my-container --format '{{.State.Status}}'               # 获取状态


# ============================================================
# 查看容器日志
# ============================================================
docker logs my-container

# 参数说明:
# ├── -f, --follow: 实时跟踪日志
# ├── --tail: 显示最后N行（默认all）
# ├── -t, --timestamps: 显示时间戳
# ├── --since: 显示指定时间后的日志
# └── --details: 显示额外信息

# 示例
docker logs my-container                           # 查看日志
docker logs -f my-container                        # 实时跟踪
docker logs --tail 100 my-container               # 最后100行
docker logs -t my-container                       # 带时间戳
docker logs --since 2024-01-01 my-container       # 指定时间后


# ============================================================
# 进入容器（执行命令）
# ============================================================
docker exec -it my-container /bin/bash

# 参数说明:
# ├── -i, --interactive: 保持STDIN打开
# ├── -t, --tty: 分配终端
# ├── -d, --detach: 后台执行
# ├── -u, --user: 指定用户
# ├── -w, --workdir: 工作目录
# └── 要执行的命令

# 示例
docker exec -it my-container /bin/bash            # 进入bash
docker exec -it my-container sh                   # 进入sh
docker exec -d my-container touch /tmp/test      # 后台执行
docker exec -u root my-container su - root        # 以root执行


# ============================================================
# 停止容器
# ============================================================
docker stop my-container

# 参数说明:
# ├── -t, --time: 等待秒数后强制停止（默认10）
# └── 发送SIGTERM，允许程序优雅退出

# 示例
docker stop my-container                          # 正常停止
docker stop -t 30 my-container                    # 30秒后强制
docker stop $(docker ps -q)                       # 停止所有运行中的


# ============================================================
# 强制终止容器
# ============================================================
docker kill my-container

# 参数说明:
# └── 发送SIGKILL，立即终止

# 示例
docker kill my-container                          # 立即终止
docker kill -s SIGTERM my-container              # 发送其他信号


# ============================================================
# 重启容器
# ============================================================
docker restart my-container

# 参数说明:
# └── 先停止再启动，等同于stop + start


# ============================================================
# 删除容器
# ============================================================
docker rm my-container

# 参数说明:
# ├── -f, --force: 强制删除（运行中的）
# ├── -l, --link: 移除链接
# └── -v, --volumes: 同时删除关联的卷

# 示例
docker rm my-container                            # 删除停止的容器
docker rm -f my-container                         # 强制删除运行中的
docker rm -v my-container                          # 同时删除卷
docker rm $(docker ps -aq)                         # 删除所有容器


# ============================================================
# 暂停/恢复容器
# ============================================================
docker pause my-container                         # 暂停
docker unpause my-container                       # 恢复

# 暂停会暂停容器内所有进程
```

### 2.3 容器资源监控

```powershell
# ============================================================
# 查看容器资源使用
# ============================================================
docker stats

# 参数说明:
# ├── --no-stream: 不持续更新
# ├── --format: 格式化输出
# └── --no-trunc: 不截断输出

# 示例
docker stats my-container                         # 单个容器
docker stats $(docker ps -q)                      # 所有容器
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"


# ============================================================
# 查看容器进程
# ============================================================
docker top my-container

# 参数说明:
# └── 显示容器内运行的进程


# ============================================================
# 容器端口映射
# ============================================================
docker port my-container

# 参数说明:
# └── 显示端口映射关系
```

### 2.4 容器高级操作

```powershell
# ============================================================
# 复制文件
# ============================================================
docker cp my-container:/app/config.json ./config.json

# 参数说明:
# ├── 格式: 容器路径 宿主机路径 或 宿主机路径 容器路径
# └── 可以复制文件或目录


# ============================================================
# 查看文件变化
# ============================================================
docker diff my-container

# 参数说明:
# ├── A: 添加的文件
# ├── D: 删除的文件
# └── C: 修改的文件


# ============================================================
# 更新容器配置
# ============================================================
docker update --memory 512m --cpu-shares 512 my-container

# 参数说明:
# ├── --memory, -m: 内存限制
# ├── --memory-swap: 内存+Swap
# ├── --cpus: CPU核心数
# ├── --cpu-shares: CPU权重
# └── --restart: 重启策略
```

---

## 3. 网络命令

### 3.1 网络管理

```powershell
# ============================================================
# 查看网络列表
# ============================================================
docker network ls

# 参数说明:
# ├── 默认网络: bridge, host, none
# └── 用户创建: 自定义网络


# ============================================================
# 创建网络
# ============================================================
docker network create my-network

# 参数说明:
# ├── -d, --driver: 网络驱动（默认bridge）
# ├── --subnet: 子网 CIDR
# ├── --gateway: 网关IP
# ├── --ip-range: 容器IP范围
# ├── --internal: 内部网络（不能访问外网）
# ├── --ipv6: 启用IPv6
# ├── --label: 网络标签
# └── --attachable: 允许手动附加容器

# 示例
docker network create my-network                              # 基本
docker network create -d bridge --subnet 172.20.0.0/16 my-net # 自定义子网
docker network create --internal my-internal                  # 内部网络


# ============================================================
# 查看网络详情
# ============================================================
docker network inspect my-network

# 参数说明:
# └── 返回网络配置和连接的容器


# ============================================================
# 连接容器到网络
# ============================================================
docker network connect my-network my-container

# 参数说明:
# └── 一个容器可以连接到多个网络


# ============================================================
# 断开容器与网络的连接
# ============================================================
docker network disconnect my-network my-container


# ============================================================
# 删除网络
# ============================================================
docker network rm my-network

# 删除所有未使用的网络
docker network prune
```

---

## 4. 卷命令

### 4.1 卷管理

```powershell
# ============================================================
# 查看卷列表
# ============================================================
docker volume ls

# 参数说明:
# ├── -f, --filter: 过滤条件
# └── -q, --quiet: 只显示卷名


# ============================================================
# 创建卷
# ============================================================
docker volume create my-volume

# 参数说明:
# ├── -d, --driver: 卷驱动（默认local）
# ├── --label: 卷标签
# └── --opt: 驱动选项

# 示例
docker volume create my-volume                    # 基本
docker volume create --driver local my-volume     # 指定驱动
docker volume create --label env=prod my-volume  # 带标签


# ============================================================
# 查看卷详情
# ============================================================
docker volume inspect my-volume

# 参数说明:
# └── 返回卷的挂载点、驱动等信息


# ============================================================
# 删除卷
# ============================================================
docker volume rm my-volume

# 删除所有未使用的卷
docker volume prune

# 参数说明:
# ├── -f, --filter: 过滤条件
# └── 警告：会删除所有未使用的本地卷
```

---

## 5. Docker Compose命令

### 5.1 基础命令

```powershell
# ============================================================
# 启动服务
# ============================================================
docker-compose up

# 参数说明:
# ├── -d, --detach: 后台运行
# ├── -f, --file: 指定compose文件
# ├── --build: 启动前构建镜像
# ├── --force-recreate: 强制重新创建容器
# ├── --no-recreate: 不重新创建已存在的容器
# ├── --no-build: 不构建镜像
# ├── --no-deps: 不启动依赖的服务
# ├── --remove-orphans: 清理未在compose中定义的容器
# └── --scale: 扩展服务实例数

# 示例
docker-compose up -d                              # 后台启动
docker-compose up --build                         # 重新构建
docker-compose up -d --build                       # 构建并启动
docker-compose up -f docker-compose.dev.yml       # 指定文件


# ============================================================
# 停止服务
# ============================================================
docker-compose down

# 参数说明:
# ├── -v, --volumes: 同时删除卷
# ├── --remove-orphans: 清理未在compose中定义的容器
# └── --rmi: 删除镜像（local/all）

# 示例
docker-compose down                               # 停止并删除容器
docker-compose down -v                            # 同时删除卷
docker-compose down --rmi local                   # 删除本地镜像


# ============================================================
# 查看服务状态
# ============================================================
docker-compose ps

# 参数说明:
# └── 显示所有服务的状态


# ============================================================
# 查看日志
# ============================================================
docker-compose logs

# 参数说明:
# ├── -f, --follow: 实时跟踪
# ├── --tail: 显示最后N行
# ├── -t, --timestamps: 显示时间戳
# └── --since: 指定时间后

# 示例
docker-compose logs -f                            # 实时跟踪
docker-compose logs -f web                         # 只看web服务
docker-compose logs --tail=100                     # 最后100行
```

### 5.2 服务管理

```powershell
# ============================================================
# 构建镜像
# ============================================================
docker-compose build

# 参数说明:
# ├── --no-cache: 不使用缓存
# ├── --force-rm: 始终删除中间容器
# └── --parallel: 并行构建

# 示例
docker-compose build                              # 构建所有服务
docker-compose build --no-cache                   # 不使用缓存


# ============================================================
# 进入服务容器
# ============================================================
docker-compose exec web /bin/bash

# 示例
docker-compose exec web sh                         # 进入web服务
docker-compose exec db psql -U user -d mydb       # 执行命令


# ============================================================
# 扩展服务
# ============================================================
docker-compose up -d --scale web=3 --scale api=2

# 示例
docker-compose up -d --scale web=3                # 扩展web到3个实例


# ============================================================
# 重新创建容器
# ============================================================
docker-compose up --force-recreate


# ============================================================
# 暂停/恢复服务
# ============================================================
docker-compose pause
docker-compose unpause


# ============================================================
# 验证配置
# ============================================================
docker-compose config

# 参数说明:
# └── 验证并显示合并后的配置


# ============================================================
# 列出服务
# ============================================================
docker-compose config --services
```

### 5.3 其他命令

```powershell
# ============================================================
# 在服务中运行命令
# ============================================================
docker-compose run web /bin/sh

# 示例
docker-compose run --rm web npm test              # 运行测试
docker-compose run -e VAR=value web cmd          # 传递环境变量


# ============================================================
# 停止服务
# ============================================================
docker-compose stop


# ============================================================
# 启动服务
# ============================================================
docker-compose start


# ============================================================
# 重启服务
# ============================================================
docker-compose restart


# ============================================================
# 删除已停止的容器
# ============================================================
docker-compose rm
```

---

## 6. 系统命令

### 6.1 Docker信息

```powershell
# ============================================================
# 查看Docker信息
# ============================================================
docker info

# 参数说明:
# └── 显示Docker系统信息（版本、镜像数、容器数等）


# ============================================================
# 查看Docker版本
# ============================================================
docker version

# 参数说明:
# └── 显示Docker客户端和服务端版本


# ============================================================
# 查看Docker磁盘使用
# ============================================================
docker system df

# 参数说明:
# ├── -v: 详细输出
# └── 显示镜像、容器、卷的磁盘占用
```

### 6.2 系统清理

```powershell
# ============================================================
# 清理构建缓存
# ============================================================
docker builder prune

# 参数说明:
# ├── -a, --all: 清理所有未使用的构建缓存
# └── --filter: 过滤条件


# ============================================================
# 清理所有未使用资源
# ============================================================
docker system prune

# 参数说明:
# ├── -a, --all: 删除所有未使用的镜像
# ├── --volumes: 同时删除卷
# ├── --filter: 过滤条件
# └── -f, --force: 不确认直接删除


# ============================================================
# 清理事件
# ============================================================
docker system events

# 参数说明:
# ├── --since: 指定时间后
# ├── --until: 指定时间前
# └── --filter: 过滤条件

# 示例
docker system events --since 60m                  # 最近60分钟
docker system events --filter 'type=container'    # 只看容器事件
```

---

## 7. Dockerfile相关命令

### 7.1 构建辅助

```powershell
# ============================================================
# 查看构建历史
# ============================================================
docker history my-image

# 参数说明:
# ├── --no-trunc: 显示完整命令
# ├── -q, --quiet: 只显示镜像ID
# └── --format: 格式化输出

# 示例
docker history my-image                           # 查看构建层
docker history --no-trunc my-image                # 完整信息
docker history --format "{{.CreatedBy}}" my-image # 只看命令
```

---

## 8. 速查索引

### 快速查找

| 操作 | 命令 |
|------|------|
| 运行nginx | `docker run -d -p 8080:80 --name my-nginx nginx` |
| 进入容器 | `docker exec -it my-container /bin/bash` |
| 查看日志 | `docker logs -f my-container` |
| 查看运行中 | `docker ps` |
| 查看所有 | `docker ps -a` |
| 停止容器 | `docker stop my-container` |
| 删除容器 | `docker rm my-container` |
| 删除镜像 | `docker rmi my-image` |
| 拉取镜像 | `docker pull nginx` |
| 构建镜像 | `docker build -t my-image .` |
| 查看网络 | `docker network ls` |
| 查看卷 | `docker volume ls` |
| 启动Compose | `docker-compose up -d` |
| 停止Compose | `docker-compose down` |
| 查看日志 | `docker-compose logs -f` |

### 常用参数速查

| 参数 | 含义 | 示例 |
|------|------|------|
| `-d` | 后台运行 | `docker run -d nginx` |
| `-p` | 端口映射 | `docker run -p 8080:80 nginx` |
| `-v` | 卷挂载 | `docker run -v /data:/app/data nginx` |
| `-e` | 环境变量 | `docker run -e ENV=prod nginx` |
| `--name` | 容器名 | `docker run --name my-nginx nginx` |
| `--rm` | 退出删除 | `docker run --rm nginx` |
| `-it` | 交互终端 | `docker run -it ubuntu /bin/bash` |
| `--network` | 网络 | `docker run --network my-net nginx` |
| `-m` | 内存限制 | `docker run -m 512m nginx` |
| `-f` | 指定文件 | `docker build -f Dockerfile.prod` |

### 端口映射格式

```
-p 宿主机端口:容器端口
-p 127.0.0.1:8080:80      # 只绑定本地IP
-p 8080:80/tcp             # 指定协议
-P                         # 随机映射所有端口
```

### 卷挂载格式

```
-v 宿主机路径:容器路径              # 绑定挂载
-v 卷名:容器路径                     # 命名卷
-v 宿主机路径:容器路径:ro           # 只读
-v 宿主机路径:容器路径:rw           # 可写（默认）
-v 宿主机路径:容器路径:ro,Z        # SELinux
--tmpfs /path                        # tmpfs
```

---

*最后更新：2024*
