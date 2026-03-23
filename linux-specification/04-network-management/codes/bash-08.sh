# wireshark/tshark - 图形/命令行抓包分析

# tshark - 命令行wireshark
tshark -i eth0
tshark -r capture.pcap
tshark -r capture.pcap -Y "http.request"  # 过滤HTTP请求
tshark -r capture.pcap -T fields -e ip.src -e http.host  # 导出字段

# 常用过滤表达式
# ip.addr == 192.168.1.1
# tcp.port == 80
# http.request.method == "GET"
# tcp.flags.syn == 1  # SYN包
# tcp.flags.fin == 1  # FIN包