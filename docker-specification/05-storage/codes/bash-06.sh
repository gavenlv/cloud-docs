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