# Docker最佳实践

## 7.1 镜像优化最佳实践

### 7.1.1 镜像体积优化

```
镜像优化策略：

┌─────────────────────────────────────────────────────────────────┐
│  镜像体积优化方法                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用Alpine基础镜像
   ├── 体积小（5MB vs 200MB）
   ├── 安全性高（攻击面小）
   ├── 兼容性好（glibc兼容）
   └── 示例：FROM alpine:3.18

2. 多阶段构建
   ├── 分离构建和运行时
   ├── 只包含必要文件
   ├── 减少镜像体积
   └── 示例：见6.2节

3. 清理缓存
   ├── 删除包管理器缓存
   ├── 删除临时文件
   ├── 减少镜像体积
   └── 示例：RUN apt-get clean && rm -rf /var/lib/apt/lists/*

4. 合并RUN指令
   ├── 减少镜像层数
   ├── 减少镜像体积
   ├── 提高构建效率
   └── 示例：RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

5. 使用.dockerignore
   ├── 排除不需要的文件
   ├── 减少构建上下文
   ├── 提高构建速度
   └── 示例：.dockerignore文件

6. 使用最小基础镜像
   ├── scratch：空镜像
   ├── distroless：无包管理器
   ├── 只包含运行时
   └── 示例：FROM scratch

7. 优化层顺序
   ├── 不常变化的层放前面
   ├── 常变化的层放后面
   ├── 提高缓存命中率
   └── 示例：COPY package*.json ./ 在 COPY . ./ 之前
```

### 7.1.2 镜像安全最佳实践

```
镜像安全策略：

┌─────────────────────────────────────────────────────────────────┐
│  镜像安全最佳实践                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用官方镜像
   ├── 官方镜像经过审核
   ├── 官方镜像定期更新
   ├── 官方镜像安全性高
   └── 示例：FROM nginx:latest

2. 使用特定版本标签
   ├── 避免使用latest标签
   ├── 使用具体版本号
   ├── 确保可重现构建
   └── 示例：FROM nginx:1.24.0

3. 定期更新镜像
   ├── 定期更新基础镜像
   ├── 定期更新依赖包
   ├── 修复安全漏洞
   └── 示例：docker pull nginx:1.24.0

4. 扫描镜像漏洞
   ├── 使用Docker Scout
   ├── 使用Trivy
   ├── 使用Clair
   └── 示例：docker scout cves nginx:1.24.0

5. 使用非root用户
   ├── 创建非root用户
   ├── 使用USER指令
   ├── 减少权限
   └── 示例：USER nginx

6. 使用distroless镜像
   ├── 无包管理器
   ├── 无shell
   ├── 减少攻击面
   └── 示例：FROM gcr.io/distroless/python3

7. 使用安全扫描工具
   ├── Docker Scout
   ├── Trivy
   ├── Clair
   └── Anchore
```

### 7.1.3 镜像构建优化

```dockerfile
# 优化前：传统构建
FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：900MB
```

```dockerfile
# 优化后：多阶段构建 + Alpine
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user=appuser -r requirements.txt

COPY . .
RUN python -m pip install --user .

FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

ENV PATH=/root/.local/bin:$PATH

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：125MB
```

```dockerfile
# 优化后：使用Alpine + 多阶段构建
FROM python:3.11-alpine AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user=appuser -r requirements.txt

COPY . .
RUN python -m pip install --user .

FROM python:3.11-alpine

WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

ENV PATH=/root/.local/bin:$PATH

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：50MB
```

---

## 7.2 容器安全最佳实践

### 7.2.1 容器隔离

