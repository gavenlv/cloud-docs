# nmap端口扫描
nmap -sS -sV -p- 192.168.1.1        # SYN扫描, 版本检测, 全端口
nmap -sV -sC -oA scan_result 10.0.0.1  # 脚本扫描, 输出所有格式

# 漏洞扫描
nikto -h https://example.com          # Web漏洞扫描
openvas-start                        # 启动OpenVAS

# 查看开放端口
ss -tuln
netstat -tuln