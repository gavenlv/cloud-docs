# 场景: 搭建LAMP环境,分离数据和系统盘

# 1. 添加新磁盘并分区
sudo fdisk /dev/sdb
# n, p, 1, w

# 2. 格式化
sudo mkfs.ext4 /dev/sdb1

# 3. 创建MySQL数据目录
sudo mkdir -p /data/mysql

# 4. 挂载
echo '/dev/sdb1 /data ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo mount -a

# 5. 设置权限
sudo chown -R mysql:mysql /data/mysql
sudo chmod 750 /data/mysql

# 6. 安装MySQL
sudo apt install mysql-server

# 7. 配置MySQL使用新数据目录
sudo systemctl stop mysql
sudo rsync -av /var/lib/mysql/ /data/mysql/

# 8. 修改MySQL配置
# 编辑/etc/mysql/mysql.conf.d/mysqld.cnf
# datadir = /data/mysql

# 9. AppArmor/selinux配置
sudo apparmor_parser -r /etc/apparmor.d/*

# 10. 启动验证
sudo systemctl start mysql
mysql -u root -p -e "SHOW VARIABLES LIKE 'datadir';"