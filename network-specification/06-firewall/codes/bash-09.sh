# nftables是iptables的下一代
# 统一的表结构, 更好的性能

# 查看nftables规则
nft list ruleset

# 创建表
nft add table ip filter

# 创建链
nft add chain ip filter input { type filter hook input priority 0 \; }

# 添加规则
nft add rule ip filter input tcp dport 22 accept

# 替换iptables
# Debian/Ubuntu
update-alternatives --set iptables /usr/sbin/iptables-nft
update-alternatives --set ip6tables /usr/sbin/ip6tables-nft