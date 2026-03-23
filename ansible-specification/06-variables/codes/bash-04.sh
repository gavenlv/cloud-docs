# 使用命令行变量

# 创建Playbook文件
cat > playbook-cli-vars.yml << 'EOF'
---
- name: 使用命令行变量的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 显示命令行变量
      debug:
        msg:
          - "HTTP端口: {{ http_port }}"
          - "HTTPS端口: {{ https_port }}"
          - "文档根目录: {{ document_root }}"
          - "服务器名称: {{ server_name }}"
          - "SSL启用: {{ ssl_enabled }}"
EOF

# 运行Playbook（使用命令行变量）
ansible-playbook playbook-cli-vars.yml -e "http_port=8080" -e "https_port=8443" -e "document_root=/var/www/myapp" -e "server_name=myapp.example.com" -e "ssl_enabled=true"

# 预期输出：
# PLAY [使用命令行变量的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [显示命令行变量] *************************************************
# ok: [localhost] => {
#     "msg": [
#         "HTTP端口: 8080",
#         "HTTPS端口: 8443",
#         "文档根目录: /var/www/myapp",
#         "服务器名称: myapp.example.com",
#         "SSL启用: true"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=2    changed=0    unreachable=0    failed=0