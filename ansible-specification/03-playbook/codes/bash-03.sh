# 创建使用Handler的Playbook

# 创建Playbook文件
cat > playbook-handler.yml << 'EOF'
---
- name: 使用Handler的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      notify:
        - 重启Nginx服务
    
    - name: 配置Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        backup: yes
        validate: 'nginx -t -c %s'
      notify:
        - 测试Nginx配置
        - 重新加载Nginx配置
    
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        mode: '0755'
      notify:
        - 重新加载Nginx配置
    
    - name: 创建首页文件
      copy:
        content: "Hello, World!"
        dest: /var/www/html/index.html
        mode: '0644'
      notify:
        - 重新加载Nginx配置
    
    - name: 手动触发Handler
      debug:
        msg: "手动触发Handler"
      changed_when: true
      notify:
        - 重新加载Nginx配置
    
    - name: 强制触发Handler
      meta: flush_handlers
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
    
    - name: 重新加载Nginx配置
      service:
        name: nginx
        state: reloaded
    
    - name: 测试Nginx配置
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
EOF

# 运行Playbook
ansible-playbook playbook-handler.yml

# 预期输出：
# PLAY [使用Handler的Playbook示例] ******************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [配置Nginx] ********************************************************
# changed: [localhost]
# TASK [创建文档根目录] ***************************************************
# changed: [localhost]
# TASK [创建首页文件] *****************************************************
# changed: [localhost]
# TASK [手动触发Handler] **************************************************
# changed: [localhost] => {
#     "msg": "手动触发Handler"
# }
# TASK [强制触发Handler] **************************************************
# RUNNING HANDLER [重启Nginx服务] ******************************************
# changed: [localhost]
# RUNNING HANDLER [测试Nginx配置] *****************************************
# ok: [localhost]
# RUNNING HANDLER [重新加载Nginx配置] **************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=8    changed=7    unreachable=0    failed=0