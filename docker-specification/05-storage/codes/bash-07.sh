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