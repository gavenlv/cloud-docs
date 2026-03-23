# 变量管理

## 6.1 变量原理

### 6.1.1 变量的核心概念

```
变量的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  变量是什么？                                             │
└─────────────────────────────────────────────────────────────────┘

变量是Ansible中用于存储和传递数据的机制：

1. 变量类型
   ├── 字符串
   ├── 数字
   ├── 布尔值
   ├── 列表
   └── 字典

2. 变量定义
   ├── Playbook中定义
   ├── Inventory中定义
   ├── 角色中定义
   ├── 命令行定义
   └── 外部文件定义

3. 变量作用域
   ├── 全局变量
   ├── Play变量
   ├── Task变量
   ├── 主机变量
   └── 组变量

4. 变量优先级
   ├── 命令行变量
   ├── Play变量
   ├── 主机变量
   ├── 组变量
   └── 默认变量

5. 变量过滤
   ├── 字符串过滤
   ├── 数字过滤
   ├── 列表过滤
   └── 字典过滤
```

### 6.1.2 变量优先级

```
变量优先级：

┌─────────────────────────────────────────────────────────────────┐
│  变量优先级（从高到低）                             │
└─────────────────────────────────────────────────────────────────┘

1. 命令行变量
   ├── -e/--extra-vars
   ├── --extra-vars @file.yml
   └── 环境变量

2. Play变量
   ├── vars
   ├── vars_files
   └── vars_prompt

3. 主机变量
   ├── host_vars/hostname.yml
   └── Inventory主机变量

4. 组变量
   ├── group_vars/groupname.yml
   └── Inventory组变量

5. 角色变量
   ├── roles/rolename/vars/main.yml
   └── roles/rolename/defaults/main.yml

6. Facts
   ├── 收集的Facts
   └── 自定义Facts

7. 魔法变量
   ├── hostvars
   ├── groups
   ├── inventory_hostname
   └── 其他魔法变量
```

---

## 6.2 变量定义

### 6.2.1 Playbook中定义变量

```yaml
# playbook-vars.yml
---
- name: Playbook中定义变量示例
  hosts: webservers
  become: true
  vars:
    http_port: 80
    https_port: 443
    document_root: /var/www/html
    server_name: localhost
    nginx_config:
      worker_processes: auto
      worker_connections: 1024
      keepalive_timeout: 65
    nginx_packages:
      - nginx
      - nginx-extras
      - python3-certbot-nginx
    ssl_enabled: false
    ssl_cert_path: /etc/ssl/certs/nginx.crt
    ssl_key_path: /etc/ssl/private/nginx.key
  tasks:
    - name: 显示变量
      debug:
        msg:
          - "HTTP端口: {{ http_port }}"
          - "HTTPS端口: {{ https_port }}"
          - "文档根目录: {{ document_root }}"
          - "服务器名称: {{ server_name }}"
          - "工作进程数: {{ nginx_config.worker_processes }}"
          - "工作连接数: {{ nginx_config.worker_connections }}"
          - "保持连接超时: {{ nginx_config.keepalive_timeout }}"
          - "Nginx包: {{ nginx_packages }}"
          - "SSL启用: {{ ssl_enabled }}"
          - "SSL证书路径: {{ ssl_cert_path }}"
          - "SSL密钥路径: {{ ssl_key_path }}"
```

### 6.2.2 Inventory中定义变量

```ini
# inventory

[webservers]
web1.example.com http_port=8080 document_root=/var/www/web1
web2.example.com http_port=8080 document_root=/var/www/web2
web3.example.com http_port=8080 document_root=/var/www/web3

[webservers:vars]
https_port=8443
server_name=example.com
ssl_enabled=true
ssl_cert_path=/etc/ssl/certs/example.com.crt
ssl_key_path=/etc/ssl/private/example.com.key
```

```yaml
# inventory.yml

all:
  children:
    webservers:
      hosts:
        web1.example.com:
          http_port: 8080
          document_root: /var/www/web1
        web2.example.com:
          http_port: 8080
          document_root: /var/www/web2
        web3.example.com:
          http_port: 8080
          document_root: /var/www/web3
      vars:
        https_port: 8443
        server_name: example.com
        ssl_enabled: true
        ssl_cert_path: /etc/ssl/certs/example.com.crt
        ssl_key_path: /etc/ssl/private/example.com.key
```

