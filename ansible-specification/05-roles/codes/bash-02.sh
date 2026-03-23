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