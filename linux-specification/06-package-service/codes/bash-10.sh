# systemd-journald 日志管理

# 查看日志
journalctl                           # 所有日志
journalctl -u nginx                  # 指定服务日志
journalctl -u nginx -f              # 实时跟踪
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-01" --until "2024-01-02"
journalctl -p err                    # 错误级别
journalctl --disk-usage              # 日志磁盘使用

# 日志清理
journalctl --vacuum-size=500M       # 限制日志大小
journalctl --vacuum-time=7d         # 保留7天
journalctl --vacuum-files=10       # 保留文件数

# 内核日志
journalctl -k                       # 等价于 dmesg
journalctl -b                       # 本次启动日志
journalctl -b -1                    # 上次启动日志

# 查看日志优先级
# 0: emerg (系统不可用)
# 1: alert (需要立即处理)
# 2: crit (严重)
# 3: err (错误)
# 4: warning (警告)
# 5: notice (普通通知)
# 6: info (信息)
# 7: debug (调试)