# 场景: 配置静态IP

# 方法1: 使用ip命令 (临时)
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add default via 192.168.1.1

# 方法2: 配置网络接口 (Debian/Ubuntu)
cat > /etc/network/interfaces << 'EOF'
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
EOF

sudo systemctl restart networking

# 方法3: Netplan (Ubuntu 18.04+)
cat > /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF

sudo netplan apply

# 方法4: RHEL/CentOS
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << 'EOF'
TYPE=Ethernet
BOOTPROTO=static
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
EOF

sudo systemctl restart network