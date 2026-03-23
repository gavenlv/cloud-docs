# 限制磁盘读取速度（10MB/s）
docker run -d \
  --name limited-container \
  --device-read-bps /dev/sda:10mb \
  nginx

# 限制磁盘写入速度（10MB/s）
docker run -d \
  --name limited-container \
  --device-write-bps /dev/sda:10mb \
  nginx

# 限制磁盘读取IOPS（1000）
docker run -d \
  --name limited-container \
  --device-read-iops /dev/sda:1000 \
  nginx

# 限制磁盘写入IOPS（1000）
docker run -d \
  --name limited-container \
  --device-write-iops /dev/sda:1000 \
  nginx

# 查看容器磁盘使用情况
docker stats limited-container --no-stream --format "table {{.Container}}\t{{.BlockIO}}"

# 输出：
# CONTAINER          BLOCK I/O
# limited-container  0B / 0B