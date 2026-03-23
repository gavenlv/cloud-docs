# VLAN - 虚拟局域网

# 加载VLAN模块
modprobe 8021q

# 创建VLAN接口
ip link add link eth0 name eth0.100 type vlan id 100
ip addr add 192.168.100.1/24 dev eth0.100
ip link set eth0.100 up

# 删除VLAN接口
ip link del eth0.100

# 查看VLAN配置
cat /proc/net/vlan/config
cat /proc/net/vlan/eth0.100

# vconfig命令 (旧)
apt install vlan
vconfig add eth0 100
vconfig set_flag eth0.100 1 1