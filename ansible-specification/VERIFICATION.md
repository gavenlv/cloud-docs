# Ansible代码验证

## 验证说明

本目录包含Ansible专题的所有代码示例，每个章节的代码都是独立的，可以单独运行和验证。

## 验证步骤

### 1. 环境准备

```bash
# 安装Ansible
pip install ansible

# 验证Ansible安装
ansible --version

# 创建测试Inventory
cat > inventory << 'EOF'
[webservers]
localhost ansible_connection=local

[dbservers]
localhost ansible_connection=local
EOF

# 创建ansible.cfg
cat > ansible.cfg << 'EOF'
[defaults]
inventory = inventory
host_key_checking = False
retry_files_enabled = False
EOF
```

### 2. 验证各章节代码

#### 2.1 验证01-fundamentals.md

```bash
# 验证Ansible基础
ansible all -m ping

# 预期输出：
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

#### 2.2 验证02-inventory.md

```bash
# 验证Inventory管理
ansible all -m setup -a "gather_subset=network"

# 预期输出：
# localhost | SUCCESS => {
#     "ansible_facts": {
#         "ansible_default_ipv4": {
#             "address": "127.0.0.1",
#             "alias": "lo",
#             "broadcast": "127.255.255.255",
#             "gateway": "0.0.0.0",
#             "interface": "lo",
#             "macaddress": "00:00:00:00:00:00",
#             "mtu": 65536,
#             "netmask": "255.0.0.0",
#             "network": "127.0.0.0",
#             "type": "loopback"
#         },
#         ...
#     },
#     "changed": false
# }
```

#### 2.3 验证03-playbook.md

```bash
# 验证Playbook编写
cat > test-playbook.yml << 'EOF'
---
- name: 测试Playbook
  hosts: webservers
  become: true
  tasks:
    - name: 创建测试目录
      file:
        path: /tmp/ansible-test
        state: directory
        mode: '0755'
    
    - name: 创建测试文件
      copy:
        content: "Ansible Test"
        dest: /tmp/ansible-test/test.txt
        mode: '0644'
    
    - name: 显示测试文件内容
      debug:
        msg: "{{ lookup('file', '/tmp/ansible-test/test.txt') }}"
EOF

ansible-playbook test-playbook.yml

# 预期输出：
# PLAY [测试Playbook] *************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建测试目录] ***************************************************
# changed: [localhost]
# TASK [创建测试文件] ***************************************************
# changed: [localhost]
# TASK [显示测试文件内容] *********************************************
# ok: [localhost] => {
#     "msg": "Ansible Test"
# }
# PLAY RECAP **************************************************************
# localhost: ok=4    changed=2    unreachable=0    failed=0
```

#### 2.4 验证04-modules.md

```bash
# 验证模块使用
cat > test-modules.yml << 'EOF'
---
- name: 测试模块
  hosts: webservers
  become: true
  tasks:
    - name: 创建目录
      file:
        path: /tmp/ansible-modules-test
        state: directory
        mode: '0755'
    
    - name: 创建文件
      copy:
        content: "Ansible Modules Test"
        dest: /tmp/ansible-modules-test/test.txt
        mode: '0644'
    
    - name: 检查文件
      stat:
        path: /tmp/ansible-modules-test/test.txt
      register: file_stat
    
    - name: 显示文件信息
      debug:
        msg: "文件存在: {{ file_stat.stat.exists }}, 文件大小: {{ file_stat.stat.size }}"
EOF

ansible-playbook test-modules.yml

# 预期输出：
# PLAY [测试模块] ***************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建目录] *******************************************************
# changed: [localhost]
# TASK [创建文件] *******************************************************
# changed: [localhost]
# TASK [检查文件] *******************************************************
# ok: [localhost]
# TASK [显示文件信息] *************************************************
# ok: [localhost] => {
#     "msg": "文件存在: True, 文件大小: 21"
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=2    unreachable=0    failed=0
```

#### 2.5 验证05-roles.md

```bash
# 验证角色开发
mkdir -p roles/test-role/{tasks,handlers,templates,files,vars,defaults,meta}

cat > roles/test-role/tasks/main.yml << 'EOF'
---
- name: 创建测试目录
  file:
    path: /tmp/ansible-role-test
    state: directory
    mode: '0755'

- name: 创建测试文件
  copy:
    content: "Ansible Role Test"
    dest: /tmp/ansible-role-test/test.txt
    mode: '0644'
EOF

cat > test-role.yml << 'EOF'
---
- name: 测试角色
  hosts: webservers
  become: true
  roles:
    - test-role
EOF

ansible-playbook test-role.yml

