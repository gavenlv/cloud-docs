# 模块使用

## 4.1 模块原理

### 4.1.1 模块的核心概念

```
模块的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  模块是什么？                                           │
└─────────────────────────────────────────────────────────────────┘

模块是Ansible中用于执行具体任务的工具：

1. 模块分类
   ├── 系统模块
   ├── 文件模块
   ├── 包管理模块
   ├── 服务模块
   ├── 网络模块
   └── 云平台模块

2. 模块特性
   ├── 幂等性
   ├── 原子性
   ├── 幂等性保证
   └── 错误处理

3. 模块参数
   ├── 必需参数
   ├── 可选参数
   ├── 默认值
   └── 参数验证

4. 模块返回
   ├── changed状态
   ├── 返回数据
   ├── 错误信息
   └── 警告信息

5. 模块开发
   ├── Python模块
   ├── Shell模块
   ├── 自定义模块
   └── 模块测试
```

### 4.1.2 模块执行原理

```
模块执行原理：

┌─────────────────────────────────────────────────────────────────┐
│  模块执行原理                                           │
└─────────────────────────────────────────────────────────────────┘

1. 模块传输

传输流程：
├── 控制节点打包模块
├── 控制节点传输模块到被管理节点
├── 被管理节点接收模块
├── 被管理节点解压模块
└── 被管理节点准备执行环境

传输特点：
├── 压缩传输
├── 加密传输
├── 增量传输
└── 并行传输

2. 模块执行

执行流程：
├── 被管理节点加载模块
├── 被管理节点解析参数
├── 被管理节点执行模块
├── 被管理节点收集结果
└── 被管理节点返回结果

执行特点：
├── 沙箱执行
├── 权限隔离
├── 资源限制
└── 超时控制

3. 结果返回

返回流程：
├── 被管理节点序列化结果
├── 被管理节点返回结果
├── 控制节点接收结果
├── 控制节点反序列化结果
└── 控制节点处理结果

返回特点：
├── JSON格式
├── 结构化数据
├── 错误信息
└── 性能统计

模块执行图：
┌──────────────┐
│  控制节点     │
│  ┌────────┐  │
│  │ Playbook│  │
│  └───┬────┘  │
└──────┼───────┘
       │
       ▼
┌──────────────┐
│  打包模块     │
│  ┌────────┐  │
│  │ 模块   │  │
│  └───┬────┘  │
└──────┼───────┘
       │ SSH
       │
       ▼
┌──────────────┐
│  被管理节点   │
│  ┌────────┐  │
│  │ 接收   │  │
│  └───┬────┘  │
└──────┼───────┘
       │
       ▼
┌──────────────┐
│  解压模块     │
│  ┌────────┐  │
│  │ 模块   │  │
│  └───┬────┘  │
└──────┼───────┘
       │
       ▼
┌──────────────┐
│  执行模块     │
│  ┌────────┐  │
│  │ 执行   │  │
│  └───┬────┘  │
└──────┼───────┘
       │
       ▼
┌──────────────┐
│  返回结果     │
│  ┌────────┐  │
│  │ 结果   │  │
│  └───┬────┘  │
└──────┼───────┘
       │ SSH
       │
       ▼
┌──────────────┐
│  控制节点     │
│  ┌────────┐  │
│  │ 处理   │  │
│  └────────┘  │
└──────────────┘
```

---

## 4.2 常用模块

### 4.2.1 文件模块

