#!/bin/bash
# 通用防火墙配置脚本

# 清除现有规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许loopback
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH (22端口)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP/HTTPS (80/443端口)
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# 允许Ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 允许DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# 记录被拒绝的包
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables DENIED: "

# 拒绝并记录其他所有
iptables -A INPUT -j LOG --log-prefix "iptables DROP: "
iptables -A INPUT -j DROP

# 保存规则
iptables-save > /etc/iptables/rules.v4