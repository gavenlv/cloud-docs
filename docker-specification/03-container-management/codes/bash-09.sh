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