### 6.2.3 主机变量和组变量

```yaml
# host_vars/web1.example.com
---
http_port: 8080
https_port: 8443
document_root: /var/www/web1
server_name: web1.example.com
ssl_enabled: true
ssl_cert_path: /etc/ssl/certs/web1.example.com.crt
ssl_key_path: /etc/ssl/private/web1.example.com.key

nginx_config:
  worker_processes: 4
  worker_connections: 1024
  keepalive_timeout: 65

nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx
```

```yaml
# group_vars/webservers.yml
---
https_port: 8443
server_name: example.com
ssl_enabled: true
ssl_cert_path: /etc/ssl/certs/example.com.crt
ssl_key_path: /etc/ssl/private/example.com.key

nginx_config:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65

nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx
```

### 6.2.4 命令行定义变量

```bash
# 命令行定义变量

# 使用-e/--extra-vars定义变量
ansible-playbook playbook.yml -e "http_port=8080"

# 使用-e/--extra-vars定义多个变量
ansible-playbook playbook.yml -e "http_port=8080" -e "https_port=8443"

# 使用-e/--extra-vars定义复杂变量
ansible-playbook playbook.yml -e '{"nginx_config": {"worker_processes": 4, "worker_connections": 1024}}'

# 使用-e/--extra-vars @file.yml从文件加载变量
cat > extra-vars.yml << 'EOF'
---
http_port: 8080
https_port: 8443
document_root: /var/www/html
server_name: example.com
ssl_enabled: true
EOF

ansible-playbook playbook.yml -e "@extra-vars.yml"

# 使用环境变量
export HTTP_PORT=8080
ansible-playbook playbook.yml -e "http_port={{ lookup('env', 'HTTP_PORT') }}"
```

---

## 6.3 变量作用域

### 6.3.1 全局变量

```yaml
# global-vars.yml
---
- name: 全局变量示例
  hosts: webservers
  become: true
  vars:
    global_http_port: 80
    global_https_port: 443
  tasks:
    - name: 显示全局变量
      debug:
        msg: "全局HTTP端口: {{ global_http_port }}"
    
    - name: 在Task中使用全局变量
      debug:
        msg: "全局HTTPS端口: {{ global_https_port }}"
```

### 6.3.2 Play变量

```yaml
# play-vars.yml
---
- name: Play变量示例
  hosts: webservers
  become: true
  vars:
    play_http_port: 80
    play_https_port: 443
  tasks:
    - name: 显示Play变量
      debug:
        msg: "Play HTTP端口: {{ play_http_port }}"
    
    - name: 在Task中使用Play变量
      debug:
        msg: "Play HTTPS端口: {{ play_https_port }}"
```

### 6.3.3 Task变量

```yaml
# task-vars.yml
---
- name: Task变量示例
  hosts: webservers
  become: true
  tasks:
    - name: 设置Task变量
      set_fact:
        task_http_port: 80
        task_https_port: 443
    
    - name: 显示Task变量
      debug:
        msg: "Task HTTP端口: {{ task_http_port }}"
    
    - name: 在另一个Task中使用Task变量
      debug:
        msg: "Task HTTPS端口: {{ task_https_port }}"
```

### 6.3.4 主机变量

```yaml
# host-vars.yml
---
- name: 主机变量示例
  hosts: webservers
  become: true
  tasks:
    - name: 显示主机变量
      debug:
        msg: "主机HTTP端口: {{ http_port }}"
    
    - name: 显示主机变量
      debug:
        msg: "主机HTTPS端口: {{ https_port }}"
```

### 6.3.5 组变量

```yaml
# group-vars.yml
---
- name: 组变量示例
  hosts: webservers
  become: true
  tasks:
    - name: 显示组变量
      debug:
        msg: "组HTTP端口: {{ http_port }}"
    
    - name: 显示组变量
      debug:
        msg: "组HTTPS端口: {{ https_port }}"
```

---

## 6.4 变量使用

