# 连接状态 (Connection Tracking)
# NEW       - 新连接
# ESTABLISHED - 已建立的连接
# RELATED   - 相关连接 (如FTP数据传输)
# INVALID   - 无效连接
# UNTRACKED - 未跟踪的连接

# 允许已建立连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH新连接
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# 允许HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT