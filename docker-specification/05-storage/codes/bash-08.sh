# 查看Docker磁盘使用情况
docker system df

# 输出：
# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
# Images          5         3         2.5GB     1.2GB (48%)
# Containers      3         2         500MB     200MB (40%)
# Local Volumes   4         2         1GB       500MB (50%)
# Build Cache     0         0         0B        0B

# 清理未使用的镜像
docker image prune

# 输出：
# Deleted Images:
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Total reclaimed space: 1.2GB

# 清理未使用的容器
docker container prune

# 输出：
# Deleted Containers:
# abc123def4567890123456789012345678901234567890123456789012345678
# abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Total reclaimed space: 200MB

# 清理未使用的数据卷
docker volume prune

# 输出：
# Deleted Volumes:
# my-volume
# my-tmpfs-volume
# ...
# Total reclaimed space: 500MB

# 清理所有未使用的资源
docker system prune -a

# 输出：
# Deleted Images:
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# deleted: sha256:abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Deleted Containers:
# abc123def4567890123456789012345678901234567890123456789012345678
# abc123def4567890123456789012345678901234567890123456789012345678
# ...
# Deleted Networks:
# my-network
# my-bridge
# ...
# Deleted Volumes:
# my-volume
# my-tmpfs-volume
# ...
# Total reclaimed space: 2GB