```yaml
# file-modules.yml
---
- name: 文件模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建目录
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: 创建文件
      file:
        path: /var/www/html/index.html
        state: touch
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: 创建符号链接
      file:
        src: /var/www/html
        dest: /var/www
        state: link
    
    - name: 复制文件
      copy:
        src: files/index.html
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
        backup: yes
    
    - name: 创建模板文件
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'nginx -t -c %s'
    
    - name: 获取文件信息
      stat:
        path: /var/www/html/index.html
      register: file_info
    
    - name: 显示文件信息
      debug:
        msg: "文件大小: {{ file_info.stat.size }} 字节"
    
    - name: 查找文件
      find:
        paths: /var/www/html
        patterns: "*.html"
        recurse: yes
      register: html_files
    
    - name: 显示找到的文件
      debug:
        msg: "找到 {{ html_files.matched }} 个HTML文件"
    
    - name: 同步目录
      synchronize:
        src: /local/path/
        dest: /var/www/html/
        delete: yes
        recursive: yes
    
    - name: 删除文件
      file:
        path: /var/www/html/old.html
        state: absent
```

### 4.2.2 包管理模块

```yaml
# package-modules.yml
---
- name: 包管理模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（Debian/Ubuntu）
      apt:
        name: nginx
        state: present
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
    
    - name: 安装Nginx（RedHat/CentOS）
      yum:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "RedHat"
    
    - name: 安装多个包
      apt:
        name:
          - nginx
          - nginx-extras
          - python3-certbot-nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 更新所有包
      apt:
        upgrade: dist
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 删除包
      apt:
        name: nginx
        state: absent
        purge: yes
        autoremove: yes
      when: ansible_os_family == "Debian"
    
    - name: 安装特定版本的包
      apt:
        name: nginx=1.18.0-0ubuntu1
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 从本地文件安装包
      apt:
        deb: /tmp/nginx_1.18.0-0ubuntu1_amd64.deb
        state: present
      when: ansible_os_family == "Debian"
    
    - name: 添加APT仓库
      apt_repository:
        repo: 'ppa:ondrej/nginx'
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: 添加APT密钥
      apt_key:
        url: https://nginx.org/keys/nginx_signing.key
        state: present
      when: ansible_os_family == "Debian"
    
    - name: 使用pip安装Python包
      pip:
        name:
          - flask
          - gunicorn
        state: present
        executable: pip3
    
    - name: 使用npm安装Node.js包
      npm:
        name: express
        path: /var/www/html
        state: present
```

### 4.2.3 服务模块

```yaml
# service-modules.yml
---
- name: 服务模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 停止Nginx服务
      service:
        name: nginx
        state: stopped
        enabled: no
    
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
    
    - name: 重新加载Nginx服务
      service:
        name: nginx
        state: reloaded
    
    - name: 检查Nginx服务状态
      service:
        name: nginx
        state: started
        enabled: yes
      register: nginx_status
    
    - name: 显示Nginx服务状态
      debug:
        msg: "Nginx服务状态: {{ nginx_status.status.ActiveState }}"
    
    - name: 使用systemd管理服务
      systemd:
        name: nginx
        state: started
        enabled: yes
        daemon_reload: yes
    
    - name: 启动多个服务
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - mysql
        - redis
    
    - name: 等待服务启动
      service:
        name: nginx
        state: started
      register: nginx_service
      until: nginx_service.status.ActiveState == "active"
      retries: 5
      delay: 5
    
    - name: 配置服务参数
      systemd:
        name: nginx
        enabled: yes
        masked: no
        scope: system
```

### 4.2.4 用户和组模块

```yaml
# user-group-modules.yml
---
- name: 用户和组模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建用户
      user:
        name: webuser
        shell: /bin/bash
        home: /home/webuser
        groups:
          - www-data
          - sudo
        append: yes
        state: present
    
    - name: 创建用户（带密码）
      user:
        name: webuser
        password: "{{ 'password' | password_hash('sha512') }}"
        shell: /bin/bash
        home: /home/webuser
        state: present
    
    - name: 创建系统用户
      user:
        name: nginx
        system: yes
        shell: /usr/sbin/nologin
        home: /var/lib/nginx
        create_home: no
        state: present
    
    - name: 删除用户
      user:
        name: olduser
        state: absent
        remove: yes
    
    - name: 创建组
      group:
        name: webgroup
        state: present
    
    - name: 创建系统组
      group:
        name: www-data
        system: yes
        state: present
    
    - name: 添加SSH密钥到用户
      authorized_key:
        user: webuser
        key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/..."
        state: present
    
    - name: 添加多个SSH密钥到用户
      authorized_key:
        user: webuser
        key: "{{ item }}"
        state: present
      loop:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/..."
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6/..."
    
    - name: 修改用户密码
      user:
        name: webuser
        password: "{{ 'newpassword' | password_hash('sha512') }}"
        state: present
```

