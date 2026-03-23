# Docker常见错误处理

## 8.1 容器启动失败

### 8.1.1 容器启动失败排查

```
容器启动失败常见原因：

┌─────────────────────────────────────────────────────────────────┐
│  容器启动失败原因分析                                    │
└─────────────────────────────────────────────────────────────────┘

1. 镜像不存在
   ├── 镜像名称错误
   ├── 镜像标签错误
   ├── 镜像未拉取
   └── 镜像被删除

2. 端口冲突
   ├── 端口已被占用
   ├── 端口映射错误
   ├── 端口范围冲突
   └── 端口权限问题

3. 资源不足
   ├── 内存不足
   ├── CPU不足
   ├── 磁盘空间不足
   └── inode不足

4. 配置错误
   ├── 环境变量错误
   ├── 命令错误
   ├── 参数错误
   └── 配置文件错误

5. 依赖问题
   ├── 依赖服务未启动
   ├── 依赖服务不可达
   ├── 依赖服务配置错误
   └── 依赖服务版本不兼容

6. 权限问题
   ├── 文件权限错误
   ├── 用户权限错误
   ├── 端口权限错误
   └── 资源权限错误
```

### 8.1.2 容器启动失败解决方案

```bash
# 错误1：镜像不存在
# 错误信息：
# Unable to find image 'nginx:latest' locally
# docker: Error response from daemon: pull access denied for nginx, repository does not exist or may require 'docker login': denied: requested access to the resource is denied

# 解决方案：
# 1. 检查镜像名称和标签
docker images | grep nginx

# 2. 拉取镜像
docker pull nginx:latest

# 3. 使用正确的镜像名称和标签
docker run -d --name web-server nginx:latest

# 错误2：端口冲突
# 错误信息：
# docker: Error response from daemon: driver failed programming external connectivity on endpoint web-server (abc123def4567890123456789012345678901234567890123456789012345678): Bind for 0.0.0.0:80 failed: port is already allocated

# 解决方案：
# 1. 查看端口占用
netstat -tulpn | grep :80
# 或
ss -tulpn | grep :80

# 2. 查看占用端口的进程
lsof -i :80

# 3. 停止占用端口的容器
docker stop $(docker ps -q --filter "publish=80")

# 4. 使用不同的端口
docker run -d --name web-server -p 8080:80 nginx

# 5. 停止占用端口的进程
sudo kill -9 <PID>

# 错误3：内存不足
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: write /proc/self/attr/keycreate: invalid argument

# 解决方案：
# 1. 查看内存使用情况
free -h

# 2. 查看容器内存限制
docker inspect web-server | grep -A 10 Memory

# 3. 增加内存限制
docker run -d --name web-server --memory="1g" nginx

# 4. 减少其他容器的内存使用
docker update --memory="256m" other-container

# 5. 清理未使用的容器和镜像
docker system prune -a

# 错误4：磁盘空间不足
# 错误信息：
# docker: Error response from daemon: write /var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged: no space left on device

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 查看Docker磁盘使用情况
docker system df

# 3. 清理未使用的镜像
docker image prune -a

# 4. 清理未使用的容器
docker container prune

# 5. 清理未使用的数据卷
docker volume prune

# 6. 清理所有未使用的资源
docker system prune -a --volumes

# 7. 增加磁盘空间
# （需要系统管理员操作）

# 错误5：配置错误
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: exec: "nginx": executable file not found in $PATH

# 解决方案：
# 1. 检查命令是否正确
docker run -it nginx:latest which nginx

# 2. 使用正确的命令
docker run -d --name web-server nginx:latest nginx -g "daemon off;"

# 3. 检查Dockerfile中的CMD和ENTRYPOINT
cat Dockerfile | grep -E "CMD|ENTRYPOINT"

# 4. 修改Dockerfile
# CMD ["nginx", "-g", "daemon off;"]

# 错误6：权限问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: exec: "nginx": permission denied

# 解决方案：
# 1. 检查文件权限
ls -la /path/to/file

# 2. 修改文件权限
chmod +x /path/to/file

# 3. 使用正确的用户
docker run -d --name web-server --user nginx nginx

# 4. 检查Dockerfile中的USER指令
cat Dockerfile | grep USER

# 5. 修改Dockerfile
# USER nginx
```

---

## 8.2 网络连接问题

### 8.2.1 网络连接问题排查

