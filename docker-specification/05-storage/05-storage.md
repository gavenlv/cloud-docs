# Docker存储深度解析

## 5.1 Docker存储原理

### 5.1.1 存储驱动

```
存储驱动原理：

┌─────────────────────────────────────────────────────────────────┐
│  Docker存储驱动类型                                        │
└─────────────────────────────────────────────────────────────────┘

存储驱动类型：

1. Overlay2（推荐）
   ├── 性能最好
   ├── 支持inode限制
   ├── 支持page cache
   ├── 支持硬链接
   ├── 支持XFS/Ext4
   └── 适合生产环境

2. Btrfs
   ├── 支持快照
   ├── 支持子卷
   ├── 支持压缩
   ├── 支持校验
   ├── 需要Btrfs文件系统
   └── 适合开发环境

3. ZFS
   ├── 支持快照
   ├── 支持压缩
   ├── 支持加密
   ├── 支持去重
   ├── 需要ZFS文件系统
   └── 适合企业环境

4. VFS（Virtual File System）
   ├── 简单可靠
   ├── 不需要特殊文件系统
   ├── 性能较差
   ├── 不支持分层
   └── 适合测试环境

存储驱动选择：

1. 性能优先
   ├── 选择Overlay2
   ├── 支持page cache
   ├── 支持硬链接
   └── 适合生产环境

2. 功能优先
   ├── 选择Btrfs/ZFS
   ├── 支持快照
   ├── 支持压缩
   └── 适合开发环境

3. 兼容性优先
   ├── 选择VFS
   ├── 不需要特殊文件系统
   ├── 简单可靠
   └── 适合测试环境
```

### 5.1.2 Union File System

```
Union File System原理：

┌─────────────────────────────────────────────────────────────────┐
│  Union File System工作原理                              │
└─────────────────────────────────────────────────────────────────┘

分层存储机制：

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

Union File System工作流程：

1. 读取文件
   ├── 从上到下查找文件
   ├── 找到文件后返回
   ├── 不修改文件
   └── 高效读取

2. 修改文件
   ├── 复制文件到可写层
   ├── 在可写层修改文件
   ├── 只读层保持不变
   └── 节省存储空间

3. 删除文件
   ├── 在可写层创建whiteout文件
   ├── 标记文件已删除
   ├── 只读层文件保持不变
   └── 节省存储空间

存储优化策略：

1. 层优化
   ├── 减少层数
   ├── 合并RUN指令
   ├── 清理缓存
   └── 减少镜像体积

2. 缓存优化
   ├── 利用构建缓存
   ├── 不常变化的层放前面
   ├── 常变化的层放后面
   └── 提高构建效率

3. 存储优化
   ├── 使用多阶段构建
   ├── 清理临时文件
   ├── 使用.dockerignore
   └── 减少镜像体积
```

---

## 5.2 数据卷

### 5.2.1 数据卷原理

```
数据卷原理：

┌─────────────────────────────────────────────────────────────────┐
│  数据卷工作原理                                          │
└─────────────────────────────────────────────────────────────────┘

数据卷特点：

1. 持久化存储
   ├── 独立于容器生命周期
   ├── 容器删除后数据保留
   ├── 可以跨容器共享
   └── 适合数据持久化

2. 性能优化
   ├── 绕过Union File System
   ├── 直接访问宿主机文件系统
   ├── 减少I/O开销
   └── 提高性能

3. 安全隔离
   ├── 独立的存储空间
   ├── 权限控制
   ├── 加密支持
   └── 提高安全性

数据卷类型：

1. 命名卷
   ├── 有名称的数据卷
   ├── 由Docker管理
   ├── 可以跨容器共享
   └── 适合生产环境

2. 匿名卷
   ├── 无名称的数据卷
   ├── 由Docker自动命名
   ├── 容器删除后自动删除
   └── 适合临时数据

3. 主机目录
   ├── 宿主机目录
   ├── 由用户管理
   ├── 可以直接访问
   └── 适合开发环境
```

### 5.2.2 数据卷管理

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

# 创建数据卷并设置选项
docker volume create \
  --driver local \
  --opt type=tmpfs \
  --opt device=tmpfs \
  --opt o=size=100m,uid=1000 \
  my-tmpfs-volume

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

