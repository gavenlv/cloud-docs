# 创建变量文件

# 创建vars目录
mkdir -p vars

# 创建变量文件
cat > vars/common.yml << 'EOF'
---
http_port: 80
https_port: 443
document_root: /var/www/html
server_name: localhost
ssl_enabled: false
ssl_cert_path: /etc/ssl/certs/nginx.crt
ssl_key_path: /etc/ssl/private/nginx.key
EOF

# 创建Nginx变量文件
cat > vars/nginx.yml << 'EOF'
---
nginx_config:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65

nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx
EOF

# 验证变量文件
cat vars/common.yml
cat vars/nginx.yml