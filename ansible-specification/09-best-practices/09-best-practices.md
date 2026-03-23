# Ansible最佳实践

## 9.1 代码组织最佳实践

### 9.1.1 Playbook组织

```
Playbook组织最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  Playbook组织                                    │
└─────────────────────────────────────────────────────────────────┘

1. 目录结构

最佳实践：
├── 使用清晰的目录结构
├── 分离不同类型的文件
├── 使用有意义的文件名
└── 保持目录结构一致

推荐结构：
project/
├── inventory/
│   ├── production/
│   ├── staging/
│   └── development/
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── host_vars/
│   ├── web1.example.com.yml
│   └── db1.example.com.yml
├── roles/
│   ├── nginx/
│   ├── mysql/
│   └── app/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── templates/
│   ├── nginx.conf.j2
│   └── my.cnf.j2
├── files/
│   ├── config.conf
│   └── script.sh
├── library/
│   └── custom_module.py
├── filter_plugins/
│   └── custom_filters.py
└── README.md

2. Playbook命名

最佳实践：
├── 使用描述性的文件名
├── 使用小写字母和下划线
├── 使用.yml扩展名
└── 保持命名一致

示例：
├── site.yml
├── webservers.yml
├── dbservers.yml
├── deploy_app.yml
├── update_config.yml
└── backup_data.yml

3. Playbook结构

最佳实践：
├── 使用注释说明Playbook
├── 使用有意义的Play名称
├── 使用有意义的Task名称
├── 使用标签组织Task
└── 使用Handler管理服务

示例：
---
# 配置Web服务器
# 作者：Ansible User
# 描述：安装和配置Nginx Web服务器

- name: 配置Web服务器
  hosts: webservers
  become: true
  vars_files:
    - vars/common.yml
    - vars/webservers.yml
  pre_tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags:
        - always
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      tags:
        - nginx
        - install
      notify:
        - 重启Nginx服务
    
    - name: 配置Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      tags:
        - nginx
        - configure
      notify:
        - 重新加载Nginx服务
  handlers:
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
    
    - name: 重新加载Nginx服务
      service:
        name: nginx
        state: reloaded
```

### 9.1.2 角色组织

```
角色组织最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  角色组织                                              │
└─────────────────────────────────────────────────────────────────┘

1. 角色结构

最佳实践：
├── 使用标准的角色结构
├── 分离不同类型的文件
├── 使用有意义的文件名
└── 保持角色结构一致

推荐结构：
role-name/
├── defaults/
│   └── main.yml
├── vars/
│   └── main.yml
├── tasks/
│   ├── main.yml
│   ├── install.yml
│   ├── configure.yml
│   └── service.yml
├── handlers/
│   └── main.yml
├── templates/
│   ├── config.conf.j2
│   └── service.conf.j2
├── files/
│   ├── config.conf
│   └── script.sh
├── meta/
│   └── main.yml
├── tests/
│   ├── inventory
│   └── test.yml
└── README.md

2. 角色命名

最佳实践：
├── 使用描述性的角色名
├── 使用小写字母和下划线
├── 使用有意义的名称
└── 保持命名一致

示例：
├── nginx
├── mysql
├── redis
├── app
├── monitoring
└── backup

3. 角色依赖

最佳实践：
├── 明确声明角色依赖
├── 使用变量配置依赖
├── 避免循环依赖
└── 测试角色依赖

示例：
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
```

---

## 9.2 性能优化最佳实践

### 9.2.1 Facts收集优化

```yaml
# facts-optimization.yml
---
- name: Facts收集优化示例
  hosts: webservers
  become: true
  tasks:
    - name: 禁用Facts收集
      setup:
      when: false
    
    - name: 只收集特定Facts
      setup:
        gather_subset:
          - "!all"
          - "!facter"
          - "!ohai"
          - network
          - virtual
    
    - name: 使用Facts缓存
      setup:
      when: ansible_date_time.epoch | int - ansible_facts_cache_timestamp | int > 3600
    
    - name: 使用自定义Facts
      debug:
        msg: "自定义Fact: {{ ansible_local.custom_fact }}"
```

### 9.2.2 并发执行优化

```yaml
# parallel-execution.yml
---
- name: 并发执行优化示例
  hosts: webservers
  become: true
  serial:
    - "30%"
    - "50%"
    - "100%"
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 配置Nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      async: 300
      poll: 10
```

### 9.2.3 模块执行优化

```yaml
# module-execution-optimization.yml
---
- name: 模块执行优化示例
  hosts: webservers
  become: true
  tasks:
    - name: 使用pipelining
      apt:
        name: nginx
        state: present
        update_cache: yes
      vars:
        ansible_ssh_pipelining: true
    
    - name: 使用SSH multiplexing
      apt:
        name: nginx
        state: present
        update_cache: yes
      vars:
        ansible_ssh_common_args: '-o ControlMaster=auto -o ControlPersist=60s'
    
    - name: 使用SSH压缩
      apt:
        name: nginx
        state: present
        update_cache: yes
      vars:
        ansible_ssh_common_args: '-o Compression=yes'
```

---

## 9.3 安全最佳实践

### 9.3.1 敏感数据加密

```yaml
# sensitive-data-encryption.yml
---
- name: 敏感数据加密示例
  hosts: webservers
  become: true
  vars_files:
    - vault/encrypted.yml
  tasks:
    - name: 使用加密变量
      debug:
        msg: "数据库密码: {{ mysql_root_password }}"
      no_log: true
    
    - name: 创建数据库用户
      mysql_user:
        name: appuser
        password: "{{ mysql_app_password }}"
        priv: "appdb.*:ALL"
        state: present
      no_log: true
```

### 9.3.2 权限控制

```yaml
# permission-control.yml
---
- name: 权限控制示例
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
    
    - name: 配置sudo权限
      copy:
        content: "ansible ALL=(ALL) NOPASSWD:ALL"
        dest: /etc/sudoers.d/ansible
        mode: '0440'
        validate: 'visudo -cf %s'
```

### 9.3.3 网络安全

```yaml
# network-security.yml
---
- name: 网络安全示例
  hosts: webservers
  become: true
  tasks:
    - name: 配置防火墙
      ufw:
        state: enabled
        policy: deny
        direction: incoming
    
    - name: 允许SSH连接
      ufw:
        rule: allow
        port: 22
        proto: tcp
    
    - name: 允许HTTP连接
      ufw:
        rule: allow
        port: 80
        proto: tcp
    
    - name: 允许HTTPS连接
      ufw:
        rule: allow
        port: 443
        proto: tcp
    
    - name: 配置SSH安全
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        state: present
      loop:
        - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
        - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
      notify:
        - 重启SSH服务
  
  handlers:
    - name: 重启SSH服务
      service:
        name: ssh
        state: restarted
```

---

## 9.4 测试最佳实践

### 9.4.1 Playbook测试

```yaml
# playbook-testing.yml
---
- name: Playbook测试示例
  hosts: webservers
  become: true
  tasks:
    - name: 检查模式
      apt:
        name: nginx
        state: present
        update_cache: yes
      check_mode: yes
      register: nginx_check
    
    - name: 显示检查结果
      debug:
        msg: "Nginx安装检查: {{ nginx_check }}"
    
    - name: 验证配置
      command: nginx -t
      register: nginx_test
      changed_when: false
      failed_when: nginx_test.rc != 0
    
    - name: 显示验证结果
      debug:
        msg: "Nginx配置验证: {{ nginx_test.stdout }}"
```

### 9.4.2 角色测试

```yaml
# roles/nginx/tests/test.yml
---
- name: 测试Nginx角色
  hosts: webservers
  become: true
  tasks:
    - name: 检查Nginx是否安装
      apt:
        name: nginx
        state: present
      check_mode: yes
      register: nginx_check
    
    - name: 验证Nginx安装
      assert:
        that:
          - nginx_check is succeeded
        fail_msg: "Nginx安装失败"
        success_msg: "Nginx安装成功"
    
    - name: 检查Nginx服务
      service:
        name: nginx
        state: started
      register: nginx_service
    
    - name: 验证Nginx服务
      assert:
        that:
          - nginx_service.status.ActiveState == "active"
        fail_msg: "Nginx服务未运行"
        success_msg: "Nginx服务运行正常"
    
    - name: 测试Nginx响应
      uri:
        url: http://localhost
        method: GET
        status_code: 200
      register: nginx_response
    
    - name: 验证Nginx响应
      assert:
        that:
          - nginx_response.status == 200
        fail_msg: "Nginx响应失败"
        success_msg: "Nginx响应正常"
```

---

## 9.5 CI/CD集成最佳实践

### 9.5.1 GitHub Actions集成

```yaml
# .github/workflows/ansible.yml
name: Ansible CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install ansible ansible-lint yamllint
    
    - name: Lint YAML files
      run: yamllint .
    
    - name: Lint Ansible playbooks
      run: ansible-lint playbooks/
    
    - name: Run Ansible syntax check
      run: ansible-playbook playbooks/site.yml --syntax-check
    
    - name: Run Ansible playbook (dry-run)
      run: ansible-playbook playbooks/site.yml --check
```

### 9.5.2 GitLab CI集成

```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - deploy

lint:
  stage: lint
  image: python:3.9
  script:
    - pip install ansible ansible-lint yamllint
    - yamllint .
    - ansible-lint playbooks/

test:
  stage: test
  image: python:3.9
  script:
    - pip install ansible
    - ansible-playbook playbooks/site.yml --syntax-check
    - ansible-playbook playbooks/site.yml --check

deploy:
  stage: deploy
  image: python:3.9
  script:
    - pip install ansible
    - ansible-playbook playbooks/site.yml
  only:
    - main
```

---

## 9.6 实战：实施最佳实践

### 9.6.1 创建项目结构

