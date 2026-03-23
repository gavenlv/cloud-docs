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