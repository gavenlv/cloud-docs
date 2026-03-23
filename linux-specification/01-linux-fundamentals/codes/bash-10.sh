# 查看swap使用
swapon -s
# Filename                Type        Size    Used    Priority
# /dev/sda2               partition   2097148 0       -2

# 创建swap文件
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 关闭swap
sudo swapoff /swapfile

# 设置swappiness (0-100, 越高越倾向使用swap)
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness=10