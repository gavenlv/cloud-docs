# 运行Nginx容器（后台模式）
docker run -d -p 80:80 --name web-server nginx

# 参数说明：
# -d: 后台模式（detached）
# -p 80:80: 端口映射（宿主机端口:容器端口）
# --name web-server: 容器名称
# nginx: 镜像名称

# 查看运行中的容器
docker ps

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 seconds ago   Up 4 seconds   0.0.0.0:80->80/tcp   web-server

# 访问Nginx
curl http://localhost

# 输出：
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# html { color-scheme: light dark; }
# body { width: 35em; margin: 0 auto;
# font-family: Tahoma, Verdana, Arial, sans-serif; }
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# <p>If you see this page, the nginx web server is successfully installed and
# working. Further configuration is required.</p>
#
# <p>For online documentation and support please refer to
# <a href="http://nginx.org/">nginx.org</a>.<br/>
# Commercial support is available at
# <a href="http://nginx.com/">nginx.com</a>.</p>
# <p><em>Thank you for using nginx.</em></p>
# </body>
# </html>

# 查看容器日志
docker logs web-server

# 输出：
# /docker-entrypoint.sh: /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
# /docker-entrypoint.sh: Listening on IPv6, address '::', port 80, http server: /
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 29
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 30
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 31
# 2024/01/15 10:30:00 [notice] 1#1: start worker process 32