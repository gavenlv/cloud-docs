# 查看优化前的镜像
docker images my-python-app:old

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    old       abc123def456   10 minutes ago  900MB

# 查看优化后的镜像
docker images my-python-app:optimized

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    optimized abc123def456   5 minutes ago   125MB

# 优化效果：
# - 减少86%的镜像体积
# - 减少90%的构建时间
# - 减少95%的下载时间