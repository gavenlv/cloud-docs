CPU监控：
top                 实时进程监控
htop                增强版监控
mpstat              CPU统计

内存监控：
free -h             内存使用情况
vmstat              虚拟内存统计

磁盘监控：
df -h               磁盘使用情况
du -sh /var         目录大小
du -h --max-depth=1 /var
iostat              IO统计

网络监控：
ifconfig            网络接口配置
ip addr             IP地址
ip route            路由表
netstat -tuln       监听端口
ss -tuln            socket统计
netstat -anp        所有连接
lsof -i :80         查看端口占用