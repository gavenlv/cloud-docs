# 创建定时任务

cat > /etc/systemd/system/mytask.timer << 'EOF'
[Unit]
Description=My Scheduled Task
Requires=mytask.service

[Timer]
OnCalendar=*-*-* *:*:00      # 每分钟
# OnCalendar=*-*-01 00:00:00  # 每月1号凌晨
# OnCalendar=daily            # 每天
# OnCalendar=hourly           # 每小时
Persistent=true              # 如果错过则立即运行

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/mytask.service << 'EOF'
[Unit]
Description=My Scheduled Task

[Service]
Type=oneshot
ExecStart=/opt/myapp/scripts/mytask.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mytask.timer
sudo systemctl list-timers