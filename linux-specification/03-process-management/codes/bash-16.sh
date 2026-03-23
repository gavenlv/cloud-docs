# pgrep - 搜索进程
pgrep nginx
pgrep -u root sshd

# pkill - 按名称杀进程
pkill nginx
pkill -9 -u username

# pidof - 获取进程PID
pidof nginx
pidof -s nginx  # 只返回一个PID

# pstree - 进程树
pstree
pstree -p
pstree -p 1     # 查看PID 1的进程树

# watch - 定期执行命令
watch -n 1 'ps -eo pid,stat,cmd --sort=-%cpu | head -10'

# lsof - 查看进程打开的文件
lsof -p PID
lsof /dev/null
lsof -i :8080

# fuser - 查找使用文件的进程
fuser /var/log/syslog
fuser -v 8080/tcp