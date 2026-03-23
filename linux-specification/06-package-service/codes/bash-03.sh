# 更新软件源索引
sudo apt update

# 升级已安装包
sudo apt upgrade              # 不删除任何包
sudo apt full-upgrade        # 必要时可以删除包

# 安装包
sudo apt install package
sudo apt install package1 package2      # 安装多个
sudo apt install -y package              # 自动确认
sudo apt install --no-install-recommends package  # 不安装推荐

# 重新安装
sudo apt reinstall package

# 删除包
sudo apt remove package       # 删除包,保留配置
sudo apt purge package        # 删除包和配置
sudo apt autoremove          # 删除不需要的依赖

# 搜索包
apt search keyword
apt-cache search keyword
apt-cache show package       # 包详细信息
apt-cache depends package    # 包依赖

# 查看已安装
apt list --installed
dpkg -l                       # 列出所有已安装包
dpkg -l | grep package        # 查找特定包

# 查看包文件
dpkg -L package               # 包安装的文件列表
dpkg -S /path/to/file         # 文件属于哪个包