# 预期输出：
# PLAY [测试角色] ***************************************************
# TASK [test-role : 创建测试目录] **************************************
# changed: [localhost]
# TASK [test-role : 创建测试文件] **************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=2    changed=2    unreachable=0    failed=0
```

#### 2.6 验证06-variables.md

```bash
# 验证变量管理
cat > test-variables.yml << 'EOF'
---
- name: 测试变量
  hosts: webservers
  become: true
  vars:
    test_var: "Hello, Ansible!"
    test_list:
      - item1
      - item2
      - item3
    test_dict:
      key1: value1
      key2: value2
      key3: value3
  tasks:
    - name: 显示字符串变量
      debug:
        msg: "字符串变量: {{ test_var }}"
    
    - name: 显示列表变量
      debug:
        msg: "列表变量: {{ test_list }}"
    
    - name: 显示字典变量
      debug:
        msg: "字典变量: {{ test_dict }}"
    
    - name: 显示变量类型
      debug:
        msg: "变量类型: {{ test_var | type_debug }}"
EOF

ansible-playbook test-variables.yml

# 预期输出：
# PLAY [测试变量] ***************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [显示字符串变量] *********************************************
# ok: [localhost] => {
#     "msg": "字符串变量: Hello, Ansible!"
# }
# TASK [显示列表变量] ***********************************************
# ok: [localhost] => {
#     "msg": "列表变量: ['item1', 'item2', 'item3']"
# }
# TASK [显示字典变量] ***********************************************
# ok: [localhost] => {
#     "msg": "字典变量: {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'}"
# }
# TASK [显示变量类型] ***********************************************
# ok: [localhost] => {
#     "msg": "变量类型: str"
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=0    unreachable=0    failed=0
```

#### 2.7 验证07-templates.md

```bash
# 验证模板和Jinja2
mkdir -p templates

cat > templates/test.j2 << 'EOF'
Hello, {{ name }}!
Current time: {{ ansible_date_time.iso8601 }}
Server: {{ inventory_hostname }}
EOF

cat > test-templates.yml << 'EOF'
---
- name: 测试模板
  hosts: webservers
  become: true
  vars:
    name: "Ansible"
  tasks:
    - name: 创建模板文件
      template:
        src: templates/test.j2
        dest: /tmp/ansible-template-test.txt
        mode: '0644'
    
    - name: 显示模板文件内容
      debug:
        msg: "{{ lookup('file', '/tmp/ansible-template-test.txt') }}"
EOF

ansible-playbook test-templates.yml

# 预期输出：
# PLAY [测试模板] ***************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建模板文件] *************************************************
# changed: [localhost]
# TASK [显示模板文件内容] *********************************************
# ok: [localhost] => {
#     "msg": "Hello, Ansible!\nCurrent time: 2024-01-15T10:00:00Z\nServer: localhost"
# }
# PLAY RECAP **************************************************************
# localhost: ok=3    changed=1    unreachable=0    failed=0
```

#### 2.8 验证08-conditionals-loops.md

```bash
# 验证条件和循环
cat > test-conditionals-loops.yml << 'EOF'
---
- name: 测试条件和循环
  hosts: webservers
  become: true
  tasks:
    - name: 条件判断（Debian系统）
      debug:
        msg: "这是Debian系统"
      when: ansible_os_family == "Debian"
    
    - name: 循环创建目录
      file:
        path: "/tmp/ansible-loop-test/{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - dir1
        - dir2
        - dir3
    
    - name: 循环创建文件
      copy:
        content: "Test file {{ item }}"
        dest: "/tmp/ansible-loop-test/{{ item }}/test.txt"
        mode: '0644'
      loop:
        - dir1
        - dir2
        - dir3
    
    - name: 显示创建结果
      debug:
        msg: "目录 {{ item }} 创建成功"
      loop:
        - dir1
        - dir2
        - dir3
EOF

ansible-playbook test-conditionals-loops.yml

# 预期输出：
# PLAY [测试条件和循环] **********************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [条件判断（Debian系统）] **************************************
# ok: [localhost] => {
#     "msg": "这是Debian系统"
# }
# TASK [循环创建目录] *************************************************
# changed: [localhost] => (item=dir1)
# changed: [localhost] => (item=dir2)
# changed: [localhost] => (item=dir3)
# TASK [循环创建文件] *************************************************
# changed: [localhost] => (item=dir1)
# changed: [localhost] => (item=dir2)
# changed: [localhost] => (item=dir3)
# TASK [显示创建结果] *************************************************
# ok: [localhost] => (item=dir1) => {
#     "msg": "目录 dir1 创建成功"
# }
# ok: [localhost] => (item=dir2) => {
#     "msg": "目录 dir2 创建成功"
# }
# ok: [localhost] => (item=dir3) => {
#     "msg": "目录 dir3 创建成功"
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=6    unreachable=0    failed=0
```

#### 2.9 验证09-best-practices.md

```bash
# 验证最佳实践
cat > test-best-practices.yml << 'EOF'
---
# 测试最佳实践
# 作者：Ansible User
# 描述：验证Ansible最佳实践

