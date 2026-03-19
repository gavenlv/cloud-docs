# Docker容器管理深度解析

## 3.1 容器生命周期管理

### 3.1.1 容器状态机

```
容器状态转换：

┌─────────────────────────────────────────────────────────────────┐
│  容器状态机                                              │
└─────────────────────────────────────────────────────────────────┘

状态定义：

1. Created（已创建）
   ├── 容器已创建但未启动
   ├── 文件系统已准备
   ├── 配置已加载
   └── 等待启动命令

2. Running（运行中）
   ├── 容器正在运行
   ├── 主进程正在执行
   ├── 可以接收请求
   └── 可以执行命令

3. Paused（已暂停）
   ├── 容器已暂停
   ├── 进程已冻结
   ├── 内存已保存
   └── 可以恢复

4. Restarting（重启中）
   ├── 容器正在重启
   ├── 主进程已退出
   ├── 正在重新启动
   └── 受重启策略控制

5. Exited（已退出）
   ├── 容器已退出
   ├── 主进程已终止
   ├── 文件系统仍存在
   └── 可以重新启动

6. Dead（已死亡）
   ├── 容器已死亡
   ├── 无法恢复
   ├── 需要删除重建
   └── 通常由错误导致

状态转换：

Created → Running
  ├── docker start
  ├── docker run
  └── docker restart

Running → Paused
  ├── docker pause
  └── 保存内存状态

Paused → Running
  ├── docker unpause
  └── 恢复内存状态

Running → Exited
  ├── 主进程正常退出
  ├── 主进程异常退出
  ├── docker stop
  └── docker kill

Exited → Running
  ├── docker start
  └── docker restart

Running → Restarting
  ├── 主进程异常退出
  ├── 受重启策略控制
  └── 自动重启

Restarting → Running
  ├── 重启成功
  └── 继续运行

Restarting → Exited
  ├── 重启失败
  ├── 达到最大重试次数
  └── 停止重启

Exited → Dead
  ├── 容器无法恢复
  ├── 文件系统损坏
  └── 需要删除重建
```

### 3.1.2 容器启动和停止

```bash
# 创建容器但不启动
docker create --name my-container nginx

# 启动已创建的容器
docker start my-container

# 查看容器状态
docker ps -a

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 minutes ago   Up 5 seconds   0.0.0.0:80->80/tcp   my-container

# 停止容器（优雅停止）
docker stop my-container

# 查看容器状态
docker ps -a

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS                     PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 minutes ago   Exited (0) 2 seconds ago   0.0.0.0:80->80/tcp   my-container

# 强制停止容器
docker kill my-container

# 重启容器
docker restart my-container

# 暂停容器
docker pause my-container

# 恢复容器
docker unpause my-container

# 删除容器
docker rm my-container

# 强制删除运行中的容器
docker rm -f my-container
```

### 3.1.3 容器重启策略

```
重启策略：

┌─────────────────────────────────────────────────────────────────┐
│  重启策略类型                                            │
└─────────────────────────────────────────────────────────────────┘

1. no（默认）
   ├── 不自动重启
   ├── 容器退出后保持退出状态
   ├── 适合调试容器
   └── 示例：--restart no

2. on-failure
   ├── 仅在非零退出时重启
   ├── 可以指定最大重启次数
   ├── 适合应用容器
   └── 示例：--restart on-failure:5

3. always
   ├── 总是重启容器
   ├── 即使手动停止也会重启
   ├── 适合服务容器
   └── 示例：--restart always

4. unless-stopped
   ├── 总是重启容器
   ├── 手动停止后不会重启
   ├── 适合服务容器
   └── 示例：--restart unless-stopped

重启策略选择：

1. 开发环境
   ├── 使用no策略
   ├── 方便调试
   ├── 快速迭代
   └── 示例：--restart no

2. 测试环境
   ├── 使用on-failure策略
   ├── 自动恢复失败
   ├── 限制重启次数
   └── 示例：--restart on-failure:3

3. 生产环境
   ├── 使用always策略
   ├── 保证高可用
   ├── 自动恢复
   └── 示例：--restart always

4. 批处理任务
   ├── 使用no策略
   ├── 任务完成后退出
   ├── 不需要重启
   └── 示例：--restart no
```

