# 查看服务状态
systemctl status nginx

# 查看详细日志
journalctl -u nginx -n 50
journalctl -u nginx --since "10 minutes ago"

# 检查配置
nginx -t

# 检查依赖
systemctl list-dependencies nginx
systemctl --failed

# 手动启动调试
/usr/sbin/nginx -g 'daemon off;' &