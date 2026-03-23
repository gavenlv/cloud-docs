# Ansible常见错误处理

## 10.1 连接错误

### 10.1.1 SSH连接错误

```
SSH连接错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  SSH连接错误排查                                    │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Connection refused
├── 错误信息：SSH connection refused
├── 常见原因：SSH服务未启动、SSH端口错误、防火墙阻止
├── 解决方案：检查SSH服务、检查SSH端口、检查防火墙规则
└── 验证方法：ssh user@host

错误2：Authentication failed
├── 错误信息：SSH authentication failed
├── 常见原因：密码错误、密钥错误、用户不存在
├── 解决方案：检查密码、检查密钥、检查用户
└── 验证方法：ssh user@host

错误3：Host key verification failed
├── 错误信息：SSH host key verification failed
├── 常见原因：主机密钥变更、主机密钥未知
├── 解决方案：清除已知主机、禁用主机密钥检查
└── 验证方法：ssh-keygen -R host

错误4：Timeout
├── 错误信息：SSH connection timeout
├── 常见原因：网络不通、主机不可达、防火墙阻止
├── 解决方案：检查网络连接、检查主机可达性、检查防火墙规则
└── 验证方法：ping host

2. 错误排查步骤

步骤1：检查SSH服务
systemctl status sshd
systemctl start sshd

步骤2：检查SSH端口
netstat -tlnp | grep ssh
ss -tlnp | grep ssh

步骤3：检查防火墙
iptables -L -n
firewall-cmd --list-ports

步骤4：测试SSH连接
ssh user@host
ssh -p port user@host
ssh -i keyfile user@host

步骤5：检查Ansible配置
ansible.cfg配置
Inventory配置
主机变量配置

3. 错误处理方法

方法1：增加连接超时时间
[ssh_connection]
ssh_args = -o ConnectTimeout=60
timeout = 60

方法2：增加重试次数
[defaults]
retries = 3

方法3：禁用主机密钥检查
[defaults]
host_key_checking = False

方法4：使用SSH代理
[ssh_connection]
ssh_args = -o ProxyCommand="ssh -W %h:%p jumpuser@jumphost"
```

### 10.1.2 认证错误

```
认证错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  认证错误排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Permission denied
├── 错误信息：Permission denied (publickey,password)
├── 常见原因：密钥权限错误、密码错误、用户权限不足
├── 解决方案：检查密钥权限、检查密码、检查用户权限
└── 验证方法：ls -l ~/.ssh/id_rsa

错误2：Invalid user
├── 错误信息：Invalid user
├── 常见原因：用户不存在、用户名错误
├── 解决方案：检查用户是否存在、检查用户名
└── 验证方法：id user

错误3：Access denied
├── 错误信息：Access denied
├── 常见原因：sudo权限不足、密码错误、策略限制
├── 解决方案：检查sudo权限、检查sudo密码、检查sudo策略
└── 验证方法：sudo -l

2. 错误排查步骤

步骤1：检查用户是否存在
id user
getent passwd user

步骤2：检查用户权限
groups user
id -G user

步骤3：检查sudo权限
sudo -l
sudo -v

步骤4：检查SSH密钥权限
ls -l ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

步骤5：测试SSH连接
ssh user@host
ssh -i keyfile user@host

3. 错误处理方法

方法1：使用密码认证
ansible_ssh_user: user
ansible_ssh_pass: password
ansible_become_pass: password

方法2：使用密钥认证
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_ssh_user: user

方法3：配置sudo权限
ansible_become: true
ansible_become_method: sudo
ansible_become_user: root
ansible_become_pass: password

方法4：禁用密码认证
ansible_ssh_common_args: '-o PreferredAuthentications=publickey'
```

---

## 10.2 执行错误

### 10.2.1 模块执行错误

