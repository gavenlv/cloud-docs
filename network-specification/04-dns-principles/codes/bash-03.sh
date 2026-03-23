# /etc/resolv.conf (Linux DNS配置)
cat /etc/resolv.conf

# nameserver 8.8.8.8        # Google DNS
# nameserver 1.1.1.1        # Cloudflare DNS
# nameserver 114.114.114.114 # 腾讯DNS
# search localdomain         # 本地搜索域

# 查看DNS缓存
systemd-resolve --statistics
resolvectl statistics

# 清除DNS缓存
# systemd-resolved
systemd-resolve --flush-caches
resolvectl flush-caches

# Windows:
ipconfig /flushdns

# macOS:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder