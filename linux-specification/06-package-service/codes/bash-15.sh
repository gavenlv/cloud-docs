# 从源码编译安装

# 1. 安装编译工具
sudo apt install build-essential   # Debian/Ubuntu
sudo yum groupinstall "Development Tools"  # RHEL/CentOS

# 2. 下载源码
wget https://example.com/package.tar.gz
tar -xzf package.tar.gz
cd package

# 3. 查看INSTALL/README
less INSTALL
less README

# 4. 配置
./configure --prefix=/opt/package --enable-feature

# 5. 编译
make -j$(nproc)

# 6. 安装
sudo make install

# 7. 清理
make clean
make distclean

# 8. 卸载 (如果没有make uninstall)
sudo rm -rf /opt/package
sudo rm -f /usr/local/bin/package