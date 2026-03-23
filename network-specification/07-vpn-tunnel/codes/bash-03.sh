# 1. 安装
apt install wireguard

# 2. 生成密钥
wg genkey > privatekey
wg pubkey < privatekey > publickey

# 3. 服务器配置 /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# 添加客户端
[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32

# 4. 客户端配置
[Interface]
Address = 10.0.0.2/24
PrivateKey = <client-private-key>
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# 5. 启动
wg-quick up wg0
wg-quick down wg0
systemctl enable wg-quick@wg0

# 6. 查看状态
wg
wg show