```
网络连接问题常见原因：

┌─────────────────────────────────────────────────────────────────┐
│  网络连接问题原因分析                                    │
└─────────────────────────────────────────────────────────────────┘

1. DNS解析失败
   ├── DNS配置错误
   ├── DNS服务器不可达
   ├── DNS查询超时
   └── DNS缓存问题

2. 网络配置错误
   ├── 网络模式错误
   ├── 网络驱动错误
   ├── 网络参数错误
   └── 网络隔离错误

3. 防火墙规则
   ├── 防火墙阻止连接
   ├── 端口未开放
   ├── 规则配置错误
   └── 规则顺序错误

4. 端口映射错误
   ├── 端口映射配置错误
   ├── 端口冲突
   ├── 端口权限问题
   └── 端口范围错误

5. 网络驱动问题
   ├── 网络驱动不支持
   ├── 网络驱动版本不兼容
   ├── 网络驱动配置错误
   └── 网络驱动崩溃

6. 路由问题
   ├── 路由表错误
   ├── 网关配置错误
   ├── 路由不可达
   └── 路由优先级错误
```

### 8.2.2 网络连接问题解决方案

```bash
# 错误1：DNS解析失败
# 错误信息：
# docker: Error response from daemon: Get "https://registry-1.docker.io/v2/": dial tcp: lookup registry-1.docker.io on 127.0.0.11:53: read udp 127.0.0.11:53->127.0.0.11:53: i/o timeout

# 解决方案：
# 1. 检查DNS配置
docker inspect web-server | grep -A 10 Dns

# 2. 修改DNS配置
docker run -d --name web-server --dns 8.8.8.8 --dns 8.8.4.4 nginx

# 3. 修改Docker守护进程DNS配置
# 编辑 /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

# 4. 重启Docker守护进程
sudo systemctl restart docker

# 5. 使用--network host模式
docker run -d --name web-server --network host nginx

# 错误2：容器间无法通信
# 错误信息：
# curl: (6) Could not resolve host: other-container

# 解决方案：
# 1. 检查容器是否在同一网络
docker inspect web-server | grep -A 10 Networks
docker inspect other-container | grep -A 10 Networks

# 2. 将容器连接到同一网络
docker network connect my-network web-server
docker network connect my-network other-container

# 3. 使用容器IP地址通信
docker inspect other-container | grep IPAddress
docker exec web-server curl http://172.17.0.2:80

# 4. 检查网络驱动
docker network inspect my-network | grep Driver

# 5. 检查网络隔离
docker network inspect my-network | grep Internal

# 错误3：外部无法访问容器
# 错误信息：
# curl: (7) Failed to connect to localhost port 80: Connection refused

# 解决方案：
# 1. 检查端口映射
docker port web-server

# 2. 检查容器是否运行
docker ps | grep web-server

# 3. 检查容器日志
docker logs web-server

# 4. 检查防火墙规则
sudo iptables -L -n -v | grep DOCKER

# 5. 检查容器监听地址
docker exec web-server netstat -tulpn

# 6. 使用正确的端口映射
docker run -d --name web-server -p 80:80 nginx

# 7. 检查容器内应用配置
docker exec web-server cat /etc/nginx/nginx.conf | grep listen

# 错误4：网络驱动不支持
# 错误信息：
# docker: Error response from daemon: could not choose network driver for network my-network

# 解决方案：
# 1. 检查可用的网络驱动
docker info | grep "Network Drivers"

# 2. 使用支持的网络驱动
docker network create --driver bridge my-network

# 3. 检查Docker守护进程配置
docker info | grep "Storage Driver"

# 4. 更新Docker守护进程配置
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}

# 5. 重启Docker守护进程
sudo systemctl restart docker

# 错误5：路由问题
# 错误信息：
# docker: Error response from daemon: failed to create endpoint web-server on network my-network: failed to add gateway address (172.18.0.1): invalid address

# 解决方案：
# 1. 检查网络配置
docker network inspect my-network | grep -A 10 IPAM

# 2. 删除网络
docker network rm my-network

# 3. 重新创建网络
docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 my-network

# 4. 检查路由表
ip route show

# 5. 添加路由
sudo ip route add 172.18.0.0/16 via 172.18.0.1

# 6. 检查网关配置
docker network inspect my-network | grep Gateway
```

---

## 8.3 存储访问问题

### 8.3.1 存储访问问题排查

