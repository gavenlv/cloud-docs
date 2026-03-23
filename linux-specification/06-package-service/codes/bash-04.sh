# 安装本地deb包
sudo dpkg -i package.deb

# 修复损坏的安装
sudo dpkg --configure -a

# 查看包状态
dpkg -s package
dpkg --status package

# 列出已配置的文件
dpkg -l

# 列出包的文件
dpkg -L package

# 找出包含文件的包
dpkg -S /bin/ls