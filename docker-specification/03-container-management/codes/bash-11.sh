# 查看容器资源使用情况
docker stats

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   web-server          0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看特定容器的资源使用情况
docker stats web-server

# 查看容器资源使用情况（不更新）
docker stats --no-stream

# 查看容器资源使用情况（自定义格式）
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# 输出：
# CONTAINER          CPU %     MEM USAGE / LIMIT
# web-server         0.50%     128MiB / 512MiB

# 查看容器详细信息
docker inspect web-server

# 查看容器进程
docker top web-server

# 输出：
# PID                 USER                TIME                COMMAND
# 12345               root                0:00                nginx: master process
# 12346               nginx               0:00                nginx: worker process
# 12347               nginx               0:00                nginx: worker process

# 查看容器端口
docker port web-server

# 输出：
# 80/tcp -> 0.0.0.0:80

# 查看容器变化
docker diff web-server

# 输出：
# C /run
# A /run/nginx.pid
# C /var/log/nginx
# A /var/log/nginx/access.log
# A /var/log/nginx/error.log