# 创建自定义bridge网络
docker network create my-network

# 运行第一个容器
docker run -d \
  --name web-server \
  --network my-network \
  nginx

# 运行第二个容器
docker run -d \
  --name app-server \
  --network my-network \
  python:3.11-slim \
  python -m http.server 8000

# 在第一个容器中访问第二个容器
docker exec web-server curl http://app-server:8000

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

# 查看容器IP地址
docker inspect web-server | grep IPAddress
docker inspect app-server | grep IPAddress

# 输出：
# "SecondaryIPAddresses": null,
# "IPAddress": "172.18.0.2",
# "IPPrefixLen": 16,
# "IPv6Gateway": "",
# "GlobalIPv6Address": "",
# "GlobalIPv6PrefixLen": 0,