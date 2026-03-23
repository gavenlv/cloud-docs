# 创建使用模板的Playbook

# 创建Playbook文件
cat > playbook-templates.yml << 'EOF'
---
- name: 使用模板的Playbook示例
  hosts: webservers
  become: true
  vars:
    nginx_user: www-data
    nginx_worker_processes: auto
    nginx_worker_connections: 1024
    nginx_keepalive_timeout: 65
    nginx_ssl_enabled: false
    site_port: 80
    site_name: example.com
    site_root: /var/www/html
    site_ssl_enabled: false
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: 配置Nginx（使用模板）
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        validate: 'nginx -t -c %s'
        backup: yes
      notify:
        - 重新加载Nginx服务
    
    - name: 创建站点配置（使用模板）
      template:
        src: templates/site.conf.j2
        dest: /etc/nginx/sites-available/default
        owner: root
        group: root
        mode: '0644'
      notify:
        - 重新加载Nginx服务
    
    - name: 启用站点
      file:
        src: /etc/nginx/sites-available/default
        dest: /etc/nginx/sites-enabled/default
        state: link
      notify:
        - 重新加载Nginx服务
    
    - name: 创建首页
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Welcome to Nginx</title>
          </head>
          <body>
              <h1>Hello, World!</h1>
              <p>Nginx is running successfully.</p>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
  
  handlers:
    - name: 重新加载Nginx服务
      service:
        name: nginx
        state: reloaded
EOF

# 运行Playbook
ansible-playbook playbook-templates.yml

# 预期输出：
# PLAY [使用模板的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [创建文档根目录] ***************************************************
# changed: [localhost]
# TASK [配置Nginx（使用模板）] ******************************************
# changed: [localhost]
# TASK [创建站点配置（使用模板）] ****************************************
# changed: [localhost]
# TASK [启用站点] *********************************************************
# changed: [localhost]
# TASK [创建首页] *********************************************************
# changed: [localhost]
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# RUNNING HANDLER [重新加载Nginx服务] ****************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=8    changed=7    unreachable=0    failed=0