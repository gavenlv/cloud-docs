# 错误1：DNS解析失败
# 错误信息：
# docker: Error response from daemon: Get "https://registry-1.docker.io/v2/": dial tcp: lookup registry-1.docker.io on 127.0.0.11:53: read udp 127.0.0.11:53->127.0.0.11:53: i/o timeout

# 解决方案：
# 1. 检查DNS配置
docker inspect web-server | grep -A 10 Dns

# 2. 修改DNS配置
docker run -d --name web-server --dns 8.8.8.8 --dns 8.8.4.4 nginx

# 3. 修改Docker守护进程DNS配置
# 编辑 /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}

# 4. 重启Docker守护进程
sudo systemctl restart docker

# 5. 使用--network host模式
docker run -d --name web-server --network host nginx

# 错误2：容器间无法通信
# 错误信息：
# curl: (6) Could not resolve host: other-container

# 解决方案：
# 1. 检查容器是否在同一网络
docker inspect web-server | grep -A 10 Networks
docker inspect other-container | grep -A 10 Networks

# 2. 将容器连接到同一网络
docker network connect my-network web-server
docker network connect my-network other-container

# 3. 使用容器IP地址通信
docker inspect other-container | grep IPAddress
docker exec web-server curl http://172.17.0.2:80

# 4. 检查网络驱动
docker network inspect my-network | grep Driver

# 5. 检查网络隔离
docker network inspect my-network | grep Internal

# 错误3：外部无法访问容器
# 错误信息：
# curl: (7) Failed to connect to localhost port 80: Connection refused

# 解决方案：
# 1. 检查端口映射
docker port web-server

# 2. 检查容器是否运行
docker ps | grep web-server

# 3. 检查容器日志
docker logs web-server

# 4. 检查防火墙规则
sudo iptables -L -n -v | grep DOCKER

# 5. 检查容器监听地址
docker exec web-server netstat -tulpn

# 6. 使用正确的端口映射
docker run -d --name web-server -p 80:80 nginx

# 7. 检查容器内应用配置
docker exec web-server cat /etc/nginx/nginx.conf | grep listen

# 错误4：网络驱动不支持
# 错误信息：
# docker: Error response from daemon: could not choose network driver for network my-network

# 解决方案：
# 1. 检查可用的网络驱动
docker info | grep "Network Drivers"

# 2. 使用支持的网络驱动
docker network create --driver bridge my-network

# 3. 检查Docker守护进程配置
docker info | grep "Storage Driver"

# 4. 更新Docker守护进程配置
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}

# 5. 重启Docker守护进程
sudo systemctl restart docker

# 错误5：路由问题
# 错误信息：
# docker: Error response from daemon: failed to create endpoint web-server on network my-network: failed to add gateway address (172.18.0.1): invalid address

# 解决方案：
# 1. 检查网络配置
docker network inspect my-network | grep -A 10 IPAM

# 2. 删除网络
docker network rm my-network

# 3. 重新创建网络
docker network create --subnet=172.18.0.0/16 --gateway=172.18.0.1 my-network

# 4. 检查路由表
ip route show

# 5. 添加路由
sudo ip route add 172.18.0.0/16 via 172.18.0.1

# 6. 检查网关配置
docker network inspect my-network | grep Gateway