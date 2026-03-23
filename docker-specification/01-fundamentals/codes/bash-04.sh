# 运行容器并限制资源
docker run -d \
  --name limited-container \
  --cpus="0.5" \
  --memory="512m" \
  --memory-swap="512m" \
  nginx

# 参数说明：
# --cpus="0.5": 限制CPU使用率为50%
# --memory="512m": 限制内存为512MB
# --memory-swap="512m": 限制交换空间为512MB

# 查看容器资源使用
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container

# 输出（部分）：
# [
#     {
#         "Id": "abc123def456789",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Path": "/var/lib/docker/containers/abc123def456789/json",
#         "Config": {
#             "Hostname": "limited-container",
#             "CpuShares": 512,
#             "Memory": 536870912,
#             "MemorySwap": 536870912,
#             "CpuPeriod": 100000,
#             "CpuQuota": 50000
#         },
#         "HostConfig": {
#             "CpuShares": 512,
#             "Memory": 536870912,
#             "MemorySwap": 536870912,
#             "CpuPeriod": 100000,
#             "CpuQuota": 50000
#         }
#     }
# ]