```
存储访问问题常见原因：

┌─────────────────────────────────────────────────────────────────┐
│  存储访问问题原因分析                                    │
└─────────────────────────────────────────────────────────────────┘

1. 权限问题
   ├── 文件权限错误
   ├── 目录权限错误
   ├── 用户权限错误
   └── SELinux/AppArmor限制

2. 磁盘空间不足
   ├── 磁盘空间已满
   ├── inode已满
   ├── 配额限制
   └── 存储驱动限制

3. 挂载点错误
   ├── 挂载点不存在
   ├── 挂载点权限错误
   ├── 挂载点类型错误
   └── 挂载点配置错误

4. 存储驱动问题
   ├── 存储驱动不支持
   ├── 存储驱动版本不兼容
   ├── 存储驱动配置错误
   └── 存储驱动崩溃

5. 数据卷问题
   ├── 数据卷不存在
   ├── 数据卷权限错误
   ├── 数据卷配置错误
   └── 数据卷损坏

6. 绑定挂载问题
   ├── 源路径不存在
   ├── 源路径权限错误
   ├── 目标路径错误
   └── 挂载选项错误
```

### 8.3.2 存储访问问题解决方案

```bash
# 错误1：权限问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/var/lib/docker/volumes/my-volume/_data" to rootfs at "/data" caused: permission denied

# 解决方案：
# 1. 检查文件权限
ls -la /path/to/file

# 2. 修改文件权限
chmod 755 /path/to/file
chown -R 1000:1000 /path/to/file

# 3. 使用正确的用户
docker run -d --name web-server --user 1000:1000 -v /path/to/file:/data nginx

# 4. 使用--userns-remap
docker run -d --name web-server --userns-remap default -v /path/to/file:/data nginx

# 5. 配置SELinux
chcon -Rt svirt_sandbox_file_t /path/to/file

# 6. 配置AppArmor
# 编辑AppArmor配置文件

# 错误2：磁盘空间不足
# 错误信息：
# docker: Error response from daemon: write /var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged: no space left on device

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 查看inode使用情况
df -i

# 3. 清理未使用的镜像
docker image prune -a

# 4. 清理未使用的容器
docker container prune

# 5. 清理未使用的数据卷
docker volume prune

# 6. 清理所有未使用的资源
docker system prune -a --volumes

# 7. 增加磁盘空间
# （需要系统管理员操作）

# 8. 清理Docker缓存
docker builder prune

# 错误3：挂载点错误
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/var/lib/docker/volumes/my-volume/_data" to rootfs at "/data" caused: no such file or directory

# 解决方案：
# 1. 检查挂载点是否存在
ls -la /path/to/mount

# 2. 创建挂载点
mkdir -p /path/to/mount

# 3. 修改挂载点权限
chmod 755 /path/to/mount

# 4. 使用正确的挂载点
docker run -d --name web-server -v /path/to/mount:/data nginx

# 5. 使用数据卷
docker volume create my-volume
docker run -d --name web-server -v my-volume:/data nginx

# 错误4：数据卷问题
# 错误信息：
# docker: Error response from daemon: volume my-volume not found

# 解决方案：
# 1. 检查数据卷是否存在
docker volume ls | grep my-volume

# 2. 创建数据卷
docker volume create my-volume

# 3. 查看数据卷详细信息
docker volume inspect my-volume

# 4. 使用正确的数据卷名称
docker run -d --name web-server -v my-volume:/data nginx

# 5. 检查数据卷权限
ls -la /var/lib/docker/volumes/my-volume/_data

# 6. 修改数据卷权限
chmod 755 /var/lib/docker/volumes/my-volume/_data

# 错误5：绑定挂载问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/path/to/host/dir" to rootfs at "/data" caused: no such file or directory

# 解决方案：
# 1. 检查源路径是否存在
ls -la /path/to/host/dir

# 2. 创建源路径
mkdir -p /path/to/host/dir

# 3. 修改源路径权限
chmod 755 /path/to/host/dir

# 4. 使用正确的源路径
docker run -d --name web-server -v /path/to/host/dir:/data nginx

# 5. 使用绝对路径
docker run -d --name web-server -v $(pwd)/data:/data nginx

# 6. 检查挂载选项
docker run -d --name web-server -v /path/to/host/dir:/data:ro nginx
```

---

## 8.4 镜像构建失败

### 8.4.1 镜像构建失败排查

```
镜像构建失败常见原因：

┌─────────────────────────────────────────────────────────────────┐
│  镜像构建失败原因分析                                    │
└─────────────────────────────────────────────────────────────────┘

1. 语法错误
   ├── Dockerfile语法错误
   ├── 指令拼写错误
   ├── 参数错误
   └── 格式错误

2. 依赖问题
   ├── 基础镜像不存在
   ├── 依赖包不存在
   ├── 依赖包版本不兼容
   └── 依赖包下载失败

3. 网络问题
   ├── 网络连接失败
   ├── DNS解析失败
   ├── 下载超时
   └── 防火墙阻止

4. 磁盘空间不足
   ├── 磁盘空间已满
   ├── inode已满
   ├── 配额限制
   └── 存储驱动限制

5. 权限问题
   ├── 文件权限错误
   ├── 目录权限错误
   ├── 用户权限错误
   └── SELinux/AppArmor限制

6. 配置错误
   ├── 环境变量错误
   ├── 构建参数错误
   ├── 构建上下文错误
   └── .dockerignore错误
```