### 6.4.1 字符串变量

```yaml
# string-vars.yml
---
- name: 字符串变量示例
  hosts: webservers
  become: true
  vars:
    string_var: "Hello, World!"
    string_var_multiline: |
      This is a
      multiline
      string
    string_var_folded: >
      This is a
      folded
      string
  tasks:
    - name: 显示字符串变量
      debug:
        msg: "{{ string_var }}"
    
    - name: 显示多行字符串变量
      debug:
        msg: "{{ string_var_multiline }}"
    
    - name: 显示折叠字符串变量
      debug:
        msg: "{{ string_var_folded }}"
```

### 6.4.2 数字变量

```yaml
# number-vars.yml
---
- name: 数字变量示例
  hosts: webservers
  become: true
  vars:
    integer_var: 42
    float_var: 3.14
    negative_var: -10
  tasks:
    - name: 显示整数变量
      debug:
        msg: "整数: {{ integer_var }}"
    
    - name: 显示浮点数变量
      debug:
        msg: "浮点数: {{ float_var }}"
    
    - name: 显示负数变量
      debug:
        msg: "负数: {{ negative_var }}"
    
    - name: 数字运算
      debug:
        msg: "运算结果: {{ integer_var + float_var }}"
```

### 6.4.3 布尔变量

```yaml
# boolean-vars.yml
---
- name: 布尔变量示例
  hosts: webservers
  become: true
  vars:
    true_var: true
    false_var: false
    yes_var: yes
    no_var: no
  tasks:
    - name: 显示布尔变量
      debug:
        msg: "true_var: {{ true_var }}"
    
    - name: 显示布尔变量
      debug:
        msg: "false_var: {{ false_var }}"
    
    - name: 显示布尔变量
      debug:
        msg: "yes_var: {{ yes_var }}"
    
    - name: 显示布尔变量
      debug:
        msg: "no_var: {{ no_var }}"
    
    - name: 布尔运算
      debug:
        msg: "运算结果: {{ true_var and false_var }}"
```

### 6.4.4 列表变量

```yaml
# list-vars.yml
---
- name: 列表变量示例
  hosts: webservers
  become: true
  vars:
    list_var:
      - item1
      - item2
      - item3
    list_var_multiline:
      - item1
      - item2
      - item3
    list_var_flow: [item1, item2, item3]
  tasks:
    - name: 显示列表变量
      debug:
        msg: "{{ list_var }}"
    
    - name: 显示列表变量
      debug:
        msg: "{{ list_var_multiline }}"
    
    - name: 显示列表变量
      debug:
        msg: "{{ list_var_flow }}"
    
    - name: 访问列表元素
      debug:
        msg: "第一个元素: {{ list_var[0] }}"
    
    - name: 访问列表元素
      debug:
        msg: "最后一个元素: {{ list_var[-1] }}"
    
    - name: 列表长度
      debug:
        msg: "列表长度: {{ list_var | length }}"
```

### 6.4.5 字典变量

```yaml
# dict-vars.yml
---
- name: 字典变量示例
  hosts: webservers
  become: true
  vars:
    dict_var:
      key1: value1
      key2: value2
      key3: value3
    dict_var_multiline:
      key1: value1
      key2: value2
      key3: value3
    dict_var_flow: {key1: value1, key2: value2, key3: value3}
  tasks:
    - name: 显示字典变量
      debug:
        msg: "{{ dict_var }}"
    
    - name: 显示字典变量
      debug:
        msg: "{{ dict_var_multiline }}"
    
    - name: 显示字典变量
      debug:
        msg: "{{ dict_var_flow }}"
    
    - name: 访问字典元素
      debug:
        msg: "key1的值: {{ dict_var.key1 }}"
    
    - name: 访问字典元素
      debug:
        msg: "key2的值: {{ dict_var['key2'] }}"
    
    - name: 字典键列表
      debug:
        msg: "字典键: {{ dict_var.keys() | list }}"
    
    - name: 字典值列表
      debug:
        msg: "字典值: {{ dict_var.values() | list }}"
```

---

## 6.5 变量过滤

### 6.5.1 字符串过滤

