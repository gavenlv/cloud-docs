# systemd使用.mount单元代替fstab

# 示例: /data挂载单元
cat /etc/systemd/system/data.mount
#[Unit]
#Description=Data Mount
#After=local-fs.target
#
#[Mount]
#What=/dev/sdb1
#Where=/data
#Type=ext4
#Options=defaults
#
#[Install]
#WantedBy=multi-user.target

# 管理systemd挂载
sudo systemctl daemon-reload
sudo systemctl start data.mount
sudo systemctl enable data.mount
sudo systemctl status data.mount