### 4.2.5 系统模块

```yaml
# system-modules.yml
---
- name: 系统模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 执行命令
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
    
    - name: 执行Shell命令
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
    
    - name: 设置环境变量
      environment:
        PATH: "/usr/local/bin:{{ ansible_env.PATH }}"
        NODE_ENV: production
      command: node app.js
    
    - name: 创建Cron任务
      cron:
        name: "备份数据库"
        minute: "0"
        hour: "2"
        job: "/usr/bin/mysqldump -u root -p{{ mysql_password }} appdb > /backup/appdb_$(date +\%Y\%m\%d).sql"
        state: present
    
    - name: 删除Cron任务
      cron:
        name: "备份数据库"
        state: absent
    
    - name: 创建Cron任务（带特殊字符）
      cron:
        name: "备份数据库"
        minute: "0"
        hour: "2"
        job: "/usr/bin/mysqldump -u root -p'{{ mysql_password }}' appdb > /backup/appdb_$(date +\\%Y\\%m\\%d).sql"
        state: present
    
    - name: 配置时区
      timezone:
        name: Asia/Shanghai
    
    - name: 配置主机名
      hostname:
        name: webserver01
    
    - name: 配置系统内核参数
      sysctl:
        name: net.ipv4.ip_forward
        value: '1'
        state: present
        reload: yes
    
    - name: 配置多个系统内核参数
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
      loop:
        - { name: 'net.ipv4.ip_forward', value: '1' }
        - { name: 'net.ipv4.conf.all.forwarding', value: '1' }
        - { name: 'net.ipv6.conf.all.forwarding', value: '1' }
    
    - name: 配置系统限制
      pam_limits:
        domain: '*'
        limit_type: soft
        limit_item: nofile
        value: 65536
```

---

## 4.3 模块参数

### 4.3.1 必需参数

```yaml
# required-params.yml
---
- name: 必需参数示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建文件（必需参数）
      file:
        path: /var/www/html/index.html
        state: touch
    
    - name: 复制文件（必需参数）
      copy:
        src: files/index.html
        dest: /var/www/html/index.html
    
    - name: 安装包（必需参数）
      apt:
        name: nginx
        state: present
    
    - name: 启动服务（必需参数）
      service:
        name: nginx
        state: started
    
    - name: 创建用户（必需参数）
      user:
        name: webuser
        state: present
```

### 4.3.2 可选参数

```yaml
# optional-params.yml
---
- name: 可选参数示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建文件（可选参数）
      file:
        path: /var/www/html/index.html
        state: touch
        owner: www-data
        group: www-data
        mode: '0644'
        modification_time: now
        access_time: now
    
    - name: 复制文件（可选参数）
      copy:
        src: files/index.html
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
        backup: yes
        force: yes
        remote_src: no
    
    - name: 安装包（可选参数）
      apt:
        name: nginx
        state: present
        update_cache: yes
        cache_valid_time: 3600
        install_recommends: yes
        allow_unauthenticated: no
    
    - name: 启动服务（可选参数）
      service:
        name: nginx
        state: started
        enabled: yes
        pattern: nginx
        sleep: 5
        timeout: 60
    
    - name: 创建用户（可选参数）
      user:
        name: webuser
        state: present
        shell: /bin/bash
        home: /home/webuser
        groups:
          - www-data
        append: yes
        password: "{{ 'password' | password_hash('sha512') }}"
        generate_ssh_key: yes
        ssh_key_bits: 4096
```

### 4.3.3 默认值

