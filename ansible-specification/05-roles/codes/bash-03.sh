# 配置角色变量

# 创建默认变量
cat > roles/nginx/defaults/main.yml << 'EOF'
---
nginx_version: "1.18.0"
nginx_port: 80
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false
nginx_ssl_cert_path: /etc/ssl/certs/nginx.crt
nginx_ssl_key_path: /etc/ssl/private/nginx.key
EOF

# 创建角色变量
cat > roles/nginx/vars/main.yml << 'EOF'
---
nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx

nginx_config_file: /etc/nginx/nginx.conf
nginx_sites_available: /etc/nginx/sites-available
nginx_sites_enabled: /etc/nginx/sites-enabled

nginx_user: www-data
nginx_group: www-data
EOF