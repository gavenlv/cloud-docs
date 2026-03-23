# 1. 安装
apt install openvpn easy-rsa

# 2. 生成证书
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-server server
./easyrsa gen-client client
./easyrsa sign-server server server
./easyrsa sign-client client client

# 3. 服务器配置 /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3

# 4. 启动服务
systemctl start openvpn@server
systemctl enable openvpn@server

# 5. 客户端配置
client
dev tun
proto udp
remote your-server 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
cipher AES-256-CBC
verb 3