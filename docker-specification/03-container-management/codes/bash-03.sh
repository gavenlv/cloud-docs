# 限制CPU使用率（50%）
docker run -d \
  --name limited-container \
  --cpus="0.5" \
  nginx

# 限制CPU核心数（使用2个核心）
docker run -d \
  --name limited-container \
  --cpuset-cpus="0,1" \
  nginx

# 设置CPU权重（1024是默认值）
docker run -d \
  --name limited-container \
  --cpu-shares=512 \
  nginx

# 设置CPU配额（每秒最多使用50000微秒）
docker run -d \
  --name limited-container \
  --cpu-quota=50000 \
  --cpu-period=100000 \
  nginx

# 查看容器CPU使用情况
docker stats limited-container

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   limited-container   0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 查看容器详细信息
docker inspect limited-container | grep -A 20 Cpu

# 输出：
# "CpuShares": 512,
# "CpuPeriod": 100000,
# "CpuQuota": 50000,
# "CpusetCpus": "0,1",
# "CpusetMems": "",
# "CpuPercent": 0,
# "Cpus": 0.5