# 条件和循环

## 8.1 条件语句

### 8.1.1 when条件

```yaml
# when条件示例

- name: when条件示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（Debian系统）
      apt:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 安装Nginx（RedHat系统）
      yum:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: 配置Nginx（SSL启用）
      template:
        src: nginx-ssl.conf.j2
        dest: /etc/nginx/nginx.conf
      when: nginx_ssl_enabled | default(false)
    
    - name: 配置Nginx（SSL禁用）
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      when: not nginx_ssl_enabled | default(false)
    
    - name: 创建目录（如果不存在）
      file:
        path: /var/www/html
        state: directory
      when: not nginx_document_root_stat.stat.exists | default(false)
```

### 8.1.2 复杂条件

```yaml
# 复杂条件示例

- name: 复杂条件示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（Debian系统且版本>=20.04）
      apt:
        name: nginx
        state: present
        update_cache: yes
      when:
        - ansible_os_family == "Debian"
        - ansible_distribution_version is version('20.04', '>=')
    
    - name: 配置Nginx（SSL启用且证书存在）
      template:
        src: nginx-ssl.conf.j2
        dest: /etc/nginx/nginx.conf
      when:
        - nginx_ssl_enabled | default(false)
        - nginx_ssl_cert_stat.stat.exists | default(false)
        - nginx_ssl_key_stat.stat.exists | default(false)
    
    - name: 安装PHP（Web服务器且PHP启用）
      apt:
        name: php-fpm
        state: present
        update_cache: yes
      when:
        - inventory_hostname in groups['webservers']
        - php_enabled | default(false)
    
    - name: 配置防火墙（HTTP或HTTPS端口）
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "{{ http_port }}"
        - "{{ https_port }}"
      when:
        - firewall_enabled | default(false)
        - item is defined
        - item is number
```

### 8.1.3 条件测试

```yaml
# 条件测试示例

- name: 条件测试示例
  hosts: webservers
  become: true
  tasks:
    - name: 检查变量是否定义
      debug:
        msg: "变量已定义"
      when: nginx_port is defined
    
    - name: 检查变量是否未定义
      debug:
        msg: "变量未定义"
      when: nginx_port is undefined
    
    - name: 检查变量是否为数字
      debug:
        msg: "变量是数字"
      when: nginx_port is number
    
    - name: 检查变量是否为字符串
      debug:
        msg: "变量是字符串"
      when: server_name is string
    
    - name: 检查变量是否为布尔值
      debug:
        msg: "变量是布尔值"
      when: nginx_ssl_enabled is boolean
    
    - name: 检查变量是否为真
      debug:
        msg: "变量为真"
      when: nginx_ssl_enabled
    
    - name: 检查变量是否为假
      debug:
        msg: "变量为假"
      when: not nginx_ssl_enabled
    
    - name: 检查列表是否为空
      debug:
        msg: "列表为空"
      when: nginx_packages | length == 0
    
    - name: 检查列表是否不为空
      debug:
        msg: "列表不为空"
      when: nginx_packages | length > 0
    
    - name: 检查字符串是否匹配
      debug:
        msg: "字符串匹配"
      when: server_name is match('example\\.com')
    
    - name: 检查字符串是否搜索
      debug:
        msg: "字符串搜索"
      when: server_name is search('example')
    
    - name: 检查文件是否存在
      stat:
        path: /etc/nginx/nginx.conf
      register: nginx_config_stat
    
    - name: 检查文件是否存在
      debug:
        msg: "文件存在"
      when: nginx_config_stat.stat.exists
    
    - name: 检查文件是否为目录
      debug:
        msg: "文件是目录"
      when: nginx_config_stat.stat.isdir
    
    - name: 检查文件是否为文件
      debug:
        msg: "文件是文件"
      when: nginx_config_stat.stat.isfile
    
    - name: 检查版本比较
      debug:
        msg: "版本>=20.04"
      when: ansible_distribution_version is version('20.04', '>=')
```

---

## 8.2 循环语句

### 8.2.1 loop循环

```yaml
# loop循环示例

- name: loop循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - nginx
        - nginx-extras
        - python3-certbot-nginx
    
    - name: 创建多个目录
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /var/www/html
        - /var/log/nginx
        - /etc/nginx/conf.d
    
    - name: 创建多个文件
      file:
        path: "{{ item.path }}"
        state: touch
        mode: "{{ item.mode }}"
      loop:
        - { path: /var/www/html/index.html, mode: '0644' }
        - { path: /var/log/nginx/access.log, mode: '0644' }
        - { path: /var/log/nginx/error.log, mode: '0644' }
    
    - name: 配置多个服务
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - mysql
        - redis
```

### 8.2.2 with_items循环

```yaml
# with_items循环示例

- name: with_items循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      with_items:
        - nginx
        - nginx-extras
        - python3-certbot-nginx
    
    - name: 创建多个目录
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      with_items:
        - /var/www/html
        - /var/log/nginx
        - /etc/nginx/conf.d
    
    - name: 配置防火墙规则
      ufw:
        rule: allow
        port: "{{ item.port }}"
        proto: "{{ item.proto }}"
      with_items:
        - { port: 80, proto: tcp }
        - { port: 443, proto: tcp }
        - { port: 22, proto: tcp }
```

### 8.2.3 with_dict循环

