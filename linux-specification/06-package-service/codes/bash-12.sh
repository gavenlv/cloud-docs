# 创建自定义服务单元

cat > /etc/systemd/system/myservice.service << 'EOF'
[Unit]
Description=My Custom Service
Documentation=https://example.com/docs
After=network.target

[Service]
Type=simple
User=myuser
Group=myuser
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/myapp --config /opt/myapp/config.yaml
ExecStop=/bin/kill -TERM $MAINPID
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myservice

# 安全加固
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/myapp/data /var/log/myapp
PrivateTmp=true

# 资源限制
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# 重载并启用
sudo systemctl daemon-reload
sudo systemctl enable myservice
sudo systemctl start myservice
sudo systemctl status myservice