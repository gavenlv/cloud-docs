# 使用角色

# 创建Playbook
cat > playbook-with-role.yml << 'EOF'
---
- name: 使用角色的Playbook示例
  hosts: webservers
  become: true
  roles:
    - role: nginx
      vars:
        nginx_port: 8080
        nginx_document_root: /var/www/myapp
        nginx_server_name: myapp.example.com
        nginx_ssl_enabled: true
EOF

# 运行Playbook
ansible-playbook playbook-with-role.yml

# 预期输出：
# PLAY [使用角色的Playbook示例] ******************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [nginx : 更新系统包] **********************************************
# ok: [localhost]
# TASK [nginx : 安装Nginx包] *********************************************
# changed: [localhost]
# TASK [nginx : 创建Nginx用户] ********************************************
# changed: [localhost]
# TASK [nginx : 创建文档根目录] ******************************************
# changed: [localhost]
# TASK [nginx : 创建Nginx配置目录] **************************************
# changed: [localhost] => (item=/etc/nginx/sites-available)
# changed: [localhost] => (item=/etc/nginx/sites-enabled)
# TASK [nginx : 配置Nginx] **********************************************
# changed: [localhost]
# TASK [nginx : 创建默认站点配置] ***************************************
# changed: [localhost]
# TASK [nginx : 启用默认站点] *******************************************
# changed: [localhost]
# TASK [nginx : 创建首页文件] *******************************************
# changed: [localhost]
# TASK [nginx : 启动Nginx服务] *******************************************
# changed: [localhost]
# TASK [nginx : 等待Nginx服务启动] ***************************************
# ok: [localhost]
# RUNNING HANDLER [nginx : 重新加载Nginx服务] ****************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=13   changed=11   unreachable=0    failed=0