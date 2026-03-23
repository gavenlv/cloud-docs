# 创建自定义bridge网络
docker network create my-bridge

# 查看网络
docker network ls

# 输出：
# NETWORK ID     NAME        DRIVER    SCOPE
# abc123def456   bridge      bridge    local
# abc123def456   host        host      local
# abc123def456   my-bridge   bridge    local
# abc123def456   none        null      local

# 查看网络详细信息
docker network inspect my-bridge

# 输出：
# [
#     {
#         "Name": "my-bridge",
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Scope": "local",
#         "Driver": "bridge",
#         "EnableIPv6": false,
#         "IPAM": {
#             "Driver": "default",
#             "Options": {},
#             "Config": [
#                 {
#                     "Subnet": "172.18.0.0/16",
#                     "Gateway": "172.18.0.1"
#                 }
#             ]
#         },
#         "Internal": false,
#         "Attachable": false,
#         "Ingress": false,
#         "ConfigFrom": {
#             "Network": ""
#         },
#         "ConfigOnly": false,
#         "Containers": {},
#         "Options": {},
#         "Labels": {}
#     }
# ]

# 创建容器并连接到自定义bridge网络
docker run -d \
  --name web-server \
  --network my-bridge \
  nginx

# 将运行中的容器连接到网络
docker network connect my-bridge web-server

# 断开容器与网络的连接
docker network disconnect my-bridge web-server

# 删除网络
docker network rm my-bridge