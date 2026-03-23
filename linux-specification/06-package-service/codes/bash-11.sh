# 服务管理命令对比

┌─────────────────────────────────────────────────────────────────┐
│       SysVinit         │            systemd                      │
├────────────────────────┼────────────────────────────────────────┤
│  service nginx start   │  systemctl start nginx                 │
│  service nginx stop    │  systemctl stop nginx                  │
│  service nginx restart  │  systemctl restart nginx               │
│  service nginx reload   │  systemctl reload nginx                │
│  service nginx status   │  systemctl status nginx                │
│  service nginx condrestart│  systemctl condrestart nginx          │
├────────────────────────┼────────────────────────────────────────┤
│  chkconfig --level 3 nginx on │  systemctl enable nginx         │
│  chkconfig --level 3 nginx off│  systemctl disable nginx         │
│  chkconfig --list nginx       │  systemctl is-enabled nginx      │
├────────────────────────┼────────────────────────────────────────┤
│  /etc/init.d/nginx     │  /lib/systemd/system/nginx.service     │
│    start|stop|reload   │    (systemd自动处理)                  │
└────────────────────────┴────────────────────────────────────────┘

# 常用命令
systemctl daemon-reload           # 重载unit文件
systemctl reset-failed            # 重置failed状态
systemctl poweroff                # 关机
systemctl reboot                  # 重启
systemctl emergency               # 进入emergency模式