```bash
# 创建项目结构

# 创建目录结构
mkdir -p ansible-project/{inventory/{production,staging,development},group_vars,host_vars,roles/{nginx,mysql,app},playbooks,templates,files,library,filter_plugins}

# 创建README文件
cat > ansible-project/README.md << 'EOF'
# Ansible项目

## 项目结构

```
ansible-project/
├── inventory/
│   ├── production/
│   ├── staging/
│   └── development/
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── host_vars/
│   ├── web1.example.com.yml
│   └── db1.example.com.yml
├── roles/
│   ├── nginx/
│   ├── mysql/
│   └── app/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── templates/
│   ├── nginx.conf.j2
│   └── my.cnf.j2
├── files/
│   ├── config.conf
│   └── script.sh
├── library/
│   └── custom_module.py
├── filter_plugins/
│   └── custom_filters.py
└── README.md
```

## 使用方法

### 运行Playbook

```bash
ansible-playbook playbooks/site.yml
```

### 运行特定Playbook

```bash
ansible-playbook playbooks/webservers.yml
```

### 运行特定Task

```bash
ansible-playbook playbooks/site.yml --tags nginx
```

### 检查模式

```bash
ansible-playbook playbooks/site.yml --check
```

### 语法检查

```bash
ansible-playbook playbooks/site.yml --syntax-check
```
EOF

# 验证项目结构
tree ansible-project

# 预期输出：
# ansible-project/
# ├── README.md
# ├── files/
# ├── filter_plugins/
# ├── group_vars/
# ├── host_vars/
# ├── inventory/
# │   ├── development/
# │   ├── production/
# │   └── staging/
# ├── library/
# ├── playbooks/
# ├── roles/
# │   ├── app/
# │   ├── mysql/
# │   └── nginx/
# └── templates/
```

### 9.6.2 创建主Playbook

```bash
# 创建主Playbook

# 创建Playbook文件
cat > ansible-project/playbooks/site.yml << 'EOF'
---
# 主Playbook
# 作者：Ansible User
# 描述：配置所有服务器

- name: 配置所有服务器
  hosts: all
  become: true
  vars_files:
    - ../group_vars/all.yml
  pre_tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags:
        - always

- name: 配置Web服务器
  import_playbook: webservers.yml

- name: 配置数据库服务器
  import_playbook: dbservers.yml
EOF

# 创建Web服务器Playbook
cat > ansible-project/playbooks/webservers.yml << 'EOF'
---
# Web服务器Playbook
# 作者：Ansible User
# 描述：配置Web服务器

- name: 配置Web服务器
  hosts: webservers
  become: true
  vars_files:
    - ../group_vars/webservers.yml
  roles:
    - role: nginx
      tags:
        - nginx
    - role: app
      tags:
        - app
EOF

# 创建数据库服务器Playbook
cat > ansible-project/playbooks/dbservers.yml << 'EOF'
---
# 数据库服务器Playbook
# 作者：Ansible User
# 描述：配置数据库服务器

- name: 配置数据库服务器
  hosts: dbservers
  become: true
  vars_files:
    - ../group_vars/dbservers.yml
  roles:
    - role: mysql
      tags:
        - mysql
EOF

# 验证Playbook
cat ansible-project/playbooks/site.yml
cat ansible-project/playbooks/webservers.yml
cat ansible-project/playbooks/dbservers.yml
```

### 9.6.3 创建变量文件

```bash
# 创建变量文件

# 创建全局变量
cat > ansible-project/group_vars/all.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

timezone: UTC
locale: en_US.UTF-8
EOF

# 创建Web服务器变量
cat > ansible-project/group_vars/webservers.yml << 'EOF'
---
nginx_port: 80
nginx_document_root: /var/www/html
nginx_server_name: localhost
nginx_ssl_enabled: false

app_name: webapp
app_version: 1.0.0
app_port: 8080
EOF

# 创建数据库服务器变量
cat > ansible-project/group_vars/dbservers.yml << 'EOF'
---
mysql_port: 3306
mysql_root_password: secret
mysql_database: appdb
mysql_user: appuser
mysql_password: apppass
EOF

# 验证变量文件
cat ansible-project/group_vars/all.yml
cat ansible-project/group_vars/webservers.yml
cat ansible-project/group_vars/dbservers.yml
```

---

## 本章小结

- 代码组织最佳实践包括Playbook组织、角色组织、变量组织
- Playbook组织应该使用清晰的目录结构、描述性的文件名、有意义的Play名称和Task名称
- 角色组织应该使用标准的角色结构、描述性的角色名、明确的角色依赖
- 性能优化最佳实践包括Facts收集优化、并发执行优化、模块执行优化
- 安全最佳实践包括敏感数据加密、权限控制、网络安全
- 测试最佳实践包括Playbook测试、角色测试、集成测试
- CI/CD集成最佳实践包括GitHub Actions集成、GitLab CI集成
- 可以使用ansible-vault加密敏感数据
- 可以使用check_mode进行测试
- 可以使用assert进行验证

---

**下一章：Ansible常见错误处理**
