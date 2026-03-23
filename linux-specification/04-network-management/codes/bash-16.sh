# /etc/resolv.conf - DNS配置

cat /etc/resolv.conf
# nameserver 8.8.8.8
# nameserver 8.8.4.4
# search localdomain

# 字段说明:
# nameserver - DNS服务器地址 (最多3个)
# search     - 搜索域 (可多个)
# domain     - 本地域名

# 注意事项:
# - 此文件通常由systemd-resolved或NetworkManager管理
# - 手动修改可能被覆盖
# - 使用 systemd-resolve --status 查看状态