```
模块执行错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  模块执行错误排查                                    │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Module not found
├── 错误信息：Module not found
├── 常见原因：模块未安装、模块路径错误、模块名称错误
├── 解决方案：安装模块、检查模块路径、检查模块名称
└── 验证方法：ansible-doc -l

错误2：Module failed
├── 错误信息：Module failed with exception
├── 常见原因：模块参数错误、模块依赖错误、模块版本不兼容
├── 解决方案：检查模块参数、检查模块依赖、检查模块版本
└── 验证方法：ansible-doc module_name

错误3：Invalid options
├── 错误信息：Invalid options for module
├── 常见原因：参数名称错误、参数值错误、参数类型错误
├── 解决方案：检查参数名称、检查参数值、检查参数类型
└── 验证方法：ansible-doc module_name

2. 错误排查步骤

步骤1：检查模块是否存在
ansible-doc -l | grep module_name
ansible-doc module_name

步骤2：检查模块参数
ansible-doc module_name
ansible-doc -s module_name

步骤3：检查模块版本
ansible --version
pip show ansible

步骤4：测试模块执行
ansible host -m module_name -a "param=value"
ansible host -m module_name -a "param=value" -vvv

步骤5：查看模块日志
tail -f /var/log/ansible.log
journalctl -u ansible

3. 错误处理方法

方法1：增加详细输出
ansible-playbook playbook.yml -vvv
ansible-playbook playbook.yml -vvvv

方法2：忽略错误
ignore_errors: yes
failed_when: false

方法3：重试执行
retries: 3
delay: 5
until: result is succeeded

方法4：使用备用模块
- name: 尝试使用apt模块
  apt:
    name: nginx
    state: present
  ignore_errors: yes

- name: 尝试使用yum模块
  yum:
    name: nginx
    state: present
  when: ansible_failed is defined
```

### 10.2.2 权限错误

```
权限错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  权限错误排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Permission denied
├── 错误信息：Permission denied
├── 常见原因：文件权限不足、目录权限不足、用户权限不足
├── 解决方案：修改文件权限、修改目录权限、提升用户权限
└── 验证方法：ls -l file

错误2：Operation not permitted
├── 错误信息：Operation not permitted
├── 常见原因：需要root权限、需要sudo权限、SELinux限制
├── 解决方案：使用sudo、配置sudo、禁用SELinux
└── 验证方法：sudo command

错误3：Access denied
├── 错误信息：Access denied
├── 常见原因：文件访问权限、目录访问权限、系统限制
├── 解决方案：修改访问权限、修改系统限制、使用sudo
└── 验证方法：getfacl file

2. 错误排查步骤

步骤1：检查文件权限
ls -l file
stat file

步骤2：检查目录权限
ls -ld directory
stat directory

步骤3：检查用户权限
id user
groups user

步骤4：检查sudo权限
sudo -l
sudo -v

步骤5：测试命令执行
sudo command
command

3. 错误处理方法

方法1：使用become
become: true
become_method: sudo
become_user: root
become_ask_pass: false

方法2：修改文件权限
file:
  path: /path/to/file
  mode: '0644'
  owner: user
  group: group

方法3：修改目录权限
file:
  path: /path/to/directory
  mode: '0755'
  owner: user
  group: group
  recurse: yes

方法4：使用sudo执行命令
command: sudo command
become: true
become_method: sudo
```

---

## 10.3 变量错误

### 10.3.1 变量未定义

