# 使用bridge网络模式（默认）
docker run -d \
  --name web-server \
  --network bridge \
  -p 80:80 \
  nginx

# 使用host网络模式
docker run -d \
  --name web-server \
  --network host \
  nginx

# 使用none网络模式
docker run -d \
  --name web-server \
  --network none \
  nginx

# 使用container网络模式
docker run -d \
  --name app-container \
  nginx

docker run -d \
  --name sidecar-container \
  --network container:app-container \
  busybox sleep 3600

# 创建自定义网络
docker network create my-network

# 使用自定义网络
docker run -d \
  --name web-server \
  --network my-network \
  -p 80:80 \
  nginx

# 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 输出：
# "Networks": {
#     "my-network": {
#         "IPAMConfig": null,
#         "Links": null,
#         "Aliases": [
#             "web-server"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.18.0.1",
#         "IPAddress": "172.18.0.2",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:12:00:02",
#         "DriverOpts": null
#     }
# }