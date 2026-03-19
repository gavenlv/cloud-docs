# Playbook编写

## 3.1 Playbook原理

### 3.1.1 Playbook的核心概念

```
Playbook的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Playbook是什么？                                    │
└─────────────────────────────────────────────────────────────────┘

Playbook是Ansible中用于定义自动化任务的YAML文件：

1. Play结构
   ├── 目标主机
   ├── 变量定义
   ├── 任务列表
   ├── 处理器
   └── 角色引用

2. Task结构
   ├── 模块调用
   ├── 模块参数
   ├── 任务名称
   ├── 条件判断
   └── 循环控制

3. Handler机制
   ├── 通知机制
   ├── 延迟执行
   ├── 幂等性保证
   └── 执行顺序

4. 执行流程
   ├── 收集Facts
   ├── 执行任务
   ├── 触发Handler
   ├── 返回结果
   └── 显示摘要

5. 错误处理
   ├── 忽略错误
   ├── 错误恢复
   ├── 失败继续
   └── 自定义错误处理
```

### 3.1.2 Playbook执行流程

```
Playbook执行流程：

┌─────────────────────────────────────────────────────────────────┐
│  Playbook执行流程                                    │
└─────────────────────────────────────────────────────────────────┘

1. 解析阶段

解析步骤：
├── 读取Playbook文件
├── 解析YAML语法
├── 验证Playbook结构
├── 加载变量文件
└── 构建执行计划

解析特点：
├── 语法检查
├── 变量替换
├── 模块验证
└── 依赖分析

2. 执行阶段

执行步骤：
├── 连接目标主机
├── 收集主机Facts
├── 执行前置任务
├── 执行主任务
├── 触发Handler
├── 执行后置任务
└── 返回执行结果

执行特点：
├── 并行执行
├── 幂等性保证
├── 错误处理
└── 状态跟踪

3. 结果阶段

结果步骤：
├── 收集执行结果
├── 计算执行摘要
├── 显示执行状态
├── 生成执行报告
└── 保存执行日志

结果特点：
├── 详细输出
├── 错误汇总
├── 变更统计
└── 性能统计

执行流程图：
┌──────────────┐
│  读取Playbook │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  解析YAML    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  验证结构    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  加载变量    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  连接主机    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  收集Facts   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  执行任务    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  触发Handler │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  返回结果    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  显示摘要    │
└──────────────┘
```

---

## 3.2 Play结构

### 3.2.1 基本Play结构

```yaml
# playbook-basic.yml
---
- name: 基本Play示例
  hosts: webservers
  become: true
  vars:
    http_port: 80
    document_root: /var/www/html
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 创建文档根目录
      file:
        path: "{{ document_root }}"
        state: directory
        mode: '0755'
    
    - name: 创建首页文件
      copy:
        content: "Hello, World!"
        dest: "{{ document_root }}/index.html"
        mode: '0644'
```

### 3.2.2 多Play结构

```yaml
# playbook-multi-play.yml
---
- name: 配置Web服务器
  hosts: webservers
  become: true
  vars:
    http_port: 80
    document_root: /var/www/html
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes

- name: 配置数据库服务器
  hosts: dbservers
  become: true
  vars:
    mysql_root_password: secret
    mysql_database: appdb
  tasks:
    - name: 安装MySQL
      apt:
        name: mysql-server
        state: present
        update_cache: yes
    
    - name: 启动MySQL服务
      service:
        name: mysql
        state: started
        enabled: yes
    
    - name: 创建数据库
      mysql_db:
        name: "{{ mysql_database }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

- name: 配置监控服务器
  hosts: monitoring
  become: true
  vars:
    prometheus_port: 9090
    grafana_port: 3000
  tasks:
    - name: 安装Prometheus
      apt:
        name: prometheus
        state: present
        update_cache: yes
    
    - name: 启动Prometheus服务
      service:
        name: prometheus
        state: started
        enabled: yes
```

