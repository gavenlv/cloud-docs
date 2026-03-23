# 角色开发

## 5.1 角色原理

### 5.1.1 角色的核心概念

```
角色的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  角色是什么？                                             │
└─────────────────────────────────────────────────────────────────┘

角色是Ansible中用于组织和重用代码的结构化方式：

1. 角色结构
   ├── tasks目录
   ├── handlers目录
   ├── templates目录
   ├── files目录
   ├── vars目录
   ├── defaults目录
   ├── meta目录
   └── tests目录

2. 角色特性
   ├── 模块化设计
   ├── 可重用性
   ├── 可维护性
   └── 可扩展性

3. 角色依赖
   ├── 角色间依赖
   ├── 依赖顺序
   ├── 依赖参数
   └── 依赖冲突

4. 角色变量
   ├── 默认变量
   ├── 角色变量
   ├── 主机变量
   └── 组变量

5. 角色任务
   ├── 任务列表
   ├── 任务顺序
   ├── 任务条件
   └── 任务循环
```

### 5.1.2 角色目录结构

```
角色目录结构：

┌─────────────────────────────────────────────────────────────────┐
│  角色目录结构                                         │
└─────────────────────────────────────────────────────────────────┘

role-name/
├── defaults/           # 默认变量
│   └── main.yml
├── files/              # 静态文件
│   ├── config.conf
│   └── script.sh
├── handlers/           # 处理器
│   └── main.yml
├── meta/               # 角色元数据
│   └── main.yml
├── tasks/              # 任务列表
│   ├── main.yml
│   ├── install.yml
│   └── configure.yml
├── templates/          # 模板文件
│   ├── config.conf.j2
│   └── nginx.conf.j2
├── tests/              # 测试文件
│   ├── inventory
│   └── test.yml
├── vars/               # 角色变量
│   └── main.yml
└── README.md           # 角色文档

目录说明：
├── defaults/           # 默认变量，优先级最低，可以被覆盖
├── files/              # 静态文件，直接复制到目标主机
├── handlers/           # 处理器，在任务变更后执行
├── meta/               # 角色元数据，包括依赖、作者、描述等
├── tasks/              # 任务列表，定义角色要执行的任务
├── templates/          # 模板文件，使用Jinja2模板引擎
├── tests/              # 测试文件，用于测试角色
├── vars/               # 角色变量，优先级高于defaults
└── README.md           # 角色文档，说明角色的使用方法
```

---

## 5.2 角色结构

### 5.2.1 基本角色结构

```yaml
# roles/nginx/defaults/main.yml
---
nginx_version: "1.18.0"
nginx_port: 80
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false
nginx_ssl_cert_path: /etc/ssl/certs/nginx.crt
nginx_ssl_key_path: /etc/ssl/private/nginx.key
```

```yaml
# roles/nginx/vars/main.yml
---
nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx

nginx_config_file: /etc/nginx/nginx.conf
nginx_sites_available: /etc/nginx/sites-available
nginx_sites_enabled: /etc/nginx/sites-enabled

nginx_user: www-data
nginx_group: www-data
```

```yaml
# roles/nginx/tasks/main.yml
---
- name: 包含安装任务
  include_tasks: install.yml
  tags:
    - nginx
    - install

- name: 包含配置任务
  include_tasks: configure.yml
  tags:
    - nginx
    - configure

- name: 包含服务任务
  include_tasks: service.yml
  tags:
    - nginx
    - service
```

```yaml
# roles/nginx/tasks/install.yml
---
- name: 更新系统包
  apt:
    update_cache: yes
    cache_valid_time: 3600
  become: true
  tags:
    - nginx
    - install

- name: 安装Nginx包
  apt:
    name: "{{ nginx_packages }}"
    state: present
    update_cache: yes
  become: true
  register: nginx_install
  tags:
    - nginx
    - install

- name: 创建Nginx用户
  user:
    name: "{{ nginx_user }}"
    system: yes
    shell: /usr/sbin/nologin
    home: /var/lib/nginx
    create_home: no
    state: present
  become: true
  tags:
    - nginx
    - install
```

```yaml
# roles/nginx/tasks/configure.yml
---
- name: 创建文档根目录
  file:
    path: "{{ nginx_document_root }}"
    state: directory
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0755'
  become: true
  tags:
    - nginx
    - configure

- name: 创建Nginx配置目录
  file:
    path: "{{ item }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  become: true
  loop:
    - "{{ nginx_sites_available }}"
    - "{{ nginx_sites_enabled }}"
  tags:
    - nginx
    - configure

- name: 配置Nginx
  template:
    src: nginx.conf.j2
    dest: "{{ nginx_config_file }}"
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
    backup: yes
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 创建默认站点配置
  template:
    src: default-site.conf.j2
    dest: "{{ nginx_sites_available }}/default"
    owner: root
    group: root
    mode: '0644'
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 启用默认站点
  file:
    src: "{{ nginx_sites_available }}/default"
    dest: "{{ nginx_sites_enabled }}/default"
    state: link
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 创建首页文件
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
    dest: "{{ nginx_document_root }}/index.html"
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0644'
  become: true
  tags:
    - nginx
    - configure
```

```yaml
# roles/nginx/tasks/service.yml
---
- name: 启动Nginx服务
  service:
    name: nginx
    state: started
    enabled: yes
  become: true
  tags:
    - nginx
    - service

- name: 等待Nginx服务启动
  wait_for:
    port: "{{ nginx_port }}"
    delay: 5
    timeout: 30
  tags:
    - nginx
    - service
```

```yaml
# roles/nginx/handlers/main.yml
---
- name: 重新加载Nginx服务
  service:
    name: nginx
    state: reloaded
  become: true

- name: 重启Nginx服务
  service:
    name: nginx
    state: restarted
  become: true
```

```yaml
# roles/nginx/meta/main.yml
---
galaxy_info:
  role_name: nginx
  author: Ansible User
  description: Install and configure Nginx web server
  company: Your Company
  license: MIT
  min_ansible_version: "2.9"
  
  platforms:
    - name: Ubuntu
      versions:
        - bionic
        - focal
        - jammy
    - name: Debian
      versions:
        - buster
        - bullseye
  
  galaxy_tags:
    - nginx
    - web
    - webserver
    - http
    - https

dependencies: []
```

### 5.2.2 模板文件

