# 创建两个网络
docker network create network-a
docker network create network-b

# 运行第一个容器并连接到network-a
docker run -d \
  --name container-a \
  --network network-a \
  nginx

# 运行第二个容器并连接到network-b
docker run -d \
  --name container-b \
  --network network-b \
  python:3.11-slim \
  python -m http.server 8000

# 尝试从container-a访问container-b（会失败）
docker exec container-a curl http://container-b:8000

# 输出：
# curl: (6) Could not resolve host: container-b

# 将container-b也连接到network-a
docker network connect network-a container-b

# 再次尝试访问（成功）
docker exec container-a curl http://container-b:8000

# 输出：
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
# <html>
# <head>
# <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
# <title>Directory listing for /</title>
# </head>
# <body>
# <h1>Directory listing for /</h1>
# <hr>
# <ul>
# <li><a href=".dockerenv">.dockerenv</a></li>
# <li><a href="app.py">app.py</a></li>
# <li><a href="bin/">bin/</a></li>
# <li><a href="dev/">dev/</a></li>
# <li><a href="etc/">etc/</a></li>
# <li><a href="home/">home/</a></li>
# <li><a href="lib/">lib/</a></li>
# <li><a href="media/">media/</a></li>
# <li><a href="mnt/">mnt/</a></li>
# <li><a href="opt/">opt/</a></li>
# <li><a href="proc/">proc/</a></li>
# <li><a href="root/">root/</a></li>
# <li><a href="run/">run/</a></li>
# <li><a href="sbin/">sbin/</a></li>
# <li><a href="srv/">srv/</a></li>
# <li><a href="sys/">sys/</a></li>
# <li><a href="tmp/">tmp/</a></li>
# <li><a href="usr/">usr/</a></li>
# <li><a href="var/">var/</a></li>
# </ul>
# <hr>
# </body>
# </html>

# 查看容器连接的网络
docker inspect container-b | grep -A 10 Networks

# 输出：
# "Networks": {
#     "network-a": {
#         "IPAMConfig": {},
#         "Links": null,
#         "Aliases": [
#             "container-b"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.19.0.1",
#         "IPAddress": "172.19.0.3",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:13:00:03",
#         "DriverOpts": {}
#     },
#     "network-b": {
#         "IPAMConfig": {},
#         "Links": null,
#         "Aliases": [
#             "container-b"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.20.0.1",
#         "IPAddress": "172.20.0.2",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:14:00:02",
#         "DriverOpts": {}
#     }
# }