```
变量未定义错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  变量未定义错误排查                                  │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Undefined variable
├── 错误信息：'variable' is undefined
├── 常见原因：变量未定义、变量作用域错误、变量名称错误
├── 解决方案：定义变量、检查变量作用域、检查变量名称
└── 验证方法：ansible-playbook playbook.yml -e "variable=value"

错误2：Variable not found
├── 错误信息：Variable 'variable' not found
├── 常见原因：变量文件不存在、变量文件路径错误、变量文件格式错误
├── 解决方案：创建变量文件、检查变量文件路径、检查变量文件格式
└── 验证方法：cat vars_file.yml

错误3：Accessing undefined variable
├── 错误信息：Error while accessing variable 'variable'
├── 常见原因：变量类型错误、变量值错误、变量引用错误
├── 解决方案：检查变量类型、检查变量值、检查变量引用
└── 验证方法：debug: var=variable

2. 错误排查步骤

步骤1：检查变量是否定义
debug:
  var: variable

步骤2：检查变量作用域
debug:
  var: hostvars[inventory_hostname].variable

步骤3：检查变量文件
cat vars_file.yml
ansible-playbook playbook.yml --list-hosts

步骤4：检查变量优先级
ansible-playbook playbook.yml -e "variable=value"
ansible-inventory --host hostname

步骤5：测试变量使用
debug:
  msg: "{{ variable }}"
```

### 10.3.2 变量类型错误

```
变量类型错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  变量类型错误排查                                  │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Type mismatch
├── 错误信息：Type mismatch for variable 'variable'
├── 常见原因：变量类型不匹配、变量值类型错误、变量引用错误
├── 解决方案：转换变量类型、检查变量值、检查变量引用
└── 验证方法：debug: var=variable | type_debug

错误2：Invalid type
├── 错误信息：Invalid type for variable 'variable'
├── 常见原因：变量类型不支持、变量值类型错误、变量转换错误
├── 解决方案：使用支持的类型、检查变量值、检查变量转换
└── 验证方法：debug: var=variable | type_debug

错误3：String expected
├── 错误信息：String expected for variable 'variable'
├── 常见原因：变量不是字符串、变量值类型错误、变量引用错误
├── 解决方案：转换为字符串、检查变量值、检查变量引用
└── 验证方法：debug: var=variable | string

2. 错误排查步骤

步骤1：检查变量类型
debug:
  var: variable | type_debug

步骤2：检查变量值
debug:
  var: variable

步骤3：转换变量类型
debug:
  var: variable | int
debug:
  var: variable | string
debug:
  var: variable | bool

步骤4：测试变量使用
debug:
  msg: "{{ variable }}"
debug:
  msg: "{{ variable | int }}"
debug:
  msg: "{{ variable | string }}"

步骤5：验证变量转换
debug:
  var: variable | default('default_value')
```

---

## 10.4 模板错误

### 10.4.1 模板语法错误

```
模板语法错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  模板语法错误排查                                  │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Template syntax error
├── 错误信息：Template syntax error
├── 常见原因：Jinja2语法错误、变量引用错误、过滤器错误
├── 解决方案：修复Jinja2语法、检查变量引用、检查过滤器
└── 验证方法：ansible-playbook playbook.yml --syntax-check

错误2：Undefined variable in template
├── 错误信息：Undefined variable 'variable' in template
├── 常见原因：变量未定义、变量作用域错误、变量名称错误
├── 解决方案：定义变量、检查变量作用域、检查变量名称
└── 验证方法：ansible-playbook playbook.yml -e "variable=value"

错误3：Filter not found
├── 错误信息：Filter 'filter' not found
├── 常见原因：过滤器不存在、过滤器名称错误、过滤器未导入
├── 解决方案：使用正确的过滤器、检查过滤器名称、导入过滤器
└── 验证方法：ansible-doc -t filter filter_name

2. 错误排查步骤

步骤1：检查模板语法
ansible-playbook playbook.yml --syntax-check
j2lint template.j2

步骤2：检查变量引用
debug:
  var: variable

步骤3：检查过滤器
ansible-doc -t filter filter_name
debug:
  var: variable | filter

步骤4：测试模板渲染
ansible host -m template -a "src=template.j2 dest=/tmp/output"

步骤5：查看模板错误
ansible-playbook playbook.yml -vvv
```

### 10.4.2 模板变量错误

