# iptables语法
iptables [-t table] -A chain [options] -j target

# 常用选项
# -A chain        添加规则到链 (APPEND)
# -I chain [num]  插入规则到链 (INSERT)
# -D chain [num]  删除规则 (DELETE)
# -R chain [num]  替换规则 (REPLACE)
# -L [chain]      列出规则 (LIST)
# -F [chain]      清空规则 (FLUSH)
# -N chain        新建链 (NEW)
# -X chain        删除链 (DELETE)
# -Z              清零计数器

# 匹配选项
# -p protocol     协议 (tcp, udp, icmp, all)
# -s source       源地址
# -d destination  目标地址
# --sport source  源端口
# --dport dest   目标端口
# -i input-if    输入接口
# -o output-if   输出接口
# -m state       连接状态
# -m comment     注释