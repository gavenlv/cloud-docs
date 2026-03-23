# 1. 损坏的包状态
sudo dpkg --configure -a
sudo apt install -f

# 2. 清理缓存
sudo apt clean
sudo apt autoclean

# 3. 修复依赖
sudo apt-get install -f