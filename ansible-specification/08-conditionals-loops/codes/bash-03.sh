# 创建使用条件和循环的Playbook

# 创建Playbook文件
cat > playbook-conditionals-loops.yml << 'EOF'
---
- name: 使用条件和循环的Playbook示例
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
    
    - name: 安装多个包（条件判断）
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
      when:
        - ansible_os_family == "Debian"
        - package is defined
    
    - name: 创建多个目录（条件判断）
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
      when: directory is defined
    
    - name: 配置防火墙规则（条件判断）
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
      when:
        - firewall_enabled | default(false)
        - rule.port is defined
        - rule.proto is defined
    
    - name: 启动多个服务（条件判断）
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
      when: service is defined
EOF

# 运行Playbook
ansible-playbook playbook-conditionals-loops.yml -e "firewall_enabled=true"

# 预期输出：
# PLAY [使用条件和循环的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx（Debian系统）] *****************************************
# changed: [localhost]
# TASK [安装多个包（条件判断）] *****************************************
# changed: [localhost] => (item=nginx)
# changed: [localhost] => (item=nginx-extras)
# changed: [localhost] => (item=python3-certbot-nginx)
# TASK [创建多个目录（条件判断）] *****************************************
# changed: [localhost] => (item=/var/www/html)
# changed: [localhost] => (item=/var/log/nginx)
# changed: [localhost] => (item=/etc/nginx/conf.d)
# TASK [配置防火墙规则（条件判断）] *************************************
# changed: [localhost] => (item={'port': 80, 'proto': 'tcp'})
# changed: [localhost] => (item={'port': 443, 'proto': 'tcp'})
# changed: [localhost] => (item={'port': 22, 'proto': 'tcp'})
# TASK [启动多个服务（条件判断）] *****************************************
# changed: [localhost] => (item=nginx)
# changed: [localhost] => (item=mysql)
# changed: [localhost] => (item=redis)
# PLAY RECAP **************************************************************
# localhost: ok=6    changed=11   unreachable=0    failed=0