```jinja2
# roles/nginx/templates/nginx.conf.j2
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    {% if nginx_ssl_enabled %}
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    {% endif %}

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

```jinja2
# roles/nginx/templates/default-site.conf.j2
server {
    listen {{ nginx_port }};
    listen [::]:{{ nginx_port }};
    server_name {{ nginx_server_name }};
    root {{ nginx_document_root }};
    index index.html index.htm;

    {% if nginx_ssl_enabled %}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate {{ nginx_ssl_cert_path }};
    ssl_certificate_key {{ nginx_ssl_key_path }};
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

---

## 5.3 角色依赖

### 5.3.1 角色依赖定义

```yaml
# roles/app/meta/main.yml
---
galaxy_info:
  role_name: app
  author: Ansible User
  description: Install and configure application
  company: Your Company
  license: MIT
  min_ansible_version: "2.9"

dependencies:
  - role: nginx
    vars:
      nginx_port: 80
      nginx_document_root: /var/www/app
  
  - role: mysql
    vars:
      mysql_root_password: secret
      mysql_database: appdb
      mysql_user: appuser
      mysql_password: apppass
  
  - role: redis
    vars:
      redis_port: 6379
      redis_bind: 127.0.0.1
```

### 5.3.2 角色依赖使用

```yaml
# playbook-with-dependencies.yml
---
- name: 使用角色依赖的Playbook
  hosts: webservers
  become: true
  roles:
    - role: app
      vars:
        app_name: myapp
        app_version: 1.0.0
        app_port: 8080
```

---

## 5.4 角色变量

### 5.4.1 默认变量

```yaml
# roles/nginx/defaults/main.yml
---
nginx_version: "1.18.0"
nginx_port: 80
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false
nginx_ssl_cert_path: /etc/ssl/certs/nginx.crt
nginx_ssl_key_path: /etc/ssl/private/nginx.key
```

### 5.4.2 角色变量

```yaml
# roles/nginx/vars/main.yml
---
nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx

nginx_config_file: /etc/nginx/nginx.conf
nginx_sites_available: /etc/nginx/sites-available
nginx_sites_enabled: /etc/nginx/sites-enabled

nginx_user: www-data
nginx_group: www-data
```

### 5.4.3 角色变量使用

```yaml
# playbook-with-roles.yml
---
- name: 使用角色变量的Playbook
  hosts: webservers
  become: true
  roles:
    - role: nginx
      vars:
        nginx_port: 8080
        nginx_document_root: /var/www/myapp
        nginx_server_name: myapp.example.com
        nginx_ssl_enabled: true
```

---

## 5.5 实战：开发角色

### 5.5.1 创建角色

```bash
# 创建角色目录结构

# 创建角色目录
mkdir -p roles/nginx/{defaults,files,handlers,meta,tasks,templates,tests,vars}

# 创建角色文件
touch roles/nginx/defaults/main.yml
touch roles/nginx/vars/main.yml
touch roles/nginx/tasks/main.yml
touch roles/nginx/handlers/main.yml
touch roles/nginx/meta/main.yml
touch roles/nginx/templates/nginx.conf.j2
touch roles/nginx/templates/default-site.conf.j2
touch roles/nginx/README.md

# 验证角色目录结构
tree roles/nginx

# 预期输出：
# roles/nginx/
# ├── defaults/
# │   └── main.yml
# ├── files/
# ├── handlers/
# │   └── main.yml
# ├── meta/
# │   └── main.yml
# ├── tasks/
# │   └── main.yml
# ├── templates/
# │   ├── default-site.conf.j2
# │   └── nginx.conf.j2
# ├── tests/
# ├── vars/
# │   └── main.yml
# └── README.md
```

### 5.5.2 编写角色任务

```bash
# 编写角色任务

# 创建安装任务
cat > roles/nginx/tasks/install.yml << 'EOF'
---
- name: 更新系统包
  apt:
    update_cache: yes
    cache_valid_time: 3600
  become: true
  tags:
    - nginx
    - install

- name: 安装Nginx包
  apt:
    name: "{{ nginx_packages }}"
    state: present
    update_cache: yes
  become: true
  register: nginx_install
  tags:
    - nginx
    - install

- name: 创建Nginx用户
  user:
    name: "{{ nginx_user }}"
    system: yes
    shell: /usr/sbin/nologin
    home: /var/lib/nginx
    create_home: no
    state: present
  become: true
  tags:
    - nginx
    - install
EOF

# 创建配置任务
cat > roles/nginx/tasks/configure.yml << 'EOF'
---
- name: 创建文档根目录
  file:
    path: "{{ nginx_document_root }}"
    state: directory
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0755'
  become: true
  tags:
    - nginx
    - configure

- name: 创建Nginx配置目录
  file:
    path: "{{ item }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  become: true
  loop:
    - "{{ nginx_sites_available }}"
    - "{{ nginx_sites_enabled }}"
  tags:
    - nginx
    - configure

- name: 配置Nginx
  template:
    src: nginx.conf.j2
    dest: "{{ nginx_config_file }}"
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
    backup: yes
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 创建默认站点配置
  template:
    src: default-site.conf.j2
    dest: "{{ nginx_sites_available }}/default"
    owner: root
    group: root
    mode: '0644'
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 启用默认站点
  file:
    src: "{{ nginx_sites_available }}/default"
    dest: "{{ nginx_sites_enabled }}/default"
    state: link
  become: true
  notify:
    - 重新加载Nginx服务
  tags:
    - nginx
    - configure

- name: 创建首页文件
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
    dest: "{{ nginx_document_root }}/index.html"
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0644'
  become: true
  tags:
    - nginx
    - configure
EOF

# 创建服务任务
cat > roles/nginx/tasks/service.yml << 'EOF'
---
- name: 启动Nginx服务
  service:
    name: nginx
    state: started
    enabled: yes
  become: true
  tags:
    - nginx
    - service

- name: 等待Nginx服务启动
  wait_for:
    port: "{{ nginx_port }}"
    delay: 5
    timeout: 30
  tags:
    - nginx
    - service
EOF

# 创建主任务文件
cat > roles/nginx/tasks/main.yml << 'EOF'
---
- name: 包含安装任务
  include_tasks: install.yml
  tags:
    - nginx
    - install

- name: 包含配置任务
  include_tasks: configure.yml
  tags:
    - nginx
    - configure

- name: 包含服务任务
  include_tasks: service.yml
  tags:
    - nginx
    - service
EOF
```

### 5.5.3 配置角色变量

```bash
# 配置角色变量

# 创建默认变量
cat > roles/nginx/defaults/main.yml << 'EOF'
---
nginx_version: "1.18.0"
nginx_port: 80
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false
nginx_ssl_cert_path: /etc/ssl/certs/nginx.crt
nginx_ssl_key_path: /etc/ssl/private/nginx.key
EOF

# 创建角色变量
cat > roles/nginx/vars/main.yml << 'EOF'
---
nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx

nginx_config_file: /etc/nginx/nginx.conf
nginx_sites_available: /etc/nginx/sites-available
nginx_sites_enabled: /etc/nginx/sites-enabled

nginx_user: www-data
nginx_group: www-data
EOF
```

### 5.5.4 配置角色处理器

```bash
# 配置角色处理器

# 创建处理器
cat > roles/nginx/handlers/main.yml << 'EOF'
---
- name: 重新加载Nginx服务
  service:
    name: nginx
    state: reloaded
  become: true

- name: 重启Nginx服务
  service:
    name: nginx
    state: restarted
  become: true
EOF
```

### 5.5.5 配置角色元数据

```bash
# 配置角色元数据

# 创建元数据
cat > roles/nginx/meta/main.yml << 'EOF'
---
galaxy_info:
  role_name: nginx
  author: Ansible User
  description: Install and configure Nginx web server
  company: Your Company
  license: MIT
  min_ansible_version: "2.9"
  
  platforms:
    - name: Ubuntu
      versions:
        - bionic
        - focal
        - jammy
    - name: Debian
      versions:
        - buster
        - bullseye
  
  galaxy_tags:
    - nginx
    - web
    - webserver
    - http
    - https

dependencies: []
EOF
```

### 5.5.6 创建模板文件

```bash
# 创建模板文件

# 创建Nginx配置模板
cat > roles/nginx/templates/nginx.conf.j2 << 'EOF'
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    {% if nginx_ssl_enabled %}
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    {% endif %}

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# 创建默认站点配置模板
cat > roles/nginx/templates/default-site.conf.j2 << 'EOF'
server {
    listen {{ nginx_port }};
    listen [::]:{{ nginx_port }};
    server_name {{ nginx_server_name }};
    root {{ nginx_document_root }};
    index index.html index.htm;

    {% if nginx_ssl_enabled %}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate {{ nginx_ssl_cert_path }};
    ssl_certificate_key {{ nginx_ssl_key_path }};
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
```

### 5.5.7 使用角色

```bash
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
```

---

## 本章小结

- 角色是Ansible中用于组织和重用代码的结构化方式
- 角色结构包括tasks、handlers、templates、files、vars、defaults、meta、tests目录
- 角色特性包括模块化设计、可重用性、可维护性、可扩展性
- 角色依赖包括角色间依赖、依赖顺序、依赖参数、依赖冲突
- 角色变量包括默认变量、角色变量、主机变量、组变量
- 角色任务包括任务列表、任务顺序、任务条件、任务循环
- 可以使用include_tasks包含任务文件
- 可以使用template模块使用模板文件
- 可以使用handler实现延迟执行
- 可以使用role在Playbook中使用角色

---

**下一章：变量管理**
