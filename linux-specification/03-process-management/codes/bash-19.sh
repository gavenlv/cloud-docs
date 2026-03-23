# systemd timer - 现代化定时任务

# 创建timer单元
cat > /etc/systemd/system/mytask.timer << 'EOF'
[Unit]
Description=My Task Timer

[Timer]
OnCalendar=*:0/5          # 每5分钟
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 创建service单元
cat > /etc/systemd/system/mytask.service << 'EOF'
[Unit]
Description=My Task Service

[Service]
Type=oneshot
ExecStart=/path/to/command

[Install]
WantedBy=multi-user.target
EOF

# 管理timer
sudo systemctl daemon-reload
sudo systemctl enable --now mytask.timer
sudo systemctl list-timers