```
模板变量错误排查：

┌─────────────────────────────────────────────────────────────────┐
│  模板变量错误排查                                  │
└─────────────────────────────────────────────────────────────────┘

1. 常见错误信息

错误1：Variable not defined in template
├── 错误信息：Variable 'variable' not defined in template
├── 常见原因：变量未定义、变量作用域错误、变量名称错误
├── 解决方案：定义变量、检查变量作用域、检查变量名称
└── 验证方法：ansible-playbook playbook.yml -e "variable=value"

错误2：Variable type mismatch in template
├── 错误信息：Variable type mismatch in template
├── 常见原因：变量类型不匹配、变量值类型错误、变量引用错误
├── 解决方案：转换变量类型、检查变量值、检查变量引用
└── 验证方法：debug: var=variable | type_debug

错误3：Variable access error in template
├── 错误信息：Variable access error in template
├── 常见原因：变量访问错误、变量嵌套错误、变量属性错误
├── 解决方案：检查变量访问、检查变量嵌套、检查变量属性
└── 验证方法：debug: var=variable

2. 错误排查步骤

步骤1：检查变量定义
debug:
  var: variable

步骤2：检查变量类型
debug:
  var: variable | type_debug

步骤3：检查变量访问
debug:
  var: variable.key
debug:
  var: variable['key']

步骤4：测试模板渲染
ansible host -m template -a "src=template.j2 dest=/tmp/output"

步骤5：查看模板错误
ansible-playbook playbook.yml -vvv
```

---

## 10.5 调试技巧

### 10.5.1 使用调试模块

```yaml
# debug-module.yml
---
- name: 使用调试模块示例
  hosts: webservers
  become: true
  tasks:
    - name: 显示变量
      debug:
        var: variable
    
    - name: 显示消息
      debug:
        msg: "Hello, World!"
    
    - name: 显示多个变量
      debug:
        msg:
          - "变量1: {{ variable1 }}"
          - "变量2: {{ variable2 }}"
          - "变量3: {{ variable3 }}"
    
    - name: 显示字典
      debug:
        var: dictionary
    
    - name: 显示列表
      debug:
        var: list
    
    - name: 显示Facts
      debug:
        var: ansible_facts
    
    - name: 显示主机变量
      debug:
        var: hostvars[inventory_hostname]
    
    - name: 显示组变量
      debug:
        var: groups
    
    - name: 显示Inventory主机名
      debug:
        var: inventory_hostname
    
    - name: 显示Inventory主机名简称
      debug:
        var: inventory_hostname_short
```

### 10.5.2 使用详细输出

```bash
# 使用详细输出

# 基本详细输出
ansible-playbook playbook.yml -v

# 更详细的输出
ansible-playbook playbook.yml -vv

# 非常详细的输出
ansible-playbook playbook.yml -vvv

# 最详细的输出
ansible-playbook playbook.yml -vvvv

# 查看连接信息
ansible-playbook playbook.yml -vvv | grep -i "ssh"

# 查看模块执行信息
ansible-playbook playbook.yml -vvv | grep -i "module"

# 查看变量信息
ansible-playbook playbook.yml -vvv | grep -i "variable"
```

### 10.5.3 使用检查模式

```bash
# 使用检查模式

# 基本检查模式
ansible-playbook playbook.yml --check

# 检查模式 + 详细输出
ansible-playbook playbook.yml --check -v

# 检查模式 + 差异输出
ansible-playbook playbook.yml --check --diff

# 检查模式 + 跳过标签
ansible-playbook playbook.yml --check --skip-tags install
```

### 10.5.4 使用单步执行

```bash
# 使用单步执行

# 单步执行模式
ansible-playbook playbook.yml --step

# 单步执行 + 详细输出
ansible-playbook playbook.yml --step -v

# 单步执行 + 检查模式
ansible-playbook playbook.yml --step --check
```

---

## 10.6 实战：处理错误

### 10.6.1 处理连接错误

