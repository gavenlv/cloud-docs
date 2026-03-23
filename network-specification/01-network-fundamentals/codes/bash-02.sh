# 交换机MAC地址表 (CAM表)
# 动态学习, 根据源MAC记录端口

show mac address-table
# VLAN  Mac Address      Type      Ports
# ----  -----------      --------  -----
#   1    00:11:22:33:44:55    DYNAMIC  Gi0/1
#   1    66:77:88:99:AA:BB    DYNAMIC  Gi0/2

# 路由器路由表
# 静态/动态学习, 根据目的网络转发

ip route show
# default via 192.168.1.1 dev eth0  proto static
# 10.0.0.0/24 via 192.168.1.254 dev eth0  proto static

# 交换机转发逻辑:
# 1. 收到帧, 学习源MAC
# 2. 查找目标MAC:
#    - 在表中 → 从对应端口转发
#    - 不在表中 → 泛洪 (广播)
# 3. 目标MAC是广播地址 → 泛洪

# 路由器转发逻辑:
# 1. 收到IP包, 检查TTL
# 2. 查找路由表:
#    - 找到路由 → 从对应接口转发
#    - 没找到 → 发送给默认网关
# 3. TTL减1, 重新封装, 发送