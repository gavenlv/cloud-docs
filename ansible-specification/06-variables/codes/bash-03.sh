# 创建使用变量文件的Playbook

# 创建Playbook文件
cat > playbook-vars-files.yml << 'EOF'
---
- name: 使用变量文件的Playbook示例
  hosts: webservers
  become: true
  vars_files:
    - vars/common.yml
    - vars/nginx.yml
  tasks:
    - name: 显示变量
      debug:
        msg:
          - "HTTP端口: {{ http_port }}"
          - "HTTPS端口: {{ https_port }}"
          - "文档根目录: {{ document_root }}"
          - "服务器名称: {{ server_name }}"
          - "SSL启用: {{ ssl_enabled }}"
          - "SSL证书路径: {{ ssl_cert_path }}"
          - "SSL密钥路径: {{ ssl_key_path }}"
          - "工作进程数: {{ nginx_config.worker_processes }}"
          - "工作连接数: {{ nginx_config.worker_connections }}"
          - "保持连接超时: {{ nginx_config.keepalive_timeout }}"
          - "Nginx包: {{ nginx_packages }}"
EOF

# 运行Playbook
ansible-playbook playbook-vars-files.yml

# 预期输出：
# PLAY [使用变量文件的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [显示变量] *********************************************************
# ok: [localhost] => {
#     "msg": [
#         "HTTP端口: 80",
#         "HTTPS端口: 443",
#         "文档根目录: /var/www/html",
#         "服务器名称: localhost",
#         "SSL启用: false",
#         "SSL证书路径: /etc/ssl/certs/nginx.crt",
#         "SSL密钥路径: /etc/ssl/private/nginx.key",
#         "工作进程数: auto",
#         "工作连接数: 1024",
#         "保持连接超时: 65",
#         "Nginx包: [\"nginx\", \"nginx-extras\", \"python3-certbot-nginx\"]"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=2    changed=0    unreachable=0    failed=0