```bash
# 创建处理连接错误的Playbook

# 创建Playbook文件
cat > playbook-connection-errors.yml << 'EOF'
---
- name: 处理连接错误的Playbook示例
  hosts: webservers
  become: true
  vars:
    ansible_ssh_timeout: 60
    ansible_ssh_retries: 3
  tasks:
    - name: 测试SSH连接
      wait_for:
        host: "{{ ansible_host }}"
        port: "{{ ansible_port | default(22) }}"
        timeout: "{{ ansible_ssh_timeout }}"
      delegate_to: localhost
      register: ssh_connection
    
    - name: 显示SSH连接结果
      debug:
        msg: "SSH连接结果: {{ ssh_connection }}"
    
    - name: 测试SSH认证
      command: ssh -o ConnectTimeout={{ ansible_ssh_timeout }} -o StrictHostKeyChecking=no {{ ansible_user }}@{{ ansible_host }} echo "SSH认证成功"
      register: ssh_auth
      changed_when: false
      failed_when: false
    
    - name: 显示SSH认证结果
      debug:
        msg: "SSH认证结果: {{ ssh_auth }}"
    
    - name: 安装Nginx（带重试）
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
      retries: 3
      delay: 5
      until: nginx_install is succeeded
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
EOF

# 运行Playbook
ansible-playbook playbook-connection-errors.yml

# 预期输出：
# PLAY [处理连接错误的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [测试SSH连接] *****************************************************
# ok: [localhost]
# TASK [显示SSH连接结果] *********************************************
# ok: [localhost] => {
#     "msg": "SSH连接结果: {\"changed\": false, \"elapsed\": 0, \"failed\": false, \"match_groupdict\": {}, \"msg\": \"All items completed\", \"path\": null, \"port\": 22, \"search_regex\": null, \"state\": \"started\"}"
# }
# TASK [测试SSH认证] *****************************************************
# ok: [localhost]
# TASK [显示SSH认证结果] *********************************************
# ok: [localhost] => {
#     "msg": "SSH认证结果: {\"changed\": false, \"cmd\": [\"ssh\", \"-o\", \"ConnectTimeout=60\", \"-o\", \"StrictHostKeyChecking=no\", \"ansible@localhost\", \"echo\", \"SSH认证成功\"], \"delta\": \"0:00:00.123456\", \"end\": \"2024-01-15 10:00:00.123456\", \"failed\": false, \"rc\": 0, \"start\": \"2024-01-15 10:00:00.000000\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"SSH认证成功\", \"stdout_lines\": [\"SSH认证成功\"]}"
# }
# TASK [安装Nginx（带重试）] *******************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\\nNeed to get 0 B/1,234 kB of archives.\\nAfter this operation, 5,678 kB of additional disk space will be used.\\nSelecting previously unselected package nginx.\\n(Reading database ... 123456 files and directories currently installed.)\\nPreparing to unpack .../nginx_1.18.0-0ubuntu1_amd64.deb ...\\nUnpacking nginx (1.18.0-0ubuntu1) ...\\nSetting up nginx (1.18.0-0ubuntu1) ...\\nProcessing triggers for ufw (0.36.1-0ubuntu0.20.04.1) ...\\nProcessing triggers for systemd (245.4-4ubuntu3.13) ...\\nProcessing triggers for man-db (2.9.1-1) ...\\n\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"Need to get 0 B/1,234 kB of archives.\", \"After this operation, 5,678 kB of additional disk space will be used.\", \"Selecting previously unselected package nginx.\", \"(Reading database ... 123456 files and directories currently installed.)\", \"Preparing to unpack .../nginx_1.18.0-0ubuntu1_amd64.deb ...\", \"Unpacking nginx (1.18.0-0ubuntu1) ...\", \"Setting up nginx (1.18.0-0ubuntu1) ...\", \"Processing triggers for ufw (0.36.1-0ubuntu0.20.04.1) ...\", \"Processing triggers for systemd (245.4-4ubuntu3.13) ...\", \"Processing triggers for man-db (2.9.1-1) ...\"]}"
# }
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=1    unreachable=0    failed=0
```

### 10.6.2 处理执行错误

