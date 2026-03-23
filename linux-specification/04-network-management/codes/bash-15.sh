# IP隧道

# 创建GRE隧道
ip tunnel add gre1 mode gre remote 10.0.0.2 local 10.0.0.1
ip addr add 192.168.10.1/24 dev gre1
ip link set gre1 up

# 创建IPIP隧道
ip tunnel add ipip1 mode ipip remote 10.0.0.2 local 10.0.0.1
ip addr add 192.168.20.1/24 dev ipip1
ip link set ipip1 up

# 删除隧道
ip tunnel del gre1

# 查看隧道
ip tunnel show

# WireGuard (现代VPN)
apt install wireguard
wg genkey | tee privatekey | wg pubkey > publickey