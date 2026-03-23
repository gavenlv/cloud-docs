# 创建变量文件

# 创建全局变量
cat > ansible-project/group_vars/all.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

timezone: UTC
locale: en_US.UTF-8
EOF

# 创建Web服务器变量
cat > ansible-project/group_vars/webservers.yml << 'EOF'
---
nginx_port: 80
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false

app_name: webapp
app_version: 1.0.0
app_port: 8080
EOF

# 创建数据库服务器变量
cat > ansible-project/group_vars/dbservers.yml << 'EOF'
---
mysql_port: 3306
mysql_root_password: secret
mysql_database: appdb
mysql_user: appuser
mysql_password: apppass
EOF

# 验证变量文件
cat ansible-project/group_vars/all.yml
cat ansible-project/group_vars/webservers.yml
cat ansible-project/group_vars/dbservers.yml