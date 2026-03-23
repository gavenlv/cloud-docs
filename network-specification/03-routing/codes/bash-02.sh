# Linux路由优先级 (数字越小优先级越高)
ip rule show
# 0:      from all lookup local
# 32766:  from all lookup main
# 32767:  from all lookup default

# 路由表优先级顺序:
# 1. local (local路由, 最高优先)
# 2. main (普通路由, 默认)
# 3. default (备用路由)

# 路由类型优先级 (使用ip route时):
# 1. Broadcast (广播)
# 2. Local (本地)
# 3. Unicast (单播) - 包括:
#    - unreachable
#    - blackhole
#    - prohibit
#    - throw
#    - nat
#    - via (普通路由)

# 自定义路由表优先级
ip rule add from 192.168.1.0/24 table custom priority 100