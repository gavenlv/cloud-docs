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