# 输出：
# Deleted:
# volumes:
# my-volume
# my-tmpfs-volume
```

### 5.2.3 数据卷备份和恢复

```bash
# 备份数据卷
docker run --rm \
  -v my-volume:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/my-volume-backup.tar.gz /data

# 恢复数据卷
docker run --rm \
  -v my-volume:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/my-volume-backup.tar.gz --strip 1"

# 备份所有数据卷
for volume in $(docker volume ls -q); do
  docker run --rm \
    -v $volume:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/$volume-backup.tar.gz /data
done

# 恢复所有数据卷
for backup in $(ls backup/*-backup.tar.gz); do
  volume=$(basename $backup -backup.tar.gz)
  docker run --rm \
    -v $volume:/data \
    -v $(pwd):/backup \
    alpine sh -c "cd /data && tar xzf /backup/$volume-backup.tar.gz --strip 1"
done
```

---

## 5.3 绑定挂载

### 5.3.1 绑定挂载原理

```
绑定挂载原理：

┌─────────────────────────────────────────────────────────────────┐
│  绑定挂载工作原理                                        │
└─────────────────────────────────────────────────────────────────┘

绑定挂载特点：

1. 直接访问
   ├── 直接访问宿主机文件系统
   ├── 不经过Docker存储驱动
   ├── 性能最好
   └── 适合开发环境

2. 灵活性高
   ├── 可以挂载任意目录
   ├── 可以挂载单个文件
   ├── 可以设置权限
   └── 适合测试环境

3. 安全性低
   ├── 容器可以修改宿主机文件
   ├── 需要权限管理
   ├── 需要路径规划
   └── 不适合生产环境

绑定挂载vs数据卷：

1. 性能
   ├── 绑定挂载：性能最好
   ├── 数据卷：性能较好
   └── 选择：性能优先选择绑定挂载

2. 安全性
   ├── 绑定挂载：安全性低
   ├── 数据卷：安全性高
   └── 选择：安全优先选择数据卷

3. 管理性
   ├── 绑定挂载：由用户管理
   ├── 数据卷：由Docker管理
   └── 选择：管理优先选择数据卷
```

### 5.3.2 绑定挂载管理

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

# 绑定挂载并设置权限
docker run -d \
  --name web-server \
  -v /path/to/host/dir:/usr/share/nginx/html:rw,Z \
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

# 查看绑定挂载的传播属性
docker inspect web-server | grep -A 5 Propagation

# 输出：
# "Propagation": "rprivate"
```

---

## 5.4 tmpfs挂载

### 5.4.1 tmpfs挂载原理

```
tmpfs挂载原理：

┌─────────────────────────────────────────────────────────────────┐
│  tmpfs挂载工作原理                                      │
└─────────────────────────────────────────────────────────────────┘

tmpfs挂载特点：

1. 内存存储
   ├── 存储在内存中
   ├── 访问速度最快
   ├── 不占用磁盘空间
   └── 适合临时数据

2. 临时性
   ├── 容器删除后数据丢失
   ├── 不持久化
   ├── 不占用磁盘
   └── 适合缓存数据

3. 性能优化
   ├── 访问速度最快
   ├── 减少I/O开销
   ├── 提高应用性能
   └── 适合高性能应用

tmpfs挂载vs数据卷：

1. 性能
   ├── tmpfs：性能最好
   ├── 数据卷：性能较好
   └── 选择：性能优先选择tmpfs

2. 持久性
   ├── tmpfs：不持久化
   ├── 数据卷：持久化
   └── 选择：持久化优先选择数据卷

3. 容量
   ├── tmpfs：受内存限制
   ├── 数据卷：受磁盘限制
   └── 选择：大容量选择数据卷
```

### 5.4.2 tmpfs挂载管理

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

# 创建多个tmpfs挂载
docker run -d \
  --name web-server \
  --tmpfs /tmp:size=100m \
  --tmpfs /var/cache/nginx:size=50m \
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

## 5.5 存储驱动配置

### 5.5.1 配置存储驱动

```bash
# 查看当前存储驱动
docker info | grep "Storage Driver"

# 输出：
# Storage Driver: overlay2

# 配置存储驱动（需要重启Docker）
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}

# 重启Docker
sudo systemctl restart docker

# 验证存储驱动
docker info | grep "Storage Driver"

# 输出：
# Storage Driver: overlay2

# 查看存储驱动详细信息
docker info | grep -A 20 "Storage Driver"

# 输出：
# Storage Driver: overlay2
#  Backing Filesystem: extfs
#  Supports d_type: true
#  Native Overlay Diff: true
#  userxattr: false
#  Logging Driver: json-file
#  Cgroup Driver: cgroupfs
#  Cgroup Version: 2
#  Plugins:
#   Volume: local
#   Network: bridge host ipvlan macvlan null overlay
#   Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
#  Swarm: inactive
#  Runtimes: runc io.containerd.runc.v2 io.containerd.runtime.v1.linux
#  Default Runtime: runc
#  Init Binary: docker-init
#  containerd version: 1.6.0
#  runc version: 1.1.0
#  init version: de40ad0
#  Security Options:
#   apparmor
#   seccomp
#    Profile: default
```

### 5.5.2 存储驱动优化

```bash
# 配置Overlay2存储驱动
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true",
    "overlay2.size=10G"
  ]
}

# 配置Btrfs存储驱动
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "btrfs",
  "storage-opts": [
    "btrfs.min_space=1G"
  ]
}

# 配置ZFS存储驱动
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "zfs",
  "storage-opts": [
    "zfs.fsname=zpool/docker"
  ]
}

# 重启Docker
sudo systemctl restart docker

# 验证存储驱动
docker info | grep "Storage Driver"

# 输出：
# Storage Driver: overlay2
```

---

## 5.6 存储性能优化

### 5.6.1 存储性能调优

```bash
# 使用数据卷提高性能
docker run -d \
  --name web-server \
  -v my-volume:/usr/share/nginx/html \
  nginx

# 使用tmpfs提高性能
docker run -d \
  --name web-server \
  --tmpfs /tmp:size=100m \
  --tmpfs /var/cache/nginx:size=50m \
  nginx

# 使用绑定挂载提高性能
docker run -d \
  --name web-server \
  -v /path/to/host/dir:/usr/share/nginx/html \
  nginx

# 使用Overlay2存储驱动
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}

# 重启Docker
sudo systemctl restart docker

# 验证存储驱动
docker info | grep "Storage Driver"

# 输出：
# Storage Driver: overlay2
```

### 5.6.2 存储空间清理

```bash
# 查看Docker磁盘使用情况
docker system df

# 输出：
# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
# Images          5         3         2.5GB     1.2GB (48%)
# Containers      3         2         500MB     200MB (40%)
# Local Volumes   4         2         1GB       500MB (50%)
# Build Cache     0         0         0B        0B

# 清理未使用的镜像
docker image prune

# 输出：
# Deleted Images:
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Total reclaimed space: 1.2GB

# 清理未使用的容器
docker container prune

# 输出：
# Deleted Containers:
# abc123def4567890123456789012345678901234567890123456789012345678
# abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Total reclaimed space: 200MB

# 清理未使用的数据卷
docker volume prune

# 输出：
# Deleted Volumes:
# my-volume
# my-tmpfs-volume
# ...
# Total reclaimed space: 500MB

# 清理所有未使用的资源
docker system prune -a

# 输出：
# Deleted Images:
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Deleted Containers:
# abc123def4567890123456789012345678901234567890123456789012345678
# abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Deleted Networks:
# my-network
# my-bridge
# ...
# Deleted Volumes:
# my-volume
# my-tmpfs-volume
# ...
# Total reclaimed space: 2GB
```

---

## 本章小结

- Docker存储驱动包括Overlay2、Btrfs、ZFS、VFS
- Union File System提供分层存储和Copy-on-Write
- 数据卷提供持久化存储，独立于容器生命周期
- 绑定挂载提供直接访问宿主机文件系统
- tmpfs挂载提供内存存储，适合临时数据
- 存储驱动配置需要重启Docker
- 存储性能优化包括使用数据卷、tmpfs、绑定挂载
- 存储空间清理包括清理镜像、容器、数据卷

---

**下一章：Docker Compose**