```bash
# 创建处理执行错误的Playbook

# 创建Playbook文件
cat > playbook-execution-errors.yml << 'EOF'
---
- name: 处理执行错误的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（忽略错误）
      apt:
        name: nginx
        state: present
        update_cache: yes
      ignore_errors: yes
      register: nginx_install
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
    
    - name: 安装Nginx（带错误处理）
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
      failed_when: nginx_install.rc != 0 and 'nginx' not in nginx_install.stdout
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
    
    - name: 配置Nginx（带验证）
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      register: nginx_config
      failed_when: nginx_config.rc != 0
    
    - name: 显示配置结果
      debug:
        msg: "Nginx配置结果: {{ nginx_config }}"
    
    - name: 启动Nginx服务（带等待）
      service:
        name: nginx
        state: started
        enabled: yes
      register: nginx_service
      until: nginx_service.status.ActiveState == "active"
      retries: 3
      delay: 5
    
    - name: 显示服务结果
      debug:
        msg: "Nginx服务结果: {{ nginx_service }}"
EOF

# 运行Playbook
ansible-playbook playbook-execution-errors.yml

# 预期输出：
# PLAY [处理执行错误的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx（忽略错误）] *******************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\"]}"
# }
# TASK [安装Nginx（带错误处理）] *****************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\"]}"
# }
# TASK [配置Nginx（带验证）] *********************************************
# changed: [localhost]
# TASK [显示配置结果) *************************************************
# ok: [localhost] => {
#     "msg": "Nginx配置结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\\nnginx: configuration file /etc/nginx/nginx.conf test is successful\\n\", \"stdout_lines\": [\"nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\", \"nginx: configuration file /etc/nginx/nginx.conf test is successful\"]}"
# }
# TASK [启动Nginx服务（带等待）] *****************************************
# changed: [localhost]
# TASK [显示服务结果) *************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\", \"stdout_lines\": [], \"status\": {\"ActiveEnterTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ActiveEnterTimestampMonotonic\": \"123456789\", \"ActiveState\": \"active\", \"After\": \"network.target system.slice\", \"AllowIsolate\": \"no\", \"AssertResult\": \"yes\", \"AssertTimestamp\": \"2024-01-15 10:00:00 UTC\", \"AssertTimestampMonotonic\": \"123456789\", \"Before\": \"shutdown.target\", \"BlockIOAccounting\": \"no\", \"BlockIOWeight\": \"[not set]\", \"CPUAccounting\": \"yes\", \"CPUQuotaPerSecUSec\": \"infinity\", \"CPUWeight\": \"[not set]\", \"CapabilityBoundingSet\": \"CAP_CHOWN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_FOWNER CAP_FSETID CAP_KILL CAP_MKNOD CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETFCAP CAP_SETPCAP CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_NICE CAP_SYS_PTRACE CAP_SYS_RAWIO CAP_SYS_TIME CAP_SYS_TTY_CONFIG CAP_WAKE_ALARM\", \"CollectMode\": \"inactive\", \"ConditionResult\": \"yes\", \"ConditionTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ConditionTimestampMonotonic\": \"123456789\", \"Conflicts\": \"shutdown.target\", \"ControlGroup\": \"/system.slice/nginx.service\", \"ControlPID\": \"12345\", \"DefaultDependencies\": \"yes\", \"Delegate\": \"no\", \"Description\": \"A high performance web server and a reverse proxy server\", \"DevicePolicy\": \"auto\", \"Documentation\": \"man:nginx(8)\", \"Dynamic\": \"no\", \"ExecMainCode\": \"0\", \"ExecMainExitTimestampMonotonic\": \"0\", \"ExecMainPID\": \"12345\", \"ExecMainStartTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ExecMainStartTimestampMonotonic\": \"123456789\", \"ExecMainStatus\": \"0\", \"ExecReload\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s reload ; ... }\", \"ExecReloadEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s reload ; ... }\", \"ExecStart\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -g daemon on; master_process on; ; ... }\", \"ExecStartEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -g daemon on; master_process on; ; ... }\", \"ExecStartPost\": \"{ path=/bin/kill ; argv[]=/bin/kill -s HUP $MAINPID ; ... }\", \"ExecStartPostEx\": \"{ path=/bin/kill ; argv[]=/bin/kill -s HUP $MAINPID ; ... }\", \"ExecStop\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s quit ; ... }\", \"ExecStopEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s quit ; ... }\", \"ExitCode\": \"0\", \"ExitCodeStatus\": \"0\", \"ExitStatus\": \"0\", \"FailureAction\": \"none\", \"FileDescriptorStoreMax\": \"0\", \"FragmentPath\": \"/etc/systemd/system/nginx.service\", \"GuessMainPID\": \"yes\", \"IOSchedulingClass\": \"[not set]\", \"IOSchedulingPriority\": \"0\", \"Id\": \"nginx.service\", \"IgnoreOnIsolate\": \"no\", \"IgnoreOnSnapshot\": \"no\", \"IgnoreSIGPIPE\": \"yes\", \"InactiveEnterTimestampMonotonic\": \"0\", \"InactiveExitTimestampMonotonic\": \"0\", \"InvocationID\": \"1234567890abcdef\", \"JobRunningTimeoutUSec\": \"infinity\", \"JobTimeoutAction\": \"none\", \"JobTimeoutUSec\": \"infinity\", \"KillMode\": \"control-group\", \"KillSignal\": \"SIGTERM\", \"LimitCPU\": \"infinity\", \"LimitCPUQuotaPerSecUSec\": \"infinity\", \"LimitData\": \"infinity\", \"LimitFSIZE\": \"infinity\", \"LimitLOCKS\": \"infinity\", \"LimitMEMLOCK\": \"infinity\", \"LimitMSGQUEUE\": \"819200\", \"LimitNICE\": \"0\", \"LimitNOFILE\": \"524288\", \"LimitNPROC\": \"123456\", \"LimitRSS\": \"infinity\", \"LimitRTPRIO\": \"infinity\", \"LimitRTTIME\": \"infinity\", \"LimitSIGPENDING\": \"123456\", \"LimitSTACK\": \"infinity\", \"LoadState\": \"loaded\", \"MainPID\": \"12345\", \"MemoryAccounting\": \"yes\", \"MemoryCurrent\": \"12345678\", \"MemoryDenyWrite\": \"no\", \"MemoryLimit\": \"infinity\", \"MemoryLow\": \"0\", \"MemoryMax\": \"infinity\", \"MemorySwapMax\": \"infinity\", \"MountFlags\": \"0\", \"NFileDescriptorStore\": \"0\", \"NRestarts\": \"0\", \"Names\": \"nginx.service\", \"NeedDaemonReload\": \"no\", \"Nice\": \"0\", \"NoNewPrivileges\": \"no\", \"NonBlocking\": \"no\", \"NotifyAccess\": \"main\", \"OOMPolicy\": \"stop\", \"OOMScoreAdjust\": \"0\", \"OnFailure\": \"no\", \"OnFailureJobMode\": \"no\", \"OnSuccess\": \"no\", \"OnSuccessJobMode\": \"no\", \"Perpetual\": \"no\", \"PIDFile\": \"/run/nginx.pid\", \"PermissionsStartOnly\": \"no\", \"PrivateDevices\": \"no\", \"PrivateMounts\": \"no\", \"PrivateNetwork\": \"no\", \"PrivateTmp\": \"no\", \"ProtectControlGroups\": \"no\", \"ProtectHome\": \"no\", \"ProtectKernelModules\": \"no\", \"ProtectKernelTunables\": \"no\", \"ProtectSystem\": \"no\", \"ProtectSystemStrict\": \"no\", \"RefuseManualStart\": \"no\", \"RefuseManualStop\": \"no\", \"RemainAfterExit\": \"no\", \"RemoveIPC\": \"no\", \"Requires\": \"network.target\", \"RequiresMountsFor\": \"\", \"Restart\": \"no\", \"RestartForceExitStatus\": \"0\", \"RestartMode\": \"no\", \"RestartUSec\": \"100ms\", \"RestrictAddressFamilies\": \"none\", \"RestrictNamespaces\": \"no\", \"RestrictRealtime\": \"no\", \"RestrictSUIDSGID\": \"no\", \"Result\": \"success\", \"RootDirectoryStartOnly\": \"no\", \"RuntimeDirectoryMode\": \"0755\", \"RuntimeDirectoryPreserve\": \"no\", \"SameProcessGroup\": \"no\", \"SecureBits\": \"0\", \"SendSIGHUP\": \"no\", \"SendSIGKILL\": \"no\", \"Slice\": \"system.slice\", \"StandardError\": \"inherit\", \"StandardInput\": \"null\", \"StandardOutput\": \"journal\", \"StartLimitAction\": \"none\", \"StartLimitBurst\": \"5\", \"StartLimitIntervalUSec\": \"10s\", \"StateChangeTimestamp\": \"2024-01-15 10:00:00 UTC\", \"StateChangeTimestampMonotonic\": \"123456789\", \"StatusErrno\": \"0\", \"StatusText\": \"\", \"StopWhenUnneeded\": \"no\", \"SubState\": \"running\", \"SuccessAction\": \"none\", \"SyslogFacility\": \"daemon\", \"SyslogIdentifier\": \"nginx\", \"SyslogLevelPrefix\": \"6\", \"SystemCallErrorNumber\": \"0\", \"TTYPath\": \"/dev/pts/0\", \"TasksAccounting\": \"yes\", \"TasksCurrent\": \"1\", \"TasksMax\": \"4915\", \"TimeoutStartUSec\": \"1min 30s\", \"TimeoutStopUSec\": \"1min 30s\", \"TimerSlackNSec\": \"50000\", \"Transient\": \"no\", \"Type\": \"notify\", \"UID\": \"0\", \"UMask\": \"0022\", \"UnitFilePreset\": \"disabled\", \"UnitFileState\": \"enabled\", \"UtmpIdentifier\": \"nginx\", \"UtmpMode\": \"user\", \"WantedBy\": \"multi-user.target\", \"Wants\": \"network.target\", \"WatchdogTimestampMonotonic\": \"0\", \"WatchdogUSec\": \"0\"}}"
# }
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=3    unreachable=0    failed=0
```