### 3.2.3 Play属性

```yaml
# playbook-attributes.yml
---
- name: Play属性示例
  hosts: webservers
  become: true
  become_method: sudo
  become_user: root
  become_flags: '-H -S -n'
  remote_user: ansible
  gather_facts: true
  fact_path: /etc/ansible/facts.d
  vars:
    http_port: 80
    document_root: /var/www/html
  vars_files:
    - vars/common.yml
    - vars/webservers.yml
  vars_prompt:
    - name: mysql_root_password
      prompt: "请输入MySQL root密码"
      private: yes
      confirm: yes
  pre_tasks:
    - name: 检查系统版本
      debug:
        msg: "系统版本: {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: 检查可用内存
      debug:
        msg: "可用内存: {{ ansible_memtotal_mb }} MB"
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
      notify:
        - 重启Nginx服务
    
    - name: 创建文档根目录
      file:
        path: "{{ document_root }}"
        state: directory
        mode: '0755'
  post_tasks:
    - name: 验证Nginx配置
      command: nginx -t
      register: nginx_test
      changed_when: false
    
    - name: 显示Nginx配置测试结果
      debug:
        msg: "{{ nginx_test.stdout }}"
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
  roles:
    - role: common
    - role: nginx
      vars:
        http_port: 80
    - role: monitoring
      when: monitoring_enabled | default(false)
```

---

## 3.3 Task结构

### 3.3.1 基本Task结构

```yaml
# task-basic.yml
---
- name: 基本Task示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        mode: '0755'
    
    - name: 创建首页文件
      copy:
        content: "Hello, World!"
        dest: /var/www/html/index.html
        mode: '0644'
```

### 3.3.2 Task属性

```yaml
# task-attributes.yml
---
- name: Task属性示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（带条件）
      apt:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 安装Nginx（带循环）
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - nginx
        - nginx-extras
        - nginx-common
    
    - name: 安装Nginx（带忽略错误）
      apt:
        name: nginx
        state: present
        update_cache: yes
      ignore_errors: yes
    
    - name: 安装Nginx（带注册变量）
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
    
    - name: 安装Nginx（带变更条件）
      apt:
        name: nginx
        state: present
        update_cache: yes
      changed_when: nginx_install.changed
    
    - name: 安装Nginx（带失败条件）
      apt:
        name: nginx
        state: present
        update_cache: yes
      failed_when: nginx_install.rc != 0
    
    - name: 安装Nginx（带重试）
      apt:
        name: nginx
        state: present
        update_cache: yes
      retries: 3
      delay: 5
      until: nginx_install is succeeded
    
    - name: 安装Nginx（带超时）
      apt:
        name: nginx
        state: present
        update_cache: yes
      async: 300
      poll: 10
    
    - name: 安装Nginx（带标签）
      apt:
        name: nginx
        state: present
        update_cache: yes
      tags:
        - nginx
        - web
        - install
    
    - name: 安装Nginx（带通知）
      apt:
        name: nginx
        state: present
        update_cache: yes
      notify:
        - 重启Nginx服务
        - 重新加载Nginx配置
    
    - name: 安装Nginx（带本地操作）
      apt:
        name: nginx
        state: present
        update_cache: yes
      delegate_to: localhost
      run_once: true
    
    - name: 安装Nginx（带become）
      apt:
        name: nginx
        state: present
        update_cache: yes
      become: true
      become_method: sudo
      become_user: root
```

### 3.3.3 Task模块参数