```yaml
# with_dict循环示例

- name: with_dict循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建多个用户
      user:
        name: "{{ item.key }}"
        shell: /bin/bash
        home: "{{ item.value.home }}"
        groups: "{{ item.value.groups }}"
        append: yes
        state: present
      with_dict:
        webuser:
          home: /home/webuser
          groups:
            - www-data
            - sudo
        dbuser:
          home: /home/dbuser
          groups:
            - mysql
            - sudo
        appuser:
          home: /home/appuser
          groups:
            - app
            - sudo
    
    - name: 创建多个目录
      file:
        path: "{{ item.value }}"
        state: directory
        mode: '0755'
      with_dict:
        html: /var/www/html
        log: /var/log/nginx
        config: /etc/nginx/conf.d
```

### 8.2.4 with_list循环

```yaml
# with_list循环示例

- name: with_list循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      with_list:
        - nginx
        - nginx-extras
        - python3-certbot-nginx
    
    - name: 创建多个目录
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      with_list:
        - /var/www/html
        - /var/log/nginx
        - /etc/nginx/conf.d
```

### 8.2.5 with_flattened循环

```yaml
# with_flattened循环示例

- name: with_flattened循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包（嵌套列表）
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      with_flattened:
        - - nginx
          - nginx-extras
        - - python3-certbot-nginx
          - python3-certbot
    
    - name: 创建多个目录（嵌套列表）
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      with_flattened:
        - - /var/www/html
          - /var/www/static
        - - /var/log/nginx
          - /var/log/nginx/old
```

### 8.2.6 with_together循环

```yaml
# with_together循环示例

- name: with_together循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建多个文件（组合列表）
      copy:
        content: "{{ item.1 }}"
        dest: "{{ item.0 }}"
        mode: '0644'
      with_together:
        - - /var/www/html/index.html
          - /var/www/html/about.html
          - /var/www/html/contact.html
        - - "Index Page"
          - "About Page"
          - "Contact Page"
    
    - name: 创建多个用户（组合列表）
      user:
        name: "{{ item.0 }}"
        shell: "{{ item.1 }}"
        home: "{{ item.2 }}"
        state: present
      with_together:
        - - webuser
          - dbuser
          - appuser
        - - /bin/bash
          - /bin/bash
          - /bin/bash
        - - /home/webuser
          - /home/dbuser
          - /home/appuser
```

### 8.2.7 with_subelements循环

```yaml
# with_subelements循环示例

- name: with_subelements循环示例
  hosts: webservers
  become: true
  vars:
    users:
      - name: webuser
        groups:
          - www-data
          - sudo
      - name: dbuser
        groups:
          - mysql
          - sudo
      - name: appuser
        groups:
          - app
          - sudo
  tasks:
    - name: 添加用户到多个组
      user:
        name: "{{ item.0.name }}"
        groups: "{{ item.1 }}"
        append: yes
      with_subelements:
        - "{{ users }}"
        - groups
```

### 8.2.8 with_sequence循环

```yaml
# with_sequence循环示例

- name: with_sequence循环示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建多个目录（数字序列）
      file:
        path: "/var/www/html/site{{ item }}"
        state: directory
        mode: '0755'
      with_sequence: start=1 end=5
    
    - name: 创建多个目录（数字序列，步长为2）
      file:
        path: "/var/www/html/site{{ item }}"
        state: directory
        mode: '0755'
      with_sequence: start=1 end=10 stride=2
    
    - name: 创建多个目录（数字序列，格式化）
      file:
        path: "/var/www/html/site{{ item | format('%03d') }}"
        state: directory
        mode: '0755'
      with_sequence: start=1 end=5 format="%03d"
```

---

## 8.3 循环控制

### 8.3.1 loop_control

```yaml
# loop_control示例

- name: loop_control示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装多个包（自定义循环变量）
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
    
    - name: 创建多个目录（自定义循环变量和标签）
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
    
    - name: 安装多个包（暂停）
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
        pause: 5
```

### 8.2.2 loop_register

```yaml
# loop_register示例

- name: loop_register示例
  hosts: webservers
  become: true
  tasks:
    - name: 检查多个文件
      stat:
        path: "{{ item }}"
      loop:
        - /etc/nginx/nginx.conf
        - /etc/nginx/sites-available/default
        - /var/www/html/index.html
      register: file_stats
    
    - name: 显示文件状态
      debug:
        msg: "文件 {{ item.item }} 存在: {{ item.stat.exists }}"
      loop: "{{ file_stats.results }}"
      when: item.stat is defined
    
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
```

---

## 8.4 实战：使用条件和循环

### 8.4.1 使用条件

```bash
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
```

### 8.4.2 使用循环

```bash
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
```

### 8.4.3 使用条件和循环

```bash
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
```

---

## 本章小结

- 条件语句用于根据条件执行任务
- when条件用于根据变量值、主机属性等条件执行任务
- 复杂条件可以使用逻辑运算符（and、or、not）和比较运算符（==、!=、<、>、<=、>=）
- 条件测试用于检查变量类型、值、文件状态等
- 循环语句用于重复执行任务
- loop循环是最基本的循环方式
- with_items循环用于遍历列表
- with_dict循环用于遍历字典
- with_list循环用于遍历列表
- with_flattened循环用于遍历嵌套列表
- with_together循环用于组合多个列表
- with_subelements循环用于遍历嵌套元素
- with_sequence循环用于生成数字序列
- loop_control用于控制循环变量、标签、暂停等
- loop_register用于注册循环结果
- 可以在循环中使用条件判断
- 可以在条件中使用循环

---

**下一章：Ansible最佳实践**
