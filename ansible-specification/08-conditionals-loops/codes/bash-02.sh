# 创建使用循环的Playbook

# 创建Playbook文件
cat > playbook-loops.yml << 'EOF'
---
- name: 使用循环的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包
      apt:
        name: "{{ package }}"
        state: present
        update_cache: yes
      loop:
        - nginx
        - nginx-extras
        - python3-certbot-nginx
      loop_control:
        loop_var: package
      register: package_install
    
    - name: 显示安装结果
      debug:
        msg: "包 {{ item.item }} 安装状态: {{ item.changed }}"
      loop: "{{ package_install.results }}"
    
    - name: 创建多个目录
      file:
        path: "{{ directory }}"
        state: directory
        mode: '0755'
      loop:
        - /var/www/html
        - /var/log/nginx
        - /etc/nginx/conf.d
      loop_control:
        loop_var: directory
        label: "创建目录 {{ directory }}"
    
    - name: 创建多个文件
      copy:
        content: "{{ item.content }}"
        dest: "{{ item.path }}"
        mode: '0644'
      loop:
        - { path: /var/www/html/index.html, content: "Index Page" }
        - { path: /var/www/html/about.html, content: "About Page" }
        - { path: /var/www/html/contact.html, content: "Contact Page" }
    
    - name: 配置防火墙规则
      ufw:
        rule: allow
        port: "{{ rule.port }}"
        proto: "{{ rule.proto }}"
      loop:
        - { port: 80, proto: tcp }
        - { port: 443, proto: tcp }
        - { port: 22, proto: tcp }
      loop_control:
        loop_var: rule
    
    - name: 启动多个服务
      service:
        name: "{{ service }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - mysql
        - redis
      loop_control:
        loop_var: service
EOF

# 运行Playbook
ansible-playbook playbook-loops.yml

# 预期输出：
# PLAY [使用循环的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装多个包] *****************************************************
# changed: [localhost] => (item=nginx)
# changed: [localhost] => (item=nginx-extras)
# changed: [localhost] => (item=python3-certbot-nginx)
# TASK [显示安装结果] *************************************************
# ok: [localhost] => (item={'item': 'nginx', 'changed': True, 'failed': False, ...})
# ok: [localhost] => (item={'item': 'nginx-extras', 'changed': True, 'failed': False, ...})
# ok: [localhost] => (item={'item': 'python3-certbot-nginx', 'changed': True, 'failed': False, ...})
# TASK [创建多个目录] ***************************************************
# changed: [localhost] => (item=/var/www/html)
# changed: [localhost] => (item=/var/log/nginx)
# changed: [localhost] => (item=/etc/nginx/conf.d)
# TASK [创建多个文件] ***************************************************
# changed: [localhost] => (item={'path': '/var/www/html/index.html', 'content': 'Index Page'})
# changed: [localhost] => (item={'path': '/var/www/html/about.html', 'content': 'About Page'})
# changed: [localhost] => (item={'path': '/var/www/html/contact.html', 'content': 'Contact Page'})
# TASK [配置防火墙规则] *************************************************
# changed: [localhost] => (item={'port': 80, 'proto': 'tcp'})
# changed: [localhost] => (item={'port': 443, 'proto': 'tcp'})
# changed: [localhost] => (item={'port': 22, 'proto': 'tcp'})
# TASK [启动多个服务] ***************************************************
# changed: [localhost] => (item=nginx)
# changed: [localhost] => (item=mysql)
# changed: [localhost] => (item=redis)
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=12   unreachable=0    failed=0