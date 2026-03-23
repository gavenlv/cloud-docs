# DEB包结构
dpkg-deb -I package.deb
# 新包格式 debian 二进制包
#  包名: package
#  版本: 1.2.3
#  架构: amd64
#  描述: Package description

# 查看deb包内容
dpkg-deb -c package.deb
dpkg-deb -x package.deb /tmp/extracted

# RPM包结构
rpm -qpi package.rpm
# Name        : package
# Version     : 1.2.3
# Release     : 1.el8
# Architecture: x86_64
# Summary     : Package description

# 查看rpm包内容
rpm -qpl package.rpm
rpm2cpio package.rpm | cpio -idv