# 1. 接口未启用
ip link show
ip link set eth0 up
ip addr show eth0

# 2. DHCP获取IP失败
dhclient -r eth0          # 释放
dhclient eth0             # 重新获取

# 3. DNS解析失败
cat /etc/resolv.conf
ping -c 2 8.8.8.8        # 测试网络
ping -c 2 google.com       # 测试DNS

# 4. 路由问题
ip route show
ip route get 8.8.8.8

# 5. 防火墙阻止
iptables -L -n
iptables -L -n -t nat