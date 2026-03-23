# systemd基础命令

# 查看服务状态
systemctl status nginx

# 启动/停止/重启
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 重载配置 (不中断服务)
sudo systemctl reload nginx

# 重启或重载
sudo systemctl reload-or-restart nginx

# 开机自启
sudo systemctl enable nginx
sudo systemctl disable nginx

# 检查是否enable
systemctl is-enabled nginx

# 查看依赖
systemctl list-dependencies nginx
systemctl list-dependencies --after nginx    # nginx之后启动的
systemctl list-dependencies --before nginx   # nginx之前启动的

# 屏蔽服务 (完全禁用)
sudo systemctl mask nginx        # 符号链接到 /dev/null
sudo systemctl unmask nginx      # 取消屏蔽

# 查看所有unit
systemctl list-units --all
systemctl list-units --type=service
systemctl list-units --type=socket
systemctl list-units --type=target

# 查看failed的unit
systemctl --failed