```yaml
# default-values.yml
---
- name: 默认值示例
  hosts: webservers
  become: true
  vars:
    default_owner: www-data
    default_group: www-data
    default_mode: '0644'
  tasks:
    - name: 创建文件（使用默认值）
      file:
        path: /var/www/html/index.html
        state: touch
        owner: "{{ default_owner }}"
        group: "{{ default_group }}"
        mode: "{{ default_mode }}"
    
    - name: 复制文件（使用默认值）
      copy:
        src: files/index.html
        dest: /var/www/html/index.html
        owner: "{{ default_owner }}"
        group: "{{ default_group }}"
        mode: "{{ default_mode }}"
    
    - name: 安装包（使用默认值）
      apt:
        name: nginx
        state: present
        update_cache: "{{ ansible_date_time.epoch | int | int < ansible_date_time.epoch | int + 3600 | ternary('yes', 'no') }}"
```

---

## 4.4 模块返回值

### 4.4.1 changed状态

```yaml
# changed-status.yml
---
- name: changed状态示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
    
    - name: 显示安装状态
      debug:
        msg: "Nginx安装状态: {{ nginx_install.changed }}"
    
    - name: 创建文件
      file:
        path: /var/www/html/index.html
        state: touch
      register: file_create
    
    - name: 显示文件创建状态
      debug:
        msg: "文件创建状态: {{ file_create.changed }}"
    
    - name: 启动服务
      service:
        name: nginx
        state: started
        enabled: yes
      register: service_start
    
    - name: 显示服务启动状态
      debug:
        msg: "服务启动状态: {{ service_start.changed }}"
```

### 4.4.2 返回数据

```yaml
# return-data.yml
---
- name: 返回数据示例
  hosts: webservers
  become: true
  tasks:
    - name: 获取文件信息
      stat:
        path: /var/www/html/index.html
      register: file_info
    
    - name: 显示文件信息
      debug:
        msg:
          - "文件路径: {{ file_info.stat.path }}"
          - "文件大小: {{ file_info.stat.size }} 字节"
          - "文件权限: {{ file_info.stat.mode }}"
          - "文件所有者: {{ file_info.stat.pw_name }}"
          - "文件组: {{ file_info.stat.gr_name }}"
          - "文件类型: {{ file_info.stat.issym | ternary('符号链接', file_info.stat.isdir | ternary('目录', '文件')) }}"
    
    - name: 执行命令
      command: nginx -t
      register: nginx_test
      changed_when: false
    
    - name: 显示命令输出
      debug:
        msg:
          - "命令: {{ nginx_test.cmd }}"
          - "返回码: {{ nginx_test.rc }}"
          - "标准输出: {{ nginx_test.stdout }}"
          - "标准错误: {{ nginx_test.stderr }}"
    
    - name: 获取URL内容
      uri:
        url: http://localhost
        method: GET
        return_content: yes
      register: web_content
      changed_when: false
    
    - name: 显示URL内容
      debug:
        msg:
          - "URL: {{ web_content.url }}"
          - "状态码: {{ web_content.status }}"
          - "内容类型: {{ web_content.content_type }}"
          - "内容长度: {{ web_content.content | length }}"
```

---

## 4.5 实战：使用模块

### 4.5.1 使用文件模块

