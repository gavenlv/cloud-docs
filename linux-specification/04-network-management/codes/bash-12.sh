# 网桥 - 用于虚拟机/容器网络

# 查看网桥
ip link show type bridge
brctl show

# 创建网桥
ip link add br0 type bridge
ip link set br0 up

# 添加接口到网桥
ip link set eth0 master br0
ip link set vnet0 master br0

# 从网桥移除
ip link set eth0 nomaster

# 删除网桥
ip link del br0

# brctl命令 (需要bridge-utils)
apt install bridge-utils
brctl addbr br0
brctl addif br0 eth0
brctl delif br0 eth0
brctl delbr br0

# 查看MAC地址表
brctl showmacs br0