```yaml
# string-filters.yml
---
- name: 字符串过滤示例
  hosts: webservers
  become: true
  vars:
    string_var: "Hello, World!"
  tasks:
    - name: 转换为大写
      debug:
        msg: "{{ string_var | upper }}"
    
    - name: 转换为小写
      debug:
        msg: "{{ string_var | lower }}"
    
    - name: 首字母大写
      debug:
        msg: "{{ string_var | capitalize }}"
    
    - name: 替换字符串
      debug:
        msg: "{{ string_var | replace('World', 'Ansible') }}"
    
    - name: 删除空格
      debug:
        msg: "{{ string_var | replace(' ', '') }}"
    
    - name: 字符串长度
      debug:
        msg: "{{ string_var | length }}"
    
    - name: 字符串分割
      debug:
        msg: "{{ string_var | split(',') }}"
    
    - name: 字符串连接
      debug:
        msg: "{{ ['Hello', 'World'] | join(', ') }}"
```

### 6.5.2 数字过滤

```yaml
# number-filters.yml
---
- name: 数字过滤示例
  hosts: webservers
  become: true
  vars:
    number_var: 3.14159
  tasks:
    - name: 四舍五入
      debug:
        msg: "{{ number_var | round }}"
    
    - name: 向上取整
      debug:
        msg: "{{ number_var | ceil }}"
    
    - name: 向下取整
      debug:
        msg: "{{ number_var | floor }}"
    
    - name: 绝对值
      debug:
        msg: "{{ -10 | abs }}"
    
    - name: 随机数
      debug:
        msg: "{{ 100 | random }}"
    
    - name: 幂运算
      debug:
        msg: "{{ 2 | pow(10) }}"
    
    - name: 对数运算
      debug:
        msg: "{{ 1024 | log2 }}"
```

### 6.5.3 列表过滤

```yaml
# list-filters.yml
---
- name: 列表过滤示例
  hosts: webservers
  become: true
  vars:
    list_var:
      - item1
      - item2
      - item3
      - item4
      - item5
  tasks:
    - name: 列表长度
      debug:
        msg: "{{ list_var | length }}"
    
    - name: 列表第一个元素
      debug:
        msg: "{{ list_var | first }}"
    
    - name: 列表最后一个元素
      debug:
        msg: "{{ list_var | last }}"
    
    - name: 列表排序
      debug:
        msg: "{{ list_var | sort }}"
    
    - name: 列表去重
      debug:
        msg: "{{ ['item1', 'item2', 'item1'] | unique }}"
    
    - name: 列表切片
      debug:
        msg: "{{ list_var | list }}"
    
    - name: 列表求和
      debug:
        msg: "{{ [1, 2, 3, 4, 5] | sum }}"
    
    - name: 列表最大值
      debug:
        msg: "{{ [1, 2, 3, 4, 5] | max }}"
    
    - name: 列表最小值
      debug:
        msg: "{{ [1, 2, 3, 4, 5] | min }}"
```

### 6.5.4 字典过滤

```yaml
# dict-filters.yml
---
- name: 字典过滤示例
  hosts: webservers
  become: true
  vars:
    dict_var:
      key1: value1
      key2: value2
      key3: value3
  tasks:
    - name: 字典键列表
      debug:
        msg: "{{ dict_var.keys() | list }}"
    
    - name: 字典值列表
      debug:
        msg: "{{ dict_var.values() | list }}"
    
    - name: 字典项列表
      debug:
        msg: "{{ dict_var.items() | list }}"
    
    - name: 字典合并
      debug:
        msg: "{{ dict_var | combine({'key4': 'value4'}) }}"
```

---

## 6.6 实战：管理变量

### 6.6.1 创建变量文件

```bash
# 创建变量文件

# 创建vars目录
mkdir -p vars

# 创建变量文件
cat > vars/common.yml << 'EOF'
---
http_port: 80
https_port: 443
document_root: /var/www/html
server_name: localhost
ssl_enabled: false
ssl_cert_path: /etc/ssl/certs/nginx.crt
ssl_key_path: /etc/ssl/private/nginx.key
EOF

# 创建Nginx变量文件
cat > vars/nginx.yml << 'EOF'
---
nginx_config:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65

nginx_packages:
  - nginx
  - nginx-extras
  - python3-certbot-nginx
EOF

# 验证变量文件
cat vars/common.yml
cat vars/nginx.yml
```