```bash
# 创建使用文件模块的Playbook

# 创建Playbook文件
cat > playbook-file-modules.yml << 'EOF'
---
- name: 使用文件模块的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建目录
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: 创建文件
      file:
        path: /var/www/html/index.html
        state: touch
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: 创建符号链接
      file:
        src: /var/www/html
        dest: /var/www
        state: link
    
    - name: 获取文件信息
      stat:
        path: /var/www/html/index.html
      register: file_info
    
    - name: 显示文件信息
      debug:
        msg:
          - "文件路径: {{ file_info.stat.path }}"
          - "文件大小: {{ file_info.stat.size }} 字节"
          - "文件权限: {{ file_info.stat.mode }}"
          - "文件所有者: {{ file_info.stat.pw_name }}"
          - "文件组: {{ file_info.stat.gr_name }}"
EOF

# 运行Playbook
ansible-playbook playbook-file-modules.yml

# 预期输出：
# PLAY [使用文件模块的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建目录] ********************************************************
# changed: [localhost]
# TASK [创建文件] ********************************************************
# changed: [localhost]
# TASK [创建符号链接] ****************************************************
# changed: [localhost]
# TASK [获取文件信息] ****************************************************
# ok: [localhost]
# TASK [显示文件信息] ****************************************************
# ok: [localhost] => {
#     "msg": [
#         "文件路径: /var/www/html/index.html",
#         "文件大小: 0 字节",
#         "文件权限: 0644",
#         "文件所有者: www-data",
#         "文件组: www-data"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=3    unreachable=0    failed=0
```

### 4.5.2 使用包管理模块

```bash
# 创建使用包管理模块的Playbook

# 创建Playbook文件
cat > playbook-package-modules.yml << 'EOF'
---
- name: 使用包管理模块的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      changed_when: false
    
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
    
    - name: 显示安装状态
      debug:
        msg: "Nginx安装状态: {{ nginx_install.changed }}"
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 检查Nginx版本
      command: nginx -v
      register: nginx_version
      changed_when: false
      failed_when: false
    
    - name: 显示Nginx版本
      debug:
        msg: "Nginx版本: {{ nginx_version.stderr }}"
EOF

# 运行Playbook
ansible-playbook playbook-package-modules.yml

# 预期输出：
# PLAY [使用包管理模块的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [更新系统包] ********************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [显示安装状态] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装状态: true"
# }
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [检查Nginx版本] ****************************************************
# ok: [localhost]
# TASK [显示Nginx版本] ****************************************************
# ok: [localhost] => {
#     "msg": "Nginx版本: nginx version: nginx/1.18.0"
# }
# PLAY RECAP **************************************************************
# localhost: ok=6    changed=2    unreachable=0    failed=0
```

### 4.5.3 使用服务模块

```bash
# 创建使用服务模块的Playbook

# 创建Playbook文件
cat > playbook-service-modules.yml << 'EOF'
---
- name: 使用服务模块的Playbook示例
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
      register: nginx_service
    
    - name: 显示服务状态
      debug:
        msg: "Nginx服务状态: {{ nginx_service.status.ActiveState }}"
    
    - name: 检查Nginx服务
      service:
        name: nginx
        state: started
      register: nginx_check
    
    - name: 显示检查结果
      debug:
        msg: "Nginx服务检查结果: {{ nginx_check.status.ActiveState }}"
    
    - name: 重新加载Nginx服务
      service:
        name: nginx
        state: reloaded
    
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
EOF

# 运行Playbook
ansible-playbook playbook-service-modules.yml

# 预期输出：
# PLAY [使用服务模块的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [显示服务状态] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务状态: active"
# }
# TASK [检查Nginx服务] ****************************************************
# ok: [localhost]
# TASK [显示检查结果] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务检查结果: active"
# }
# TASK [重新加载Nginx服务] ************************************************
# changed: [localhost]
# TASK [重启Nginx服务] ****************************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=4    unreachable=0    failed=0
```

---

## 本章小结

- 模块是Ansible中用于执行具体任务的工具
- 模块包括系统模块、文件模块、包管理模块、服务模块、网络模块、云平台模块
- 模块特性包括幂等性、原子性、幂等性保证、错误处理
- 模块参数包括必需参数、可选参数、默认值、参数验证
- 模块返回包括changed状态、返回数据、错误信息、警告信息
- 模块执行原理包括模块传输、模块执行、结果返回
- 可以使用file模块管理文件和目录
- 可以使用apt/yum模块管理软件包
- 可以使用service模块管理系统服务
- 可以使用user/group模块管理用户和组
- 可以使用command/shell模块执行命令

---

**下一章：角色开发**
