# 使用host网络运行容器
docker run -d \
  --name web-server \
  --network host \
  nginx

# 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 输出：
# "Networks": {
#     "host": {
#         "IPAMConfig": null,
#         "Links": null,
#         "Aliases": null,
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "",
#         "IPAddress": "",
#         "IPPrefixLen": 0,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "",
#         "DriverOpts": null
#     }
# }