---

## 本章小结

- 连接错误包括SSH连接错误、认证错误
- SSH连接错误常见原因包括SSH服务未启动、SSH端口错误、防火墙阻止
- 认证错误常见原因包括密钥权限错误、密码错误、用户权限不足
- 执行错误包括模块执行错误、权限错误
- 模块执行错误常见原因包括模块未安装、模块参数错误、模块依赖错误
- 权限错误常见原因包括文件权限不足、目录权限不足、用户权限不足
- 变量错误包括变量未定义、变量类型错误
- 变量未定义常见原因包括变量未定义、变量作用域错误、变量名称错误
- 变量类型错误常见原因包括变量类型不匹配、变量值类型错误、变量引用错误
- 模板错误包括模板语法错误、模板变量错误
- 模板语法错误常见原因包括Jinja2语法错误、变量引用错误、过滤器错误
- 模板变量错误常见原因包括变量未定义、变量类型不匹配、变量访问错误
- 调试技巧包括使用调试模块、使用详细输出、使用检查模式、使用单步执行
- 可以使用debug模块显示变量和消息
- 可以使用-v、-vv、-vvv、-vvvv增加详细输出
- 可以使用--check模式进行测试
- 可以使用--step模式进行单步执行
- 可以使用ignore_errors忽略错误
- 可以使用failed_when自定义失败条件
- 可以使用retries和until重试执行

---

**恭喜！你已经完成了Ansible专题的学习！**
