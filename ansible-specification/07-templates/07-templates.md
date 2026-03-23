# 模板和Jinja2

## 7.1 模板原理

### 7.1.1 模板的核心概念

```
模板的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  模板是什么？                                             │
└─────────────────────────────────────────────────────────────────┘

模板是Ansible中用于生成配置文件的机制：

1. 模板特性
   ├── 动态生成
   ├── 变量替换
   ├── 条件渲染
   ├── 循环渲染
   └── 继承机制

2. Jinja2语法
   ├── 变量输出
   ├── 表达式
   ├── 过滤器
   ├── 测试
   └── 标签

3. 模板引擎
   ├── 解析模板
   ├── 替换变量
   ├── 执行表达式
   ├── 应用过滤器
   └── 生成输出

4. 模板使用
   ├── template模块
   ├── copy模块
   ├── assemble模块
   └── 自定义模板

5. 模板最佳实践
   ├── 模块化设计
   ├── 变量验证
   ├── 模板测试
   └── 版本控制
```

### 7.1.2 Jinja2语法

```
Jinja2语法：

┌─────────────────────────────────────────────────────────────────┐
│  Jinja2语法                                          │
└─────────────────────────────────────────────────────────────────┘

1. 变量输出

语法：
{{ variable }}

示例：
{{ http_port }}
{{ nginx_config.worker_processes }}
{{ nginx_packages | join(', ') }}

2. 表达式

语法：
{% expression %}

示例：
{% if http_port == 80 %}
{% for package in nginx_packages %}
{% set variable = value %}

3. 过滤器

语法：
{{ variable | filter }}

示例：
{{ http_port | default(80) }}
{{ nginx_packages | length }}
{{ server_name | upper }}

4. 测试

语法：
{{ variable is test }}

示例：
{% if ssl_enabled is defined %}
{% if http_port is number %}
{% if server_name is string %}

5. 标签

语法：
{% tag %}

示例：
{% if condition %}
{% for item in items %}
{% set variable = value %}
{% block blockname %}
{% extends 'base.j2' %}
{% include 'partial.j2' %}
```

---

## 7.2 Jinja2语法

### 7.2.1 变量输出

```jinja2
# 变量输出示例

# 简单变量
{{ http_port }}
{{ https_port }}
{{ document_root }}
{{ server_name }}

# 嵌套变量
{{ nginx_config.worker_processes }}
{{ nginx_config.worker_connections }}
{{ nginx_config.keepalive_timeout }}

# 列表变量
{{ nginx_packages }}
{{ nginx_packages[0] }}
{{ nginx_packages[-1] }}

# 字典变量
{{ nginx_config }}
{{ nginx_config.worker_processes }}
{{ nginx_config['worker_processes'] }}

# 默认值
{{ http_port | default(80) }}
{{ https_port | default(443) }}

# 必需值
{{ http_port | mandatory }}
{{ https_port | mandatory }}
```

### 7.2.2 表达式

```jinja2
# 表达式示例

# 算术表达式
{{ 1 + 1 }}
{{ 10 - 5 }}
{{ 2 * 3 }}
{{ 10 / 2 }}
{{ 10 % 3 }}
{{ 2 ** 3 }}

# 比较表达式
{{ 1 == 1 }}
{{ 1 != 2 }}
{{ 1 < 2 }}
{{ 1 <= 2 }}
{{ 1 > 2 }}
{{ 1 >= 2 }}

# 逻辑表达式
{{ true and false }}
{{ true or false }}
{{ not true }}

# 成员表达式
{{ 'nginx' in nginx_packages }}
{{ 'apache' not in nginx_packages }}

# 字符串表达式
{{ 'Hello, ' ~ 'World!' }}
{{ 'Hello, ' + 'World!' }}

# 列表表达式
{{ [1, 2, 3] }}
{{ nginx_packages + ['php-fpm'] }}
```

### 7.2.3 过滤器

```jinja2
# 过滤器示例

# 字符串过滤器
{{ server_name | upper }}
{{ server_name | lower }}
{{ server_name | capitalize }}
{{ server_name | title }}
{{ server_name | replace('example.com', 'test.com') }}
{{ server_name | trim }}
{{ server_name | length }}
{{ server_name | split('.') }}

# 数字过滤器
{{ 3.14159 | round }}
{{ 3.14159 | round(2) }}
{{ 3.7 | ceil }}
{{ 3.2 | floor }}
{{ -10 | abs }}
{{ 100 | random }}
{{ 2 | pow(10) }}
{{ 1024 | log2 }}

# 列表过滤器
{{ nginx_packages | length }}
{{ nginx_packages | first }}
{{ nginx_packages | last }}
{{ nginx_packages | sort }}
{{ nginx_packages | unique }}
{{ nginx_packages | join(', ') }}
{{ [1, 2, 3] | sum }}
{{ [1, 2, 3] | max }}
{{ [1, 2, 3] | min }}

# 字典过滤器
{{ nginx_config.keys() | list }}
{{ nginx_config.values() | list }}
{{ nginx_config.items() | list }}
{{ nginx_config | combine({'new_key': 'new_value'}) }}

# 默认值过滤器
{{ http_port | default(80) }}
{{ ssl_enabled | default(false) }}

# 必需值过滤器
{{ http_port | mandatory }}

# 类型转换过滤器
{{ '80' | int }}
{{ 80 | string }}
{{ 'true' | bool }}
{{ 80 | float }}

# 安全过滤器
{{ user_input | safe }}
{{ user_input | escape }}

# 时间过滤器
{{ ansible_date_time.iso8601 }}
{{ ansible_date_time.epoch | int }}

# 文件路径过滤器
{{ document_root | basename }}
{{ document_root | dirname }}
{{ document_root | realpath }}
```

### 7.2.4 测试

```jinja2
# 测试示例

# 定义测试
{% if http_port is defined %}
HTTP端口已定义
{% endif %}

{% if ssl_enabled is undefined %}
SSL未启用
{% endif %}

# 类型测试
{% if http_port is number %}
HTTP端口是数字
{% endif %}

{% if server_name is string %}
服务器名称是字符串
{% endif %}

{% if nginx_packages is sequence %}
Nginx包是序列
{% endif %}

{% if nginx_config is mapping %}
Nginx配置是映射
{% endif %}

{% if ssl_enabled is boolean %}
SSL启用是布尔值
{% endif %}

# 值测试
{% if http_port == 80 %}
HTTP端口是80
{% endif %}

{% if http_port != 80 %}
HTTP端口不是80
{% endif %}

{% if http_port > 80 %}
HTTP端口大于80
{% endif %}

{% if http_port >= 80 %}
HTTP端口大于等于80
{% endif %}

{% if http_port < 80 %}
HTTP端口小于80
{% endif %}

{% if http_port <= 80 %}
HTTP端口小于等于80
{% endif %}

# 成员测试
{% if 'nginx' in nginx_packages %}
Nginx在包列表中
{% endif %}

{% if 'apache' not in nginx_packages %}
Apache不在包列表中
{% endif %}

# 空值测试
{% if nginx_packages is empty %}
Nginx包列表为空
{% endif %}

{% if nginx_packages is not empty %}
Nginx包列表不为空
{% endif %}

# 奇偶测试
{% if nginx_packages | length is even %}
Nginx包数量为偶数
{% endif %}

{% if nginx_packages | length is odd %}
Nginx包数量为奇数
{% endif %}

# 可迭代测试
{% if nginx_packages is iterable %}
Nginx包可迭代
{% endif %}
```

### 7.2.5 标签

```jinja2
# 标签示例

# if标签
{% if ssl_enabled %}
SSL已启用
{% elif http_port == 80 %}
使用HTTP
{% else %}
使用其他协议
{% endif %}

# for标签
{% for package in nginx_packages %}
- {{ package }}
{% endfor %}

{% for key, value in nginx_config.items() %}
{{ key }}: {{ value }}
{% endfor %}

{% for i in range(5) %}
{{ i }}
{% endfor %}

# set标签
{% set http_port = 80 %}
{% set https_port = 443 %}
{% set document_root = '/var/www/html' %}

# block标签
{% block content %}
这是内容块
{% endblock %}

# extends标签
{% extends 'base.j2' %}

# include标签
{% include 'partial.j2' %}

# macro标签
{% macro render_server(server) %}
server {
    listen {{ server.port }};
    server_name {{ server.name }};
    root {{ server.root }};
}
{% endmacro %}

{{ render_server({'port': 80, 'name': 'example.com', 'root': '/var/www/html'}) }}

# filter标签
{% filter upper %}
{{ server_name }}
{% endfilter %}

# autoescape标签
{% autoescape false %}
{{ user_input }}
{% endautoescape %}
```

---

## 7.3 模板文件

### 7.3.1 Nginx配置模板

```jinja2
# templates/nginx.conf.j2
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

    {% if nginx_custom_config is defined %}
    {{ nginx_custom_config | indent(4) }}
    {% endif %}

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### 7.3.2 Nginx站点配置模板

```jinja2
# templates/site.conf.j2
server {
    listen {{ site_port }};
    listen [::]:{{ site_port }};
    server_name {{ site_name }};
    root {{ site_root }};
    index index.html index.htm index.php;

    {% if site_ssl_enabled %}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate {{ site_ssl_cert_path }};
    ssl_certificate_key {{ site_ssl_key_path }};
    {% endif %}

    {% if site_access_log is defined %}
    access_log {{ site_access_log }};
    {% endif %}

    {% if site_error_log is defined %}
    error_log {{ site_error_log }};
    {% endif %}

    {% if site_max_body_size is defined %}
    client_max_body_size {{ site_max_body_size }};
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }

    {% if site_php_enabled %}
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
    {% endif %}

    {% if site_proxy_enabled %}
    location / {
        proxy_pass {{ site_proxy_pass }};
        proxy_set Host $host;
        proxy_set X-Real-IP $remote_addr;
        proxy_set X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set X-Forwarded-Proto $scheme;
    }
    {% endif %}

    {% if site_static_files is defined %}
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires {{ site_static_files_expires | default('1y') }};
        add_header Cache-Control "public, immutable";
    }
    {% endif %}

    location ~ /\.ht {
        deny all;
    }
}
```

### 7.3.3 MySQL配置模板

```jinja2
# templates/my.cnf.j2
[mysqld]
# 基本配置
port = {{ mysql_port }}
datadir = {{ mysql_datadir }}
socket = {{ mysql_socket }}
pid-file = {{ mysql_pidfile }}

# 网络配置
bind-address = {{ mysql_bind_address }}

# 字符集配置
character-set-server = {{ mysql_character_set | default('utf8mb4') }}
collation-server = {{ mysql_collation | default('utf8mb4_unicode_ci') }}

# 连接配置
max_connections = {{ mysql_max_connections | default(200) }}
max_connect_errors = {{ mysql_max_connect_errors | default(100000) }}

# InnoDB配置
innodb_buffer_pool_size = {{ mysql_innodb_buffer_pool_size | default('1G') }}
innodb_log_file_size = {{ mysql_innodb_log_file_size | default('256M') }}
innodb_flush_log_at_trx_commit = {{ mysql_innodb_flush_log_at_trx_commit | default(1) }}
innodb_flush_method = {{ mysql_innodb_flush_method | default('O_DIRECT') }}

# 查询缓存
{% if mysql_query_cache_size is defined %}
query_cache_size = {{ mysql_query_cache_size }}
query_cache_type = 1
query_cache_limit = {{ mysql_query_cache_limit | default('2M') }}
{% endif %}

# 慢查询日志
{% if mysql_slow_query_log is defined %}
slow_query_log = {{ mysql_slow_query_log }}
slow_query_log_file = {{ mysql_slow_query_log_file }}
long_query_time = {{ mysql_long_query_time | default(2) }}
{% endif %}

# 二进制日志
{% if mysql_log_bin is defined %}
log_bin = {{ mysql_log_bin }}
binlog_format = {{ mysql_binlog_format | default('ROW') }}
expire_logs_days = {{ mysql_expire_logs_days | default(7) }}
max_binlog_size = {{ mysql_max_binlog_size | default('100M') }}
{% endif %}

# 错误日志
log_error = {{ mysql_log_error }}

# 安全配置
{% if mysql_skip_name_resolve is defined %}
skip-name-resolve = {{ mysql_skip_name_resolve }}
{% endif %}

{% if mysql_local_infile is defined %}
local-infile = {{ mysql_local_infile }}
{% endif %}

[mysql]
default-character-set = {{ mysql_character_set | default('utf8mb4') }}

[client]
port = {{ mysql_port }}
socket = {{ mysql_socket }}
default-character-set = {{ mysql_character_set | default('utf8mb4') }}
```

---

## 7.4 模板继承

### 7.4.1 基础模板

```jinja2
# templates/base.j2
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Default Title{% endblock %}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
        }
        header {
            background-color: #333;
            color: white;
            padding: 10px;
        }
        footer {
            background-color: #333;
            color: white;
            padding: 10px;
            text-align: center;
        }
    </style>
    {% block styles %}{% endblock %}
</head>
<body>
    <header>
        {% block header %}Default Header{% endblock %}
    </header>
    
    <main>
        {% block content %}Default Content{% endblock %}
    </main>
    
    <footer>
        {% block footer %}Default Footer{% endblock %}
    </footer>
    
    <script>
        {% block scripts %}{% endblock %}
    </script>
</body>
</html>
```

### 7.4.2 子模板

```jinja2
# templates/index.j2
{% extends 'base.j2' %}

{% block title %}Home Page{% endblock %}

{% block header %}
<h1>Welcome to {{ server_name }}</h1>
{% endblock %}

{% block content %}
<p>This is the home page of {{ server_name }}.</p>
<p>Server running on port {{ http_port }}.</p>
{% endblock %}

{% block footer %}
<p>&copy; {{ ansible_date_time.year }} {{ server_name }}</p>
{% endblock %}
```

### 7.4.3 使用模板继承

```yaml
# playbook-template-inheritance.yml
---
- name: 使用模板继承的Playbook示例
  hosts: webservers
  become: true
  vars:
    server_name: example.com
    http_port: 80
  tasks:
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: 创建首页（使用模板继承）
      template:
        src: templates/index.j2
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
```

---

## 7.5 实战：使用模板

### 7.5.1 创建Nginx配置模板

```bash
# 创建Nginx配置模板

# 创建templates目录
mkdir -p templates

# 创建Nginx配置模板
cat > templates/nginx.conf.j2 << 'EOF'
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

# 创建站点配置模板
cat > templates/site.conf.j2 << 'EOF'
server {
    listen {{ site_port }};
    listen [::]:{{ site_port }};
    server_name {{ site_name }};
    root {{ site_root }};
    index index.html index.htm;

    {% if site_ssl_enabled %}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate {{ site_ssl_cert_path }};
    ssl_certificate_key {{ site_ssl_key_path }};
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

### 7.5.2 使用模板

```bash
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
```

---

## 本章小结

- 模板是Ansible中用于生成配置文件的机制
- 模板特性包括动态生成、变量替换、条件渲染、循环渲染、继承机制
- Jinja2语法包括变量输出、表达式、过滤器、测试、标签
- 变量输出使用{{ variable }}语法
- 表达式使用{% expression %}语法
- 过滤器使用{{ variable | filter }}语法
- 测试使用{{ variable is test }}语法
- 标签使用{% tag %}语法
- 模板继承使用extends和block标签
- 可以使用template模块使用模板
- 可以使用Jinja2过滤器处理变量

---

**下一章：条件和循环**
