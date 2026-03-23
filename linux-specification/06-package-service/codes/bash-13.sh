# 创建socket激活服务

cat > /etc/systemd/system/mysocket.socket << 'EOF'
[Unit]
Description=My Service Socket
PartOf=myservice.service

[Socket]
ListenStream=/run/myservice.sock
SocketMode=0660
SocketUser=myuser
SocketGroup=mygroup

[Install]
WantedBy=sockets.target
EOF

cat > /etc/systemd/system/myservice.service << 'EOF'
[Unit]
Description=My Service
After=mysocket.socket

[Service]
Type=notify
ExecStart=/opt/myapp/bin/myapp --socket /run/myservice.sock
SocketActivation=accept

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mysocket.socket
sudo systemctl start mysocket.socket