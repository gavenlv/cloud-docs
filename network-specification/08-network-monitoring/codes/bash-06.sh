# Wireshark是图形化抓包分析工具

# 常用过滤
ip.addr == 192.168.1.1           # 特定IP
ip.src == 192.168.1.0/24        # 源IP网段
tcp.port == 80                   # TCP端口
tcp.flags.syn == 1               # SYN包
http.request.method == "GET"     # HTTP GET

# 统计功能
# Statistics → Summary: 连接统计
# Statistics → Conversations: 对话统计
# Statistics → Protocol Hierarchy: 协议层级

# 导出
# File → Export Objects → HTTP: 导出HTTP对象