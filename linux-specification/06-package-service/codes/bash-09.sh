# 查看target
systemctl list-units --type=target --all

# 查看当前target
systemctl get-default

# 设置默认target
sudo systemctl set-default multi-user.target
sudo systemctl set-default graphical.target

# 切换到target (不修改默认)
sudo systemctl isolate multi-user.target
sudo systemctl isolate graphical.target

# 查看target的依赖
systemctl list-dependencies multi-user.target