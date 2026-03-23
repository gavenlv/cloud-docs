# 创建容器但不启动
docker create --name my-container nginx

# 启动已创建的容器
docker start my-container

# 查看容器状态
docker ps -a

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 minutes ago   Up 5 seconds   0.0.0.0:80->80/tcp   my-container

# 停止容器（优雅停止）
docker stop my-container

# 查看容器状态
docker ps -a

# 输出：
# CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS                     PORTS                NAMES
# abc123def456   nginx     "/docker-entrypoint.…"   5 minutes ago   Exited (0) 2 seconds ago   0.0.0.0:80->80/tcp   my-container

# 强制停止容器
docker kill my-container

# 重启容器
docker restart my-container

# 暂停容器
docker pause my-container

# 恢复容器
docker unpause my-container

# 删除容器
docker rm my-container

# 强制删除运行中的容器
docker rm -f my-container