### 8.4.2 镜像构建失败解决方案

```bash
# 错误1：语法错误
# 错误信息：
# [+] Building 0.0s (2/2)
# ERROR [1/2] FROM docker.io/library/python:3.11
# ----
# > [1/2] FROM docker.io/library/python:3.11
# ----
# failed to solve: rpc error: code = Unknown desc = failed to solve with frontend dockerfile.v0: failed to create LLB definition: dockerfile parse error line 3: unknown instruction: FORM"

# 解决方案：
# 1. 检查Dockerfile语法
cat Dockerfile

# 2. 修正语法错误
# FORM python:3.11
# 改为
# FROM python:3.11

# 3. 使用Dockerfile linter
docker run --rm -i hadolint/hadolint < Dockerfile

# 4. 使用docker build --check
docker build --check -f Dockerfile .

# 错误2：基础镜像不存在
# 错误信息：
# [+] Building 0.0s (2/2)
# ERROR [1/2] FROM docker.io/library/python:3.11
# ----
# > [1/2] FROM docker.io/library/python:3.11
# ----
# failed to solve: pull access denied for python, repository does not exist or may require 'docker login': denied: requested access to the resource is denied

# 解决方案：
# 1. 检查基础镜像是否存在
docker images | grep python

# 2. 拉取基础镜像
docker pull python:3.11

# 3. 使用正确的镜像名称和标签
FROM python:3.11-slim

# 4. 登录Docker Hub
docker login

# 5. 使用私有镜像
FROM my-registry.com/python:3.11

# 错误3：依赖包下载失败
# 错误信息：
# ERROR [3/5] RUN pip install -r requirements.txt:
# ----
# > [3/5] RUN pip install -r requirements.txt:
# ----
# #8 0.596 Collecting flask==2.3.3
# #8 0.735   Downloading flask-2.3.3-py3-none-any.whl (96 kB)
# #8 1.452 ERROR: Could not find a version that satisfies the requirement flask==2.3.3 (from versions: none)
# #8 1.452 ERROR: No matching distribution found for flask==2.3.3

# 解决方案：
# 1. 检查requirements.txt
cat requirements.txt

# 2. 使用正确的包版本
flask==2.3.2

# 3. 使用国内镜像源
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

# 4. 使用--no-cache-dir选项
RUN pip install --no-cache-dir -r requirements.txt

# 5. 检查网络连接
docker run --rm python:3.11 pip install flask

# 错误4：网络问题
# 错误信息：
# ERROR [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# > [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# #8 0.596 Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
# #8 0.735 Get:2 http://deb.debian.org/debian bullseye/main amd64 Packages [8183 kB]
# #8 30.452 Err:2 http://deb.debian.org/debian bullseye/main amd64 Packages
# #8 30.452   Connection failed [IP: 151.101.1.148 80]
# #8 30.452 Reading package lists...
# #8 30.452 W: Failed to fetch http://deb.debian.org/debian/dists/bullseye/InRelease  Connection failed [IP: 151.101.1.148 80]
# #8 30.452 W: Some index files failed to download. They have been ignored, or old ones used instead.

# 解决方案：
# 1. 使用国内镜像源
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# 2. 使用--network host选项
docker build --network host -t myapp .

# 3. 配置代理
docker build --build-arg HTTP_PROXY=http://proxy.example.com:8080 -t myapp .

# 4. 检查网络连接
docker run --rm python:3.11 ping -c 3 deb.debian.org

# 5. 使用--no-cache选项
docker build --no-cache -t myapp .

# 错误5：磁盘空间不足
# 错误信息：
# ERROR [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# > [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 清理未使用的镜像
docker image prune -a

# 3. 清理构建缓存
docker builder prune

# 4. 清理所有未使用的资源
docker system prune -a --volumes

# 5. 增加磁盘空间
# （需要系统管理员操作）

# 6. 使用--no-cache选项
docker build --no-cache -t myapp .

# 错误6：权限问题
# 错误信息：
# ERROR [3/5] COPY . /app:
# ----
# > [3/5] COPY . /app:
# ----
# #8 0.596 ERROR: "/app" is not a directory

# 解决方案：
# 1. 检查Dockerfile
cat Dockerfile | grep COPY

# 2. 检查源路径是否存在
ls -la .

# 3. 创建目标目录
RUN mkdir -p /app

# 4. 使用正确的路径
COPY . /app/

# 5. 检查文件权限
ls -la /path/to/file

# 6. 修改文件权限
chmod 755 /path/to/file
```

