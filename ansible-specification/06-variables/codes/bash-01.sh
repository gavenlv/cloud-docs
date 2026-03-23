# 命令行定义变量

# 使用-e/--extra-vars定义变量
ansible-playbook playbook.yml -e "http_port=8080"

# 使用-e/--extra-vars定义多个变量
ansible-playbook playbook.yml -e "http_port=8080" -e "https_port=8443"

# 使用-e/--extra-vars定义复杂变量
ansible-playbook playbook.yml -e '{"nginx_config": {"worker_processes": 4, "worker_connections": 1024}}'

# 使用-e/--extra-vars @file.yml从文件加载变量
cat > extra-vars.yml << 'EOF'
---
http_port: 8080
https_port: 8443
document_root: /var/www/html
server_name: example.com
ssl_enabled: true
EOF

ansible-playbook playbook.yml -e "@extra-vars.yml"

# 使用环境变量
export HTTP_PORT=8080
ansible-playbook playbook.yml -e "http_port={{ lookup('env', 'HTTP_PORT') }}"