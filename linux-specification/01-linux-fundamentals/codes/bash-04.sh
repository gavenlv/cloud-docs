# systemd基础命令

# 查看当前默认target
systemctl get-default

# 设置默认target
sudo systemctl set-default multi-user.target
sudo systemctl set-default graphical.target

# 切换到指定target (不改变默认设置)
sudo systemctl isolate multi-user.target

# 查看所有units
systemctl list-units --all

# 查看服务状态
systemctl status nginx

# 启动/停止/重启服务
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 开机自启
sudo systemctl enable nginx
sudo systemctl disable nginx

# 查看启动耗时
systemd-analyze
systemd-analyze blame