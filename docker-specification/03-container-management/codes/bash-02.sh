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