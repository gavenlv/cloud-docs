# 场景1: Web服务器目录权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
# 上传目录需要可写
sudo chmod 775 /var/www/html/uploads

# 场景2: SSH密钥权限
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 场景3: 数据库数据目录
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod 700 /var/lib/mysql
sudo chmod 660 /var/lib/mysql/*.ibd

# 场景4: 共享目录 (使用SGID保证组继承)
sudo groupadd team
sudo usermod -aG team user1
sudo usermod -aG team user2
sudo mkdir /shared
sudo chgrp team /shared
sudo chmod 2775 /shared  # SGID + rwxrwxr-x
# 现在team成员创建的文件都继承team组