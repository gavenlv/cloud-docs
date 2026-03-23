# 创建复杂Playbook

# 创建Playbook文件
cat > playbook-complex.yml << 'EOF'
---
- name: 配置Web服务器
  hosts: webservers
  become: true
  vars:
    http_port: 80
    https_port: 443
    document_root: /var/www/html
    server_name: localhost
  pre_tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      changed_when: false
    
    - name: 检查系统版本
      debug:
        msg: "系统版本: {{ ansible_distribution }} {{ ansible_distribution_version }}"
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
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
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
              <p>This is a test page.</p>
          </body>
          </html>
        dest: "{{ document_root }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
      notify:
        - 重新加载Nginx配置
    
    - name: 配置防火墙
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "{{ http_port }}"
        - "{{ https_port }}"
      notify:
        - 重新加载防火墙
    
    - name: 启用Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
  post_tasks:
    - name: 测试Nginx服务
      uri:
        url: "http://localhost:{{ http_port }}"
        method: GET
        status_code: 200
        timeout: 30
        return_content: yes
      register: web_test
      changed_when: false
    
    - name: 显示测试结果
      debug:
        msg: "Nginx服务测试结果: {{ web_test.status }}"
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
      listen:
        - 重启Nginx服务
    
    - name: 重新加载Nginx配置
      service:
        name: nginx
        state: reloaded
      listen:
        - 重新加载Nginx配置
    
    - name: 测试Nginx配置
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
      listen:
        - 测试Nginx配置
    
    - name: 重新加载防火墙
      ufw:
        state: reloaded
      listen:
        - 重新加载防火墙
EOF

# 创建Nginx配置模板
mkdir -p templates
cat > templates/nginx.conf.j2 << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    server {
        listen {{ http_port }};
        listen [::]:{{ http_port }};
        server_name {{ server_name }};
        root {{ document_root }};
        index index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

        location ~ /\.ht {
            deny all;
        }
    }
}
EOF

# 运行Playbook
ansible-playbook playbook-complex.yml

# 预期输出：
# PLAY [配置Web服务器] ****************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [更新系统包] ********************************************************
# ok: [localhost]
# TASK [检查系统版本] *****************************************************
# ok: [localhost] => {
#     "msg": "系统版本: Ubuntu 22.04"
# }
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [配置Nginx] ********************************************************
# changed: [localhost]
# TASK [创建文档根目录] ***************************************************
# changed: [localhost]
# TASK [创建首页文件] *****************************************************
# changed: [localhost]
# TASK [配置防火墙] ********************************************************
# changed: [localhost] => (item=80)
# changed: [localhost] => (item=443)
# TASK [启用Nginx服务] ****************************************************
# changed: [localhost]
# TASK [测试Nginx服务] ****************************************************
# ok: [localhost]
# TASK [显示测试结果] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务测试结果: 200"
# }
# RUNNING HANDLER [测试Nginx配置] *****************************************
# ok: [localhost]
# RUNNING HANDLER [重新加载Nginx配置] **************************************
# changed: [localhost]
# RUNNING HANDLER [重新加载防火墙] ****************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=13   changed=10   unreachable=0    failed=0