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