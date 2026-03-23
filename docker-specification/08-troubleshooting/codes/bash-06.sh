# 1. 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 2. 查看容器IP地址
docker inspect web-server | grep IPAddress

# 3. 查看容器端口映射
docker port web-server

# 4. 查看网络列表
docker network ls

# 5. 查看网络详细信息
docker network inspect my-network

# 6. 查看容器连接的网络
docker inspect web-server | grep -A 10 Networks

# 7. 在容器中测试网络连接
docker exec web-server ping -c 3 google.com

# 8. 在容器中测试DNS解析
docker exec web-server nslookup google.com

# 9. 在容器中测试端口连接
docker exec web-server nc -zv google.com 80

# 10. 查看iptables规则
sudo iptables -L -n -v | grep DOCKER

# 11. 查看路由表
docker exec web-server ip route show

# 12. 查看网络接口
docker exec web-server ip addr show

# 13. 查看网络统计
docker exec web-server netstat -i

# 14. 查看网络连接
docker exec web-server netstat -tulpn

# 15. 抓包分析
docker exec web-server tcpdump -i eth0 -w /tmp/capture.pcap