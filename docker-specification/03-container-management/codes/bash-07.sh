# 映射单个端口（宿主机端口:容器端口）
docker run -d \
  --name web-server \
  -p 80:80 \
  nginx

# 映射多个端口
docker run -d \
  --name web-server \
  -p 80:80 \
  -p 443:443 \
  nginx

# 映射随机端口
docker run -d \
  --name web-server \
  -p 80 \
  nginx

# 查看端口映射
docker port web-server

# 输出：
# 80/tcp -> 0.0.0.0:32768

# 绑定到特定接口
docker run -d \
  --name web-server \
  -p 127.0.0.1:80:80 \
  nginx

# 绑定到特定接口和端口
docker run -d \
  --name web-server \
  -p 192.168.1.100:8080:80 \
  nginx

# 映射UDP端口
docker run -d \
  --name dns-server \
  -p 53:53/udp \
  dns-server

# 映射端口范围
docker run -d \
  --name web-server \
  -p 8000-8010:8000-8010 \
  nginx