# 诊断步骤
# 1. 查看连接状态
ss -tan | grep :80

# 2. 查看服务日志
journalctl -u nginx -n 50

# 3. 检查资源限制
ulimit -n
cat /proc/sys/fs/file-max

# 常见原因
# 1. 连接数满
# 查看最大连接数
ss -s
# 调整限制
ulimit -n 65535

# 2. 服务崩溃
systemctl restart nginx