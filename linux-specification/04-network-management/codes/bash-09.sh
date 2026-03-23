# arp - ARP缓存
arp -n                         # 查看ARP表
arp -s 192.168.1.1 00:11:22:33:44:55  # 静态ARP
arp -d 192.168.1.1              # 删除ARP条目

# arpwatch - ARP监控
sudo apt install arpwatch
sudo systemctl start arpwatch

# dig - DNS查询
dig @8.8.8.8 example.com
dig +short example.com          # 简短输出
dig -x 192.168.1.1             # 反向查询
dig example.com +trace          # 追踪DNS解析

# nslookup - DNS查询 (已过时)
nslookup example.com

# host - DNS查询
host example.com
host -t mx example.com          # MX记录

# nc/netcat - 网络瑞士军刀
nc -l 8080                     # 监听端口
nc 192.168.1.1 8080             # 连接端口
nc -zv 192.168.1.1 80          # 扫描端口
echo "GET /" | nc example.com 80  # 发送原始请求

# nmap - 端口扫描
nmap -sT localhost              # TCP连接扫描
nmap -sU localhost              # UDP扫描
nmap -sP 192.168.1.0/24        # 主机发现
nmap -O 192.168.1.1            # 操作系统检测