### 6.6.2 使用变量文件

```bash
# 创建使用变量文件的Playbook

# 创建Playbook文件
cat > playbook-vars-files.yml << 'EOF'
---
- name: 使用变量文件的Playbook示例
  hosts: webservers
  become: true
  vars_files:
    - vars/common.yml
    - vars/nginx.yml
  tasks:
    - name: 显示变量
      debug:
        msg:
          - "HTTP端口: {{ http_port }}"
          - "HTTPS端口: {{ https_port }}"
          - "文档根目录: {{ document_root }}"
          - "服务器名称: {{ server_name }}"
          - "SSL启用: {{ ssl_enabled }}"
          - "SSL证书路径: {{ ssl_cert_path }}"
          - "SSL密钥路径: {{ ssl_key_path }}"
          - "工作进程数: {{ nginx_config.worker_processes }}"
          - "工作连接数: {{ nginx_config.worker_connections }}"
          - "保持连接超时: {{ nginx_config.keepalive_timeout }}"
          - "Nginx包: {{ nginx_packages }}"
EOF

# 运行Playbook
ansible-playbook playbook-vars-files.yml

# 预期输出：
# PLAY [使用变量文件的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [显示变量] *********************************************************
# ok: [localhost] => {
#     "msg": [
#         "HTTP端口: 80",
#         "HTTPS端口: 443",
#         "文档根目录: /var/www/html",
#         "服务器名称: localhost",
#         "SSL启用: false",
#         "SSL证书路径: /etc/ssl/certs/nginx.crt",
#         "SSL密钥路径: /etc/ssl/private/nginx.key",
#         "工作进程数: auto",
#         "工作连接数: 1024",
#         "保持连接超时: 65",
#         "Nginx包: [\"nginx\", \"nginx-extras\", \"python3-certbot-nginx\"]"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=2    changed=0    unreachable=0    failed=0
```

### 6.6.3 使用命令行变量

```bash
# 使用命令行变量

# 创建Playbook文件
cat > playbook-cli-vars.yml << 'EOF'
---
- name: 使用命令行变量的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 显示命令行变量
      debug:
        msg:
          - "HTTP端口: {{ http_port }}"
          - "HTTPS端口: {{ https_port }}"
          - "文档根目录: {{ document_root }}"
          - "服务器名称: {{ server_name }}"
          - "SSL启用: {{ ssl_enabled }}"
EOF

# 运行Playbook（使用命令行变量）
ansible-playbook playbook-cli-vars.yml -e "http_port=8080" -e "https_port=8443" -e "document_root=/var/www/myapp" -e "server_name=myapp.example.com" -e "ssl_enabled=true"

# 预期输出：
# PLAY [使用命令行变量的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [显示命令行变量] *************************************************
# ok: [localhost] => {
#     "msg": [
#         "HTTP端口: 8080",
#         "HTTPS端口: 8443",
#         "文档根目录: /var/www/myapp",
#         "服务器名称: myapp.example.com",
#         "SSL启用: true"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=2    changed=0    unreachable=0    failed=0
```

---

## 本章小结

- 变量是Ansible中用于存储和传递数据的机制
- 变量类型包括字符串、数字、布尔值、列表、字典
- 变量定义包括Playbook中定义、Inventory中定义、角色中定义、命令行定义、外部文件定义
- 变量作用域包括全局变量、Play变量、Task变量、主机变量、组变量
- 变量优先级从高到低：命令行变量、Play变量、主机变量、组变量、角色变量、Facts、魔法变量
- 变量过滤包括字符串过滤、数字过滤、列表过滤、字典过滤
- 可以使用vars、vars_files、vars_prompt定义变量
- 可以使用host_vars和group_vars定义主机变量和组变量
- 可以使用-e/--extra-vars定义命令行变量
- 可以使用Jinja2过滤器处理变量

---

**下一章：模板和Jinja2**
