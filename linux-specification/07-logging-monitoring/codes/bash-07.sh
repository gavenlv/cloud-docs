# /etc/logrotate.d/nginx

/var/log/nginx/*.log {
    daily                 # 每日轮转
    missingok             # 忽略不存在
    rotate 14            # 保留14份
    compress             # gzip压缩
    delaycompress         # 延迟压缩(保留最近的不压缩)
    notifempty           # 空文件不轮转
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}