```yaml
# task-module-params.yml
---
- name: Task模块参数示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建用户（使用模块参数）
      user:
        name: webuser
        shell: /bin/bash
        home: /home/webuser
        groups:
          - www-data
        append: yes
        state: present
    
    - name: 创建目录（使用模块参数）
      file:
        path: /var/www/html
        state: directory
        owner: webuser
        group: www-data
        mode: '0755'
        recurse: yes
    
    - name: 复制文件（使用模块参数）
      copy:
        src: files/index.html
        dest: /var/www/html/index.html
        owner: webuser
        group: www-data
        mode: '0644'
        backup: yes
    
    - name: 创建模板文件（使用模块参数）
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'nginx -t -c %s'
    
    - name: 安装包（使用模块参数）
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
        cache_valid_time: 3600
      loop:
        - nginx
        - nginx-extras
    
    - name: 启动服务（使用模块参数）
      service:
        name: nginx
        state: started
        enabled: yes
        pattern: nginx
        sleep: 5
        timeout: 60
    
    - name: 执行命令（使用模块参数）
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
    
    - name: 执行Shell命令（使用模块参数）
      shell: |
        if [ -f /etc/nginx/nginx.conf ]; then
          nginx -t
        else
          echo "Nginx配置文件不存在"
          exit 1
        fi
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
    
    - name: 获取URL内容（使用模块参数）
      uri:
        url: http://localhost
        method: GET
        status_code: 200
        timeout: 30
        return_content: yes
      register: web_content
      changed_when: false
    
    - name: 显示Web内容
      debug:
        msg: "{{ web_content.content }}"
```

---

## 3.4 Handler机制

### 3.4.1 Handler基本用法

```yaml
# handler-basic.yml
---
- name: Handler基本用法示例
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
      notify:
        - 重启Nginx服务
    
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
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
    
    - name: 重新加载Nginx配置
      service:
        name: nginx
        state: reloaded
```

### 3.4.2 Handler高级用法

```yaml
# handler-advanced.yml
---
- name: Handler高级用法示例
  hosts: webservers
  become: true
  vars:
    nginx_config_changed: false
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
      notify:
        - 重启Nginx服务
    
    - name: 配置Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        backup: yes
        validate: 'nginx -t -c %s'
      register: nginx_config
      notify:
        - 重启Nginx服务
        - 重新加载Nginx配置
    
    - name: 标记配置变更
      set_fact:
        nginx_config_changed: true
      when: nginx_config.changed
    
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
    
    - name: 显示配置变更状态
      debug:
        msg: "Nginx配置已变更: {{ nginx_config_changed }}"
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
      listen:
        - 重启Nginx服务
        - Nginx服务重启
    
    - name: 重新加载Nginx配置
      service:
        name: nginx
        state: reloaded
      listen:
        - 重新加载Nginx配置
        - Nginx配置重载
      when: nginx_config_changed | bool
    
    - name: 测试Nginx配置
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
      listen:
        - 测试Nginx配置
```

---

## 3.5 实战：编写Playbook

### 3.5.1 创建简单Playbook

```bash
# 创建简单Playbook

# 创建Playbook文件
cat > playbook-simple.yml << 'EOF'
---
- name: 简单Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        mode: '0755'
    
    - name: 创建首页文件
      copy:
        content: "Hello, World!"
        dest: /var/www/html/index.html
        mode: '0644'
EOF

# 运行Playbook
ansible-playbook playbook-simple.yml

# 预期输出：
# PLAY [简单Playbook示例] **************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [创建文档根目录] ***************************************************
# changed: [localhost]
# TASK [创建首页文件] *****************************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=4    unreachable=0    failed=0
```

### 3.5.2 创建复杂Playbook

```bash
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
```

### 3.5.3 使用Handler

```bash
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
```

---

## 本章小结

- Playbook是Ansible中用于定义自动化任务的YAML文件
- Playbook包括Play结构、Task结构、Handler机制、执行流程、错误处理
- Play结构包括目标主机、变量定义、任务列表、处理器、角色引用
- Task结构包括模块调用、模块参数、任务名称、条件判断、循环控制
- Handler机制包括通知机制、延迟执行、幂等性保证、执行顺序
- Playbook执行流程包括解析阶段、执行阶段、结果阶段
- 可以使用ansible-playbook命令运行Playbook
- 可以使用Handler实现延迟执行和幂等性保证

---

**下一章：模块使用**