```bash
# 创建容器并设置重启策略
docker run -d \
  --name web-server \
  --restart always \
  -p 80:80 \
  nginx

# 创建容器并设置on-failure重启策略
docker run -d \
  --name web-server \
  --restart on-failure:5 \
  -p 80:80 \
  nginx

# 查看容器重启策略
docker inspect web-server | grep -A 10 RestartPolicy

# 输出：
# "RestartPolicy": {
#     "Name": "always",
#     "MaximumRetryCount": 0
# }

# 修改容器重启策略
docker update --restart unless-stopped web-server

# 验证修改
docker inspect web-server | grep -A 10 RestartPolicy

# 输出：
# "RestartPolicy": {
#     "Name": "unless-stopped",
#     "MaximumRetryCount": 0
# }
```

---

## 3.2 容器资源管理

### 3.2.1 CPU资源限制

```bash
# 限制CPU使用率（50%）
docker run -d \
  --name limited-container \
  --cpus="0.5" \
  nginx

# 限制CPU核心数（使用2个核心）
docker run -d \
  --name limited-container \
  --cpuset-cpus="0,1" \
  nginx

# 设置CPU权重（1024是默认值）
docker run -d \
  --name limited-container \
  --cpu-shares=512 \
  nginx

# 设置CPU配额（每秒最多使用50000微秒）
docker run -d \
  --name limited-container \
  --cpu-quota=50000 \
  --cpu-period=100000 \
  nginx

# 查看容器CPU使用情况
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container | grep -A 20 Cpu

# 输出：
# "CpuShares": 512,
# "CpuPeriod": 100000,
# "CpuQuota": 50000,
# "CpusetCpus": "0,1",
# "CpusetMems": "",
# "CpuPercent": 0,
# "Cpus": 0.5
```

### 3.2.2 内存资源限制

```bash
# 限制内存使用（512MB）
docker run -d \
  --name limited-container \
  --memory="512m" \
  nginx

# 限制内存和交换空间（各512MB）
docker run -d \
  --name limited-container \
  --memory="512m" \
  --memory-swap="512m" \
  nginx

# 限制内存预留（256MB）
docker run -d \
  --name limited-container \
  --memory-reservation="256m" \
  nginx

# 禁用交换空间
docker run -d \
  --name limited-container \
  --memory="512m" \
  --memory-swap="512m" \
  --memory-swappiness=0 \
  nginx

# 设置OOM优先级（-1000到1000，默认0）
docker run -d \
  --name limited-container \
  --memory="512m" \
  --oom-kill-disable \
  nginx

# 查看容器内存使用情况
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container | grep -A 20 Memory

# 输出：
# "Memory": 536870912,
# "MemoryReservation": 268435456,
# "MemorySwap": 536870912,
# "MemorySwappiness": 0,
# "OomKillDisable": true,
# "OomScoreAdj": 0
```

### 3.2.3 存储资源限制

```bash
# 限制磁盘读取速度（10MB/s）
docker run -d \
  --name limited-container \
  --device-read-bps /dev/sda:10mb \
  nginx

# 限制磁盘写入速度（10MB/s）
docker run -d \
  --name limited-container \
  --device-write-bps /dev/sda:10mb \
  nginx

# 限制磁盘读取IOPS（1000）
docker run -d \
  --name limited-container \
  --device-read-iops /dev/sda:1000 \
  nginx

# 限制磁盘写入IOPS（1000）
docker run -d \
  --name limited-container \
  --device-write-iops /dev/sda:1000 \
  nginx

# 查看容器磁盘使用情况
docker stats limited-container --no-stream --format "table {{.Container}}\t{{.BlockIO}}"

# 输出：
# CONTAINER          BLOCK I/O
# limited-container  0B / 0B
```

---

## 3.3 容器网络配置

### 3.1.1 容器网络模式

```
网络模式：

┌─────────────────────────────────────────────────────────────────┐
│  Docker网络模式                                          │
└─────────────────────────────────────────────────────────────────┘

1. Bridge（默认）
   ├── 创建独立的网络命名空间
   ├── 使用docker0网桥
   ├── 容器可以通过IP通信
   ├── 可以通过端口映射访问外部
   └── 示例：--network bridge

2. Host
   ├── 共享宿主机网络命名空间
   ├── 容器使用宿主机IP
   ├── 性能最好
   ├── 没有网络隔离
   └── 示例：--network host

3. None
   ├── 不配置网络
   ├── 只有loopback接口
   ├── 完全隔离
   ├── 需要手动配置
   └── 示例：--network none

4. Container
   ├── 共享另一个容器的网络
   ├── 共享网络命名空间
   ├── 可以通过localhost通信
   ├── 适合容器间通信
   └── 示例：--network container:other-container

5. 自定义网络
   ├── 创建自定义网络
   ├── 支持多种驱动
   ├── 支持网络隔离
   ├── 支持服务发现
   └── 示例：--network my-network
```

```bash
# 使用bridge网络模式（默认）
docker run -d \
  --name web-server \
  --network bridge \
  -p 80:80 \
  nginx

# 使用host网络模式
docker run -d \
  --name web-server \
  --network host \
  nginx

# 使用none网络模式
docker run -d \
  --name web-server \
  --network none \
  nginx

# 使用container网络模式
docker run -d \
  --name app-container \
  nginx

docker run -d \
  --name sidecar-container \
  --network container:app-container \
  busybox sleep 3600

# 创建自定义网络
docker network create my-network

# 使用自定义网络
docker run -d \
  --name web-server \
  --network my-network \
  -p 80:80 \
  nginx

# 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 输出：
# "Networks": {
#     "my-network": {
#         "IPAMConfig": null,
#         "Links": null,
#         "Aliases": [
#             "web-server"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.18.0.1",
#         "IPAddress": "172.18.0.2",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:12:00:02",
#         "DriverOpts": null
#     }
# }
```

### 3.3.2 端口映射

```bash
# 映射单个端口（宿主机端口:容器端口）
docker run -d \
  --name web-server \
  -p 80:80 \
  nginx

# 映射多个端口
docker run -d \
  --name web-server \
  -p 80:80 \
  -p 443:443 \
  nginx

# 映射随机端口
docker run -d \
  --name web-server \
  -p 80 \
  nginx

# 查看端口映射
docker port web-server

# 输出：
# 80/tcp -> 0.0.0.0:32768

# 绑定到特定接口
docker run -d \
  --name web-server \
  -p 127.0.0.1:80:80 \
  nginx

# 绑定到特定接口和端口
docker run -d \
  --name web-server \
  -p 192.168.1.100:8080:80 \
  nginx

# 映射UDP端口
docker run -d \
  --name dns-server \
  -p 53:53/udp \
  dns-server

# 映射端口范围
docker run -d \
  --name web-server \
  -p 8000-8010:8000-8010 \
  nginx
```

---

## 3.4 容器数据持久化

### 3.4.1 数据卷

```bash
# 创建数据卷
docker volume create my-volume

# 查看数据卷
docker volume ls

# 输出：
# DRIVER    VOLUME NAME
# local     my-volume

# 查看数据卷详细信息
docker volume inspect my-volume

# 输出：
# [
#     {
#         "CreatedAt": "2024-01-15T10:30:00Z",
#         "Driver": "local",
#         "Labels": null,
#         "Mountpoint": "/var/lib/docker/volumes/my-volume/_data",
#         "Name": "my-volume",
#         "Options": {},
#         "Scope": "local"
#     }
# ]

# 使用数据卷
docker run -d \
  --name web-server \
  -v my-volume:/usr/share/nginx/html \
  nginx

# 挂载多个数据卷
docker run -d \
  --name web-server \
  -v my-volume:/usr/share/nginx/html \
  -v my-logs:/var/log/nginx \
  nginx

# 创建只读数据卷
docker run -d \
  --name web-server \
  -v my-volume:/usr/share/nginx/html:ro \
  nginx

# 查看容器挂载的数据卷
docker inspect web-server | grep -A 20 Mounts

# 输出：
# "Mounts": [
#     {
#         "Type": "volume",
#         "Name": "my-volume",
#         "Source": "/var/lib/docker/volumes/my-volume/_data",
#         "Destination": "/usr/share/nginx/html",
#         "Driver": "local",
#         "Mode": "rw",
#         "RW": true,
#         "Propagation": ""
#     }
# ]

# 删除数据卷
docker volume rm my-volume

# 删除未使用的数据卷
docker volume prune
```

### 3.4.2 绑定挂载

```bash
# 绑定挂载宿主机目录
docker run -d \
  --name web-server \
  -v /path/to/host/dir:/usr/share/nginx/html \
  nginx

# 绑定挂载单个文件
docker run -d \
  --name web-server \
  -v /path/to/host/file:/etc/nginx/nginx.conf \
  nginx

# 创建只读绑定挂载
docker run -d \
  --name web-server \
  -v /path/to/host/dir:/usr/share/nginx/html:ro \
  nginx

# 查看容器挂载的绑定挂载
docker inspect web-server | grep -A 20 Mounts

# 输出：
# "Mounts": [
#     {
#         "Type": "bind",
#         "Source": "/path/to/host/dir",
#         "Destination": "/usr/share/nginx/html",
#         "Mode": "rw",
#         "RW": true,
#         "Propagation": "rprivate"
#     }
# ]
```

### 3.4.3 tmpfs挂载

```bash
# 创建tmpfs挂载
docker run -d \
  --name web-server \
  --tmpfs /tmp \
  nginx

# 创建tmpfs挂载并设置大小
docker run -d \
  --name web-server \
  --tmpfs /tmp:size=100m \
  nginx

# 创建tmpfs挂载并设置权限
docker run -d \
  --name web-server \
  --tmpfs /tmp:size=100m,mode=1777 \
  nginx

# 查看容器挂载的tmpfs
docker inspect web-server | grep -A 20 Mounts

# 输出：
# "Mounts": [
#     {
#         "Type": "tmpfs",
#         "Tmpfs": {
#             "Size": 104857600,
#             "Mode": 1777
#         },
#         "Destination": "/tmp",
#         "Mode": "",
#         "RW": true,
#         "Propagation": ""
#     }
# ]
```

---

## 3.5 容器监控和日志

### 3.5.1 容器监控

```bash
# 查看容器资源使用情况
docker stats

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   web-server          0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看特定容器的资源使用情况
docker stats web-server

# 查看容器资源使用情况（不更新）
docker stats --no-stream

# 查看容器资源使用情况（自定义格式）
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# 输出：
# CONTAINER          CPU %     MEM USAGE / LIMIT
# web-server         0.50%     128MiB / 512MiB

# 查看容器详细信息
docker inspect web-server

# 查看容器进程
docker top web-server

# 输出：
# PID                 USER                TIME                COMMAND
# 12345               root                0:00                nginx: master process
# 12346               nginx               0:00                nginx: worker process
# 12347               nginx               0:00                nginx: worker process

# 查看容器端口
docker port web-server

# 输出：
# 80/tcp -> 0.0.0.0:80

# 查看容器变化
docker diff web-server

# 输出：
# C /run
# A /run/nginx.pid
# C /var/log/nginx
# A /var/log/nginx/access.log
# A /var/log/nginx/error.log
```

### 3.5.2 容器日志

```bash
# 查看容器日志
docker logs web-server

# 输出：
# /docker-entrypoint.sh: /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# /docker-entrypoint.sh: Listening on IPv6, address '::', port 80, http server: /
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 29
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 30

# 查看容器日志（实时）
docker logs -f web-server

# 查看容器日志（最后100行）
docker logs --tail 100 web-server

# 查看容器日志（最后10分钟）
docker logs --since 10m web-server

# 查看容器日志（时间范围）
docker logs --since 2024-01-15T10:00:00 --until 2024-01-15T11:00:00 web-server

# 查看容器日志（带时间戳）
docker logs -t web-server

# 输出：
# 2024-01-15T10:30:00.123456789Z /docker-entrypoint.sh: /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# 2024-01-15T10:30:00.123456789Z /docker-entrypoint.sh: Listening on IPv6, address '::', port 80, http server: /

# 配置容器日志驱动
docker run -d \
  --name web-server \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx

# 查看容器日志配置
docker inspect web-server | grep -A 10 LogConfig

# 输出：
# "LogConfig": {
#     "Type": "json-file",
#     "Config": {
#         "max-size": "10m",
#         "max-file": "3"
#     }
# }
```

---

## 本章小结

- 容器有6种状态：Created、Running、Paused、Restarting、Exited、Dead
- 容器重启策略：no、on-failure、always、unless-stopped
- 容器资源限制：CPU、内存、存储
- 容器网络模式：bridge、host、none、container、自定义
- 容器数据持久化：数据卷、绑定挂载、tmpfs挂载
- 容器监控：docker stats、docker inspect、docker top
- 容器日志：docker logs、日志驱动、日志配置

---

**下一章：Docker网络**