---

## 8.5 调试技巧

### 8.5.1 容器调试

```bash
# 1. 查看容器日志
docker logs web-server

# 2. 查看容器日志（实时）
docker logs -f web-server

# 3. 查看容器日志（最后100行）
docker logs --tail 100 web-server

# 4. 查看容器日志（带时间戳）
docker logs -t web-server

# 5. 进入容器
docker exec -it web-server /bin/bash

# 6. 查看容器进程
docker top web-server

# 7. 查看容器资源使用
docker stats web-server

# 8. 查看容器详细信息
docker inspect web-server

# 9. 查看容器端口
docker port web-server

# 10. 查看容器变化
docker diff web-server

# 11. 查看容器文件系统
docker export web-server | tar -xvf -

# 12. 复制文件到容器
docker cp /path/to/file web-server:/path/in/container

# 13. 从容器复制文件
docker cp web-server:/path/in/container /path/to/file

# 14. 在容器中执行命令
docker exec web-server ls -la

# 15. 在容器中执行交互式命令
docker exec -it web-server /bin/bash
```

### 8.5.2 网络调试

```bash
# 1. 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 2. 查看容器IP地址
docker inspect web-server | grep IPAddress

# 3. 查看容器端口映射
docker port web-server

# 4. 查看网络列表
docker network ls

# 5. 查看网络详细信息
docker network inspect my-network

# 6. 查看容器连接的网络
docker inspect web-server | grep -A 10 Networks

# 7. 在容器中测试网络连接
docker exec web-server ping -c 3 google.com

# 8. 在容器中测试DNS解析
docker exec web-server nslookup google.com

# 9. 在容器中测试端口连接
docker exec web-server nc -zv google.com 80

# 10. 查看iptables规则
sudo iptables -L -n -v | grep DOCKER

# 11. 查看路由表
docker exec web-server ip route show

# 12. 查看网络接口
docker exec web-server ip addr show

# 13. 查看网络统计
docker exec web-server netstat -i

# 14. 查看网络连接
docker exec web-server netstat -tulpn

# 15. 抓包分析
docker exec web-server tcpdump -i eth0 -w /tmp/capture.pcap
```

### 8.5.3 存储调试

```bash
# 1. 查看容器挂载
docker inspect web-server | grep -A 20 Mounts

# 2. 查看数据卷列表
docker volume ls

# 3. 查看数据卷详细信息
docker volume inspect my-volume

# 4. 查看数据卷使用情况
docker system df -v | grep VOLUME

# 5. 查看磁盘使用情况
docker exec web-server df -h

# 6. 查看inode使用情况
docker exec web-server df -i

# 7. 查看存储驱动
docker info | grep "Storage Driver"

# 8. 查看存储驱动详细信息
docker info | grep -A 20 "Storage Driver"

# 9. 查看容器文件系统
docker exec web-server ls -la /

# 10. 查看容器文件系统使用情况
docker exec web-server du -sh /path/to/dir

# 11. 查看容器文件系统inode使用情况
docker exec web-server du -si /path/to/dir

# 12. 查看容器文件系统权限
docker exec web-server ls -ld /path/to/dir

# 13. 查看容器文件系统挂载
docker exec web-server mount | grep /path/to/dir

# 14. 查看容器文件系统空间
docker exec web-server df -h /path/to/dir

# 15. 查看容器文件系统inode
docker exec web-server df -i /path/to/dir
```

---

## 本章小结

- 容器启动失败常见原因包括镜像不存在、端口冲突、资源不足等
- 网络连接问题常见原因包括DNS解析失败、网络配置错误、防火墙规则等
- 存储访问问题常见原因包括权限问题、磁盘空间不足、挂载点错误等
- 镜像构建失败常见原因包括语法错误、依赖问题、网络问题等
- 调试技巧包括查看日志、进入容器、查看配置、测试连接等
- 使用docker logs、docker exec、docker inspect等命令进行调试
- 使用ping、nslookup、nc等工具进行网络调试
- 使用df、du、mount等命令进行存储调试

---

**恭喜！你已经完成了Docker专题的学习！**
