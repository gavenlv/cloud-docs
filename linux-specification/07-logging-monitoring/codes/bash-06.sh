# /etc/logrotate.conf 主配置
# /etc/logrotate.d/* 子配置

cat /etc/logrotate.conf
# weekly              # 每周轮转
# rotate 4            # 保留4份
# create              # 创建新日志
# dateext             # 使用日期作为扩展名
# compress            # 压缩旧日志
# include /etc/logrotate.d

/var/log/wtmp {
    monthly
    create 0664 root utmp
    rotate 1
}

/var/log/btmp {
    monthly
    create 0664 root utmp
    rotate 1
}