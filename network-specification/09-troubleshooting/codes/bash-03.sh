# 诊断步骤
# 1. 检查服务是否监听
ss -tuln | grep :80
netstat -tuln | grep :80

# 2. 检查服务状态
systemctl status nginx

# 3. 测试本地连接
curl -v localhost:80
telnet localhost 80

# 4. 检查防火墙
iptables -L -n | grep :80
firewall-cmd --list-all

# 常见原因
# 1. 服务未启动
systemctl start nginx
systemctl enable nginx

# 2. 端口未监听
# 检查配置文件
ss -tuln | grep nginx

# 3. 防火墙阻止
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
firewall-cmd --add-port=80/tcp --permanent