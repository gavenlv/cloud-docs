# 诊断步骤
# 1. 检查DNS服务器
cat /etc/resolv.conf

# 2. 测试DNS服务器
dig @8.8.8.8 example.com
nslookup example.com 8.8.8.8

# 3. 检查本机缓存
systemd-resolve --flush-caches

# 常见原因
# 1. DNS服务器配置错误
# 修复
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. DNS服务器不可达
# 更换DNS服务器
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 3. hosts文件污染
cat /etc/hosts