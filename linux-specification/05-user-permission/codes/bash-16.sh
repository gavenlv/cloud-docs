# 检查权限问题
ls -la /problematic/path

# 找出权限过于宽松的文件
find /home -perm -777 -type f 2>/dev/null

# 找出没有owner的文件
find / -nouser -o -nogroup 2>/dev/null

# 修复常见权限问题
# /tmp目录
chmod 1777 /tmp

# /var/tmp
chmod 1777 /var/tmp

# /home目录
chmod 755 /home
chmod 700 /home/username

# SSH配置
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 644 /etc/ssh/ssh_host_rsa_key.pub