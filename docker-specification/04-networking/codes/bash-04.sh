# 创建overlay网络（需要Swarm集群）
docker network create \
  --driver overlay \
  --subnet 10.0.0.0/24 \
  --opt encrypted \
  my-overlay

# 查看网络
docker network ls

# 输出：
# NETWORK ID     NAME        DRIVER    SCOPE
# abc123def456   bridge      bridge    local
# abc123def456   host        host      local
# abc123def456   my-overlay  overlay   swarm
# abc123def456   none        null      local

# 查看网络详细信息
docker network inspect my-overlay

# 输出：
# [
#     {
#         "Name": "my-overlay",
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Scope": "swarm",
#         "Driver": "overlay",
#         "EnableIPv6": false,
#         "IPAM": {
#             "Driver": "default",
#             "Options": {},
#             "Config": [
#                 {
#                     "Subnet": "10.0.0.0/24",
#                     "Gateway": "10.0.0.1"
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
#         "Options": {
#             "encrypted": ""
#         },
#         "Labels": {}
#     }
# ]