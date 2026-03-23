# Snap (Canonical开发)
# 安装
sudo snap install vlc

# 列出
snap list
snap list --all

# 更新
sudo snap refresh
sudo snap refresh vlc

# 删除
sudo snap remove vlc

# 经典模式 (需要--classic)
sudo snap install --classic code

# Flatpak (通用)
# 安装
flatpak install flathub org.videolan.VLC

# 列出
flatpak list

# 更新
flatpak update

# 删除
flatpak uninstall org.videolan.VLC