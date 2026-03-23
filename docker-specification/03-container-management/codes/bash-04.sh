# 限制内存使用（512MB）
docker run -d \
  --name limited-container \
  --memory="512m" \
  nginx

# 限制内存和交换空间（各512MB）
docker run -d \
  --name limited-container \
  --memory="512m" \
  --memory-swap="512m" \
  nginx

# 限制内存预留（256MB）
docker run -d \
  --name limited-container \
  --memory-reservation="256m" \
  nginx

# 禁用交换空间
docker run -d \
  --name limited-container \
  --memory="512m" \
  --memory-swap="512m" \
  --memory-swappiness=0 \
  nginx

# 设置OOM优先级（-1000到1000，默认0）
docker run -d \
  --name limited-container \
  --memory="512m" \
  --oom-kill-disable \
  nginx

# 查看容器内存使用情况
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container | grep -A 20 Memory

# 输出：
# "Memory": 536870912,
# "MemoryReservation": 268435456,
# "MemorySwap": 536870912,
# "MemorySwappiness": 0,
# "OomKillDisable": true,
# "OomScoreAdj": 0