# netfilter的5个HOOK点:

1. NF_INET_PRE_ROUTING  (PREROUTING)
   - 数据包接收后, 路由决策之前
   - 用于NAT (DNAT)

2. NF_INET_LOCAL_IN  (INPUT)
   - 目的地是本机的数据包, 路由决策之后
   - 用于包过滤

3. NF_INET_FORWARD  (FORWARD)
   - 需要转发到其他主机的数据包
   - 用于包过滤

4. NF_INET_LOCAL_OUT  (OUTPUT)
   - 从本机发出的数据包
   - 用于包过滤, NAT (SNAT)

5. NF_INET_POST_ROUTING  (POSTROUTING)
   - 数据包发送前, 路由决策之后
   - 用于NAT (SNAT)