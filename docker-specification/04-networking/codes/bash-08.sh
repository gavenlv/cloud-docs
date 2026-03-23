# 运行多个容器
docker run -d \
  --name web-server-1 \
  -p 8081:80 \
  nginx

docker run -d \
  --name web-server-2 \
  -p 8082:80 \
  nginx

docker run -d \
  --name web-server-3 \
  -p 8083:80 \
  nginx

# 使用HAProxy进行负载均衡
docker run -d \
  --name haproxy \
  -p 80:80 \
  -v /path/to/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  haproxy:latest

# haproxy.cfg
# frontend http-in
#     bind *:80
#     default_backend web-servers
#
# backend web-servers
#     balance roundrobin
#     server web1 web-server-1:80 check
#     server web2 web-server-2:80 check
#     server web3 web-server-3:80 check

# 测试负载均衡
for i in {1..10}; do
  curl http://localhost
  echo ""
done

# 输出：
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
# ...