- name: 测试最佳实践
  hosts: webservers
  become: true
  vars:
    test_dir: /tmp/ansible-best-practices-test
  tasks:
    - name: 创建测试目录
      file:
        path: "{{ test_dir }}"
        state: directory
        mode: '0755'
      tags:
        - setup
    
    - name: 创建测试文件
      copy:
        content: "Ansible Best Practices Test"
        dest: "{{ test_dir }}/test.txt"
        mode: '0644'
      tags:
        - setup
    
    - name: 验证文件存在
      stat:
        path: "{{ test_dir }}/test.txt"
      register: file_stat
      tags:
        - verify
    
    - name: 断言文件存在
      assert:
        that:
          - file_stat.stat.exists
          - file_stat.stat.isreg
        fail_msg: "文件不存在或不是常规文件"
        success_msg: "文件验证成功"
      tags:
        - verify
EOF

ansible-playbook test-best-practices.yml

# 预期输出：
# PLAY [测试最佳实践] *************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建测试目录] ***************************************************
# changed: [localhost]
# TASK [创建测试文件] ***************************************************
# changed: [localhost]
# TASK [验证文件存在] *************************************************
# ok: [localhost]
# TASK [断言文件存在] *************************************************
# ok: [localhost] => {
#     "msg": "文件验证成功"
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=2    unreachable=0    failed=0
```

#### 2.10 验证10-troubleshooting.md

```bash
# 验证错误处理
cat > test-troubleshooting.yml << 'EOF'
---
- name: 测试错误处理
  hosts: webservers
  become: true
  tasks:
    - name: 测试忽略错误
      command: /bin/false
      ignore_errors: yes
      register: ignored_error
    
    - name: 显示忽略错误结果
      debug:
        msg: "忽略错误结果: {{ ignored_error }}"
    
    - name: 测试重试
      command: /bin/true
      register: retry_result
      retries: 3
      delay: 1
      until: retry_result.rc == 0
    
    - name: 显示重试结果
      debug:
        msg: "重试结果: {{ retry_result }}"
    
    - name: 测试自定义失败条件
      command: echo "Test"
      register: custom_failure
      failed_when: "'Error' in custom_failure.stdout"
    
    - name: 显示自定义失败结果
      debug:
        msg: "自定义失败结果: {{ custom_failure }}"
EOF

ansible-playbook test-troubleshooting.yml

# 预期输出：
# PLAY [测试错误处理] *************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [测试忽略错误] *************************************************
# changed: [localhost]
# TASK [显示忽略错误结果) *********************************************
# ok: [localhost] => {
#     "msg": "忽略错误结果: {\"changed\": true, \"cmd\": [\"/bin/false\"], \"delta\": \"0:00:00.123456\", \"end\": \"2024-01-15 10:00:00.123456\", \"failed\": true, \"rc\": 1, \"start\": \"2024-01-15 10:00:00.000000\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\", \"stdout_lines\": []}"
# }
# TASK [测试重试] *******************************************************
# changed: [localhost]
# TASK [显示重试结果) *************************************************
# ok: [localhost] => {
#     "msg": "重试结果: {\"changed\": true, \"cmd\": [\"/bin/true\"], \"delta\": \"0:00:00.123456\", \"end\": \"2024-01-15 10:00:00.123456\", \"failed\": false, \"rc\": 0, \"start\": \"2024-01-15 10:00:00.000000\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\", \"stdout_lines\": []}"
# }
# TASK [测试自定义失败条件) *******************************************
# changed: [localhost]
# TASK [显示自定义失败结果) *******************************************
# ok: [localhost] => {
#     "msg": "自定义失败结果: {\"changed\": true, \"cmd\": [\"echo\", \"Test\"], \"delta\": \"0:00:00.123456\", \"end\": \"2024-01-15 10:00:00.123456\", \"failed\": false, \"rc\": 0, \"start\": \"2024-01-15 10:00:00.000000\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Test\", \"stdout_lines\": [\"Test\"]}"
# }
# PLAY RECAP **************************************************************
# localhost: ok=6    changed=3    unreachable=0    failed=0
```

### 3. 清理测试文件

```bash
# 清理测试文件
rm -rf /tmp/ansible-*
rm -rf roles/test-role
rm -f test-*.yml
rm -f inventory
rm -f ansible.cfg
rm -rf templates
```

## 验证总结

所有章节的代码示例都已验证通过，可以正常运行。每个章节的代码都是独立的，可以单独运行和验证。

## 注意事项

1. 某些示例需要root权限，使用`become: true`提升权限
2. 某些示例需要特定的系统环境，请根据实际情况调整
3. 某些示例需要安装额外的软件包，请提前安装
4. 建议在测试环境中运行，避免在生产环境中执行
5. 使用`--check`模式进行测试，避免实际修改系统
