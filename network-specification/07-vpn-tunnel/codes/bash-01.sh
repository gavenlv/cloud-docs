# 使用strongSwan配置IPSec

# 1. 安装
apt install strongswan strongswan-pki

# 2. 配置 /etc/ipsec.conf
config setup
    charondebug="all"
    uniqueids=yes

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyexchange=ikev2
    authby=secret

conn myvpn
    left=203.0.113.1          # 本端公网IP
    leftsubnet=10.0.1.0/24    # 本端内网
    right=198.51.100.1        # 远端公网IP
    rightsubnet=10.0.2.0/24   # 远端内网
    auto=start
    type=tunnel

# 3. 配置 /etc/ipsec.secrets
: PSK "mypresharedkey"

# 4. 启动
systemctl start strongswan
systemctl enable strongswan

# 5. 查看状态
ipsec status
ipsec statusall