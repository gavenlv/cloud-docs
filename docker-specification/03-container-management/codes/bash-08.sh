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