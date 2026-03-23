# 基础语法
iptables -t filter -A INPUT -s 192.168.1.0/24 -j DROP
#   │        │    │    │              │
#   │        │    │    │              └─ 动作
#   │        │    │    └─ 源地址
#   │        │    └─ 链
#   │        └─ 表
#   └─ 操作 (-A添加, -D删除, -I插入, -L列表, -F清空)

# 动作 (Target)
# ACCEPT - 接受
# DROP   - 丢弃 (不响应)
# REJECT - 拒绝 (响应ICMP错误)
# LOG    - 记录日志
# SNAT   - 源NAT
# DNAT   - 目标NAT
# MASQUERADE - 动态SNAT

# 常用操作
iptables -L                           # 列出所有规则
iptables -L -n                        # 不解析IP
iptables -L -v                        # 详细
iptables -L -t nat                    # 查看NAT表
iptables -L INPUT --line-numbers      # 带行号

# 追加规则
iptables -A INPUT -p tcp --dport 22 -j ACCEPT     # 允许SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT     # 允许HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT    # 允许HTTPS
iptables -A INPUT -j DROP                        # 默认拒绝

# 插入规则
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT   # 插入到第1行

# 删除规则
iptables -D INPUT 3                              # 删除第3行
iptables -D INPUT -p tcp --dport 22 -j ACCEPT   # 删除匹配规则

# 清空规则
iptables -F                           # 清空filter表
iptables -t nat -F                    # 清空NAT表
iptables -X                           # 删除用户自定义链

# 设置默认策略
iptables -P INPUT DROP                 # 默认拒绝输入
iptables -P FORWARD DROP               # 默认拒绝转发
iptables -P OUTPUT ACCEPT              # 默认允许输出