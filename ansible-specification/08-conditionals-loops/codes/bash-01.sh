# 创建使用条件的Playbook

# 创建Playbook文件
cat > playbook-conditionals.yml << 'EOF'
---
- name: 使用条件的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（Debian系统）
      apt:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
      register: nginx_install
    
    - name: 安装Nginx（RedHat系统）
      yum:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "RedHat"
      register: nginx_install
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装状态: {{ nginx_install.changed }}"
      when: nginx_install is defined
    
    - name: 配置Nginx（SSL启用）
      template:
        src: nginx-ssl.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      when: nginx_ssl_enabled | default(false)
      notify:
        - 重新加载Nginx服务
    
    - name: 配置Nginx（SSL禁用）
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      when: not nginx_ssl_enabled | default(false)
      notify:
        - 重新加载Nginx服务
    
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
ansible-playbook playbook-conditionals.yml -e "nginx_ssl_enabled=true"

# 预期输出：
# PLAY [使用条件的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx（Debian系统）] *****************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装状态: true"
# }
# TASK [配置Nginx（SSL启用）] *******************************************
# changed: [localhost]
# TASK [启动Nginx服务] ***************************************************
# changed: [localhost]
# RUNNING HANDLER [重新加载Nginx服务] ****************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=3    unreachable=0    failed=0