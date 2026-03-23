journalctl          systemd日志
journalctl -u nginx 服务日志
journalctl -f       实时跟踪
journalctl --since "1 hour ago"

/var/log/           传统日志目录
/var/log/messages   系统消息
/var/log/secure     安全日志
/var/log/syslog     系统日志

tail -f /var/log/messages
grep "error" /var/log/messages