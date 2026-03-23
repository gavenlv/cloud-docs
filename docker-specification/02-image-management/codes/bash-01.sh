# 构建镜像
docker build -t my-python-app:1.0 .

# 查看镜像
docker images

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    1.0       abc123def456   5 minutes ago   125MB

# 查看镜像详细信息
docker inspect my-python-app:1.0

# 输出（部分）：
# [
#     {
#         "Id": "sha256:abc123def456789012345678901234567890123456789012",
#         "RepoTags": [
#             "my-python-app:1.0"
#         ],
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Size": 125000000,
#         "VirtualSize": 125000000,
#         "Config": {
#             "Env": [
#                 "PYTHONUNBUFFERED=1",
#                 "APP_ENV=production",
#                 "PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
#             ],
#             "ExposedPorts": {
#                 "8000/tcp": {}
#             },
#             "WorkingDir": "/app"
#         }
#     }
# ]