```
容器隔离策略：

┌─────────────────────────────────────────────────────────────────┐
│  容器隔离最佳实践                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用非root用户
   ├── 创建非root用户
   ├── 使用USER指令
   ├── 减少权限
   └── 示例：USER nginx

2. 限制容器权限
   ├── 删除所有capabilities
   ├── 只添加必要的capabilities
   ├── 使用--cap-drop和--cap-add
   └── 示例：--cap-drop ALL --cap-add NET_BIND_SERVICE

3. 使用只读文件系统
   ├── 使用--read-only标志
   ├── 只挂载可写目录
   ├── 防止文件系统修改
   └── 示例：--read-only --tmpfs /tmp --tmpfs /run

4. 使用安全选项
   ├── no-new-privileges
   ├── 禁止获取新权限
   ├── 防止权限提升
   └── 示例：--security-opt no-new-privileges

5. 使用AppArmor/SELinux
   ├── 配置AppArmor配置文件
   ├── 配置SELinux上下文
   ├── 限制容器访问
   └── 示例：--security-opt apparmor=docker-default

6. 使用seccomp
   ├── 配置seccomp配置文件
   ├── 限制系统调用
   ├── 减少攻击面
   └── 示例：--security-opt seccomp=default.json

7. 使用user namespaces
   ├── 隔离用户ID
   ├── 容器内root不是真正的root
   ├── 提高安全性
   └── 示例：--userns-remap=default
```

### 7.2.2 容器资源限制

```
资源限制策略：

┌─────────────────────────────────────────────────────────────────┐
│  容器资源限制最佳实践                                    │
└─────────────────────────────────────────────────────────────────┘

1. CPU限制
   ├── 限制CPU使用率
   ├── 限制CPU核心数
   ├── 设置CPU权重
   └── 示例：--cpus="0.5" --cpu-shares=512

2. 内存限制
   ├── 限制内存使用量
   ├── 限制交换空间
   ├── 设置内存预留
   └── 示例：--memory="512m" --memory-swap="512m"

3. 存储限制
   ├── 限制磁盘读取速度
   ├── 限制磁盘写入速度
   ├── 限制磁盘IOPS
   └── 示例：--device-read-bps /dev/sda:10mb

4. 进程限制
   ├── 限制进程数量
   ├── 防止fork炸弹
   ├── 提高稳定性
   └--pids-limit 100

5. 重启策略
   ├── 设置重启策略
   ├── 自动恢复失败
   ├── 提高可用性
   └--restart always
```

### 7.2.3 容器网络安全

```
网络安全策略：

┌─────────────────────────────────────────────────────────────────┐
│  容器网络安全最佳实践                                    │
└─────────────────────────────────────────────────────────────────┘

1. 使用自定义网络
   ├── 创建自定义网络
   ├── 网络隔离
   ├── 服务发现
   └--network my-network

2. 限制端口暴露
   ├── 只暴露必要端口
   ├── 使用特定端口
   ├── 避免暴露所有端口
   └-p 80:80

3. 使用网络策略
   ├── 配置网络策略
   ├── 限制容器间通信
   ├── 提高安全性
   └--network-alias my-alias

4. 使用TLS加密
   ├── 启用TLS加密
   ├── 使用证书
   ├── 加密通信
   └--tlsverify

5. 使用防火墙
   ├── 配置防火墙规则
   ├── 限制访问
   ├── 提高安全性
   └iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

---

## 7.3 性能优化最佳实践

### 7.3.1 容器性能优化

```
性能优化策略：

┌─────────────────────────────────────────────────────────────────┐
│  容器性能优化方法                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用高效的基础镜像
   ├── 使用Alpine镜像
   ├── 使用distroless镜像
   ├── 减少镜像体积
   └── 示例：FROM alpine:3.18

2. 优化镜像层数
   ├── 合并RUN指令
   ├── 减少镜像层数
   ├── 提高构建效率
   └--squash

3. 使用缓存
   ├── 利用构建缓存
   ├── 优化层顺序
   ├── 提高构建速度
   └--cache-from

4. 使用多阶段构建
   ├── 分离构建和运行时
   ├── 只包含必要文件
   ├── 减少镜像体积
   └--target

5. 使用资源限制
   ├── 设置CPU限制
   ├── 设置内存限制
   ├── 提高资源利用率
   └--cpus="0.5" --memory="512m"

6. 使用存储优化
   ├── 使用数据卷
   ├── 使用tmpfs
   ├── 提高I/O性能
   └-v my-volume:/data
```

### 7.3.2 网络性能优化

```
网络性能优化策略：

┌─────────────────────────────────────────────────────────────────┐
│  网络性能优化方法                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用host网络
   ├── 共享宿主机网络
   ├── 性能最好
   ├── 无网络隔离
   └--network host

2. 使用overlay网络
   ├── 跨主机通信
   ├── 使用VXLAN封装
   ├── 支持加密
   └--network overlay

3. 使用macvlan网络
   ├── 直接连接物理网络
   ├── 性能较好
   ├── 需要配置
   └--network macvlan

4. 使用IPv6
   ├── 使用IPv6地址
   ├── 减少NAT开销
   ├── 提高性能
   └--ipv6

5. 优化网络配置
   ├── 调整MTU
   ├── 调整TCP参数
   ├── 提高性能
   └--opt com.docker.network.driver.mtu=1400
```

### 7.3.3 存储性能优化

```
存储性能优化策略：

┌─────────────────────────────────────────────────────────────────┐
│  存储性能优化方法                                        │
└─────────────────────────────────────────────────────────────────┘

1. 使用Overlay2存储驱动
   ├── 性能最好
   ├── 支持inode限制
   ├── 支持page cache
   └--storage-driver overlay2

2. 使用数据卷
   ├── 绕过Union File System
   ├── 直接访问宿主机文件系统
   ├── 减少I/O开销
   └-v my-volume:/data

3. 使用tmpfs
   ├── 存储在内存中
   ├── 访问速度最快
   ├── 适合临时数据
   └--tmpfs /tmp

4. 使用绑定挂载
   ├── 直接访问宿主机文件系统
   ├── 性能最好
   ├── 适合开发环境
   └-v /path/to/host/dir:/data

5. 优化存储配置
   ├── 调整存储驱动参数
   ├── 调整文件系统参数
   ├── 提高性能
   └--storage-opt overlay2.size=10G
```

---

## 7.4 监控和日志

### 7.4.1 容器监控

```bash
# 使用docker stats监控容器
docker stats

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   web-server          0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 使用docker inspect查看容器详细信息
docker inspect web-server

# 输出：
# [
#     {
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Path": "/docker-entrypoint.sh",
#         "Args": [
#             "nginx",
#             "-g",
#             "daemon off;"
#         ],
#         "State": {
#             "Status": "running",
#             "Running": true,
#             "Paused": false,
#             "Restarting": false,
#             "OOMKilled": false,
#             "Dead": false,
#             "Pid": 12345,
#             "ExitCode": 0,
#             "Error": "",
#             "StartedAt": "2024-01-15T10:30:00.000000000Z",
#             "FinishedAt": "0001-01-01T00:00:00Z"
#         },
#         "Image": "sha256:abc123def4567890123456789012345678901234567890123456789012345678",
#         "ResolvConfPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/resolv.conf",
#         "HostnamePath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/hostname",
#         "HostsPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/hosts",
#         "LogPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/abc123def4567890123456789012345678901234567890123456789012345678-json.log",
#         "Name": "/web-server",
#         "RestartCount": 0,
#         "Driver": "overlay2",
#         "Platform": "linux",
#         "MountLabel": "",
#         "ProcessLabel": "",
#         "AppArmorProfile": "",
#         "ExecIDs": null,
#         "HostConfig": {
#             "Binds": null,
#             "ContainerIDFile": "",
#             "LogConfig": {
#                 "Type": "json-file",
#                 "Config": {}
#             },
#             "NetworkMode": "default",
#             "PortBindings": {
#                 "80/tcp": [
#                     {
#                         "HostIp": "",
#                         "HostPort": "80"
#                     }
#                 ]
#             },
#             "RestartPolicy": {
#                 "Name": "no",
#                 "MaximumRetryCount": 0
#             },
#             "AutoRemove": false,
#             "VolumeDriver": "",
#             "VolumesFrom": null,
#             "CapAdd": null,
#             "CapDrop": null,
#             "CgroupnsMode": "host",
#             "Dns": [],
#             "DnsOptions": [],
#             "DnsSearch": [],
#             "ExtraHosts": null,
#             "GroupAdd": null,
#             "IpcMode": "private",
#             "Cgroup": "",
#             "Links": null,
#             "OomScoreAdj": 0,
#             "PidMode": "",
#             "Privileged": false,
#             "PublishAllPorts": false,
#             "ReadonlyRootfs": false,
#             "SecurityOpt": null,
#             "UTSMode": "",
#             "UsernsMode": "",
#             "ShmSize": 67108864,
#             "Runtime": "runc",
#             "ConsoleSize": [
#                 0,
#                 0
#             ],
#             "Isolation": "",
#             "CpuShares": 0,
#             "Memory": 0,
#             "NanoCpus": 0,
#             "CgroupParent": "",
#             "BlkioWeight": 0,
#             "BlkioWeightDevice": [],
#             "BlkioDeviceReadBps": null,
#             "BlkioDeviceWriteBps": null,
#             "BlkioDeviceReadIOps": null,
#             "BlkioDeviceWriteIOps": null,
#             "CpuPeriod": 0,
#             "CpuQuota": 0,
#             "CpuRealtimePeriod": 0,
#             "CpuRealtimeRuntime": 0,
#             "CpusetCpus": "",
#             "CpusetMems": "",
#             "Devices": [],
#             "DeviceCgroupRules": null,
#             "DeviceRequests": null,
#             "KernelMemory": 0,
#             "KernelMemoryTCP": 0,
#             "MemoryReservation": 0,
#             "MemorySwap": 0,
#             "MemorySwappiness": null,
#             "OomKillDisable": false,
#             "PidsLimit": null,
#             "Ulimits": null,
#             "CpuCount": 0,
#             "CpuPercent": 0,
#             "IOMaximumIOps": 0,
#             "IOMaximumBandwidth": 0,
#             "MaskedPaths": [
#                 "/proc/asound",
#                 "/proc/acpi",
#                 "/proc/kcore",
#                 "/proc/keys",
#                 "/proc/latency_stats",
#                 "/proc/timer_list",
#                 "/proc/timer_stats",
#                 "/proc/sched_debug",
#                 "/proc/scsi",
#                 "/sys/firmware"
#             ],
#             "ReadonlyPaths": [
#                 "/proc/bus",
#                 "/proc/fs",
#                 "/proc/irq",
#                 "/proc/sys",
#                 "/proc/sysrq-trigger"
#             ]
#         },
#         "GraphDriver": {
#             "Data": {
#                 "LowerDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678-init/diff:/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/diff",
#                 "MergedDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged",
#                 "UpperDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/diff",
#                 "WorkDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/work"
#             },
#             "Name": "overlay2"
#         },
#         "Mounts": [],
#         "Config": {
#             "Hostname": "abc123def4567890",
#             "Domainname": "",
#             "User": "",
#             "AttachStdin": false,
#             "AttachStdout": true,
#             "AttachStderr": true,
#             "ExposedPorts": {
#                 "80/tcp": {}
#             },
#             "Tty": false,
#             "OpenStdin": false,
#             "StdinOnce": false,
#             "Env": [
#                 "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
#                 "NGINX_VERSION=1.24.0",
#                 "NJS_VERSION=0.7.12",
#                 "PKG_RELEASE=1~bullseye"
#             ],
#             "Cmd": [
#                 "nginx",
#                 "-g",
#                 "daemon off;"
#             ],
#             "Image": "nginx:latest",
#             "Volumes": null,
#             "WorkingDir": "",
#             "Entrypoint": [
#                 "/docker-entrypoint.sh"
#             ],
#             "OnBuild": null,
#             "Labels": {
#                 "maintainer": "NGINX Docker Maintainers <docker-maint@nginx.com>"
#             },
#             "StopSignal": "SIGQUIT"
#         },
#         "NetworkSettings": {
#             "Bridge": "",
#             "SandboxID": "abc123def4567890123456789012345678901234567890123456789012345678",
#             "HairpinMode": false,
#             "LinkLocalIPv6Address": "",
#             "LinkLocalIPv6PrefixLen": 0,
#             "Ports": {
#                 "80/tcp": [
#                     {
#                         "HostIp": "0.0.0.0",
#                         "HostPort": "80"
#                     }
#                 ]
#             },
#             "SandboxKey": "/var/run/docker/netns/abc123def4567890123456789012345678901234567890123456789012345678",
#             "SecondaryIPAddresses": null,
#             "SecondaryIPv6Addresses": null,
#             "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#             "Gateway": "172.17.0.1",
#             "GlobalIPv6Address": "",
#             "GlobalIPv6PrefixLen": 0,
#             "IPAddress": "172.17.0.2",
#             "IPPrefixLen": 16,
#             "IPv6Gateway": "",
#             "GlobalIPv6Address": "",
#             "GlobalIPv6PrefixLen": 0,
#             "IPAddress": "172.17.0.2",
#             "IPPrefixLen": 16,
#             "IPv6Gateway": "",
#             "MacAddress": "02:42:ac:11:00:02",
#             "Networks": {
#                 "bridge": {
#                     "IPAMConfig": null,
#                     "Links": null,
#                     "Aliases": null,
#                     "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#                     "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#                     "Gateway": "172.17.0.1",
#                     "IPAddress": "172.17.0.2",
#                     "IPPrefixLen": 16,
#                     "IPv6Gateway": "",
#                     "GlobalIPv6Address": "",
#                     "GlobalIPv6PrefixLen": 0,
#                     "MacAddress": "02:42:ac:11:00:02",
#                     "DriverOpts": null
#                 }
#             }
#         }
#     }
# ]

# 使用Prometheus监控容器
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

# 使用Grafana可视化监控数据
docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana
```

### 7.4.2 容器日志

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

# 使用ELK Stack收集日志
docker run -d \
  --name elasticsearch \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  elasticsearch:8.0.0

docker run -d \
  --name kibana \
  -p 5601:5601 \
  --link elasticsearch:elasticsearch \
  kibana:8.0.0

docker run -d \
  --name logstash \
  --link elasticsearch:elasticsearch \
  -v /path/to/logstash.conf:/usr/share/logstash/pipeline/logstash.conf \
  logstash:8.0.0
```

---

## 7.5 CI/CD集成

### 7.5.1 GitHub Actions

```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          username/myapp:latest
          username/myapp:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Scan image for vulnerabilities
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: username/myapp:latest
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

### 7.5.2 GitLab CI

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  DOCKER_LATEST: $CI_REGISTRY_IMAGE:latest

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE -t $DOCKER_LATEST .
    - docker push $DOCKER_IMAGE
    - docker push $DOCKER_LATEST
  only:
    - main

test:
  stage: test
  image: $DOCKER_IMAGE
  services:
    - postgres:latest
    - redis:latest
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: postgresql://testuser:testpass@postgres:5432/testdb
    REDIS_URL: redis://redis:6379/0
  script:
    - pip install pytest
    - pytest tests/
  only:
    - main

deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker pull $DOCKER_IMAGE
    - docker stop myapp || true
    - docker rm myapp || true
    - docker run -d --name myapp -p 80:80 $DOCKER_IMAGE
  only:
    - main
  when: manual
```

---

## 本章小结

- 镜像优化包括使用Alpine、多阶段构建、清理缓存等
- 镜像安全包括使用官方镜像、特定版本、定期更新等
- 容器安全包括使用非root用户、限制权限、网络隔离等
- 性能优化包括使用高效镜像、优化网络、优化存储等
- 监控和日志包括使用docker stats、docker logs、Prometheus等
- CI/CD集成包括GitHub Actions、GitLab CI等

---

**下一章：Docker常见错误处理**
