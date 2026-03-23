# iptables
iptables -L -n -v, iptables -A INPUT -j ACCEPT
iptables -t nat -A PREROUTING -j DNAT
iptables -t nat -A POSTROUTING -j MASQUERADE

# firewalld
firewall-cmd --list-all, firewall-cmd --add-service

# nftables
nft list ruleset, nft add rule