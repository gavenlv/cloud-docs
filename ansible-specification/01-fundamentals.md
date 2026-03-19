# Ansible基础和核心原理

## 1.1 Ansible架构

### 1.1.1 Ansible的核心概念

```
Ansible的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Ansible是什么？                                    │
└─────────────────────────────────────────────────────────────────┘

Ansible是一个开源的自动化工具，用于配置管理、应用部署、任务编排：

1. 无代理架构
   ├── 不需要在被管理主机上安装代理
   ├── 使用SSH连接被管理主机
   ├── 使用Python执行任务
   └── 轻量级、简单、易用

2. 幂等性
   ├── 多次执行相同任务结果一致
   ├── 自动检测状态变化
   ├── 只执行必要的操作
   └── 安全可靠

3. 声明式语言
   ├── 描述期望状态
   ├── 不关心如何实现
   ├── 简化配置管理
   └── 提高可读性

4. 模块化设计
   ├── 丰富的模块库
   ├── 可扩展的模块系统
   ├── 支持自定义模块
   └── 社区活跃

5. 推送模式
   ├── 控制节点推送任务
   ├── 被管理节点执行任务
   ├── 实时反馈执行结果
   └── 集中式管理
```

### 1.1.2 Ansible架构原理

```
Ansible架构原理：

┌─────────────────────────────────────────────────────────────────┐
│  Ansible架构                                    │
└─────────────────────────────────────────────────────────────────┘

控制节点（Control Node）：
├── Ansible核心
├── Inventory
├── Playbook
├── 模块
└── 插件

被管理节点（Managed Node）：
├── SSH服务
├── Python运行时
├── 临时目录
└── 执行环境

执行流程：
1. 控制节点读取Playbook
2. 控制节点解析Playbook
3. 控制节点生成任务列表
4. 控制节点通过SSH连接被管理节点
5. 控制节点推送模块到被管理节点
6. 被管理节点执行模块
7. 被管理节点返回执行结果
8. 控制节点收集执行结果
9. 控制节点显示执行结果

架构图：
┌─────────────────────────────────────────────────────────────────┐
│                        控制节点                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Playbook   │  │   Inventory  │  │    Modules   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                     │
│         └─────────────────┴─────────────────┘                     │
│                           │                                       │
│                    ┌──────▼──────┐                               │
│                    │   Ansible    │                               │
│                    │   Core       │                               │
│                    └──────┬──────┘                               │
└───────────────────────────┼───────────────────────────────────────┘
                            │ SSH
                            │
┌───────────────────────────┼───────────────────────────────────────┐
│                    ┌──────▼──────┐                               │
│  被管理节点1         │   SSH       │                               │
│  ┌──────────────┐   │   Daemon    │                               │
│  │   Python     │   └──────┬──────┘                               │
│  │   Runtime    │          │                                     │
│  └──────────────┘   ┌──────▼──────┐                               │
│                    │   Modules   │                               │
│                    │   Cache     │                               │
│                    └─────────────┘                               │
└───────────────────────────────────────────────────────────────────┘
┌───────────────────────────┼───────────────────────────────────────┐
│                    ┌──────▼──────┐                               │
│  被管理节点2         │   SSH       │                               │
│  ┌──────────────┐   │   Daemon    │                               │
│  │   Python     │   └──────┬──────┘                               │
│  │   Runtime    │          │                                     │
│  └──────────────┘   ┌──────▼──────┐                               │
│                    │   Modules   │                               │
│                    │   Cache     │                               │
│                    └─────────────┘                               │
└───────────────────────────────────────────────────────────────────┘
```

### 1.1.3 无代理架构原理

```
无代理架构原理：

┌─────────────────────────────────────────────────────────────────┐
│  无代理架构原理                                    │
└─────────────────────────────────────────────────────────────────┘

1. SSH连接

SSH连接特点：
├── 安全加密
├── 标准协议
├── 广泛支持
└── 无需额外安装

SSH连接流程：
1. 控制节点建立SSH连接
2. 控制节点进行身份验证
3. 控制节点建立安全通道
4. 控制节点传输数据
5. 控制节点关闭连接

SSH连接配置：
├── 密钥认证
├── 密码认证
├── SSH配置文件
└── SSH代理

2. 模块执行

模块执行流程：
1. 控制节点生成模块参数
2. 控制节点打包模块
3. 控制节点传输模块到被管理节点
4. 被管理节点解压模块
5. 被管理节点执行模块
6. 被管理节点返回结果
7. 被管理节点清理临时文件

模块执行特点：
├── 临时执行
├── 自动清理
├── 幂等性保证
└── 错误处理

3. 临时目录

临时目录作用：
├── 存储模块文件
├── 存储执行结果
├── 存储临时数据
└── 自动清理

临时目录位置：
├── /tmp/ansible
├── ~/.ansible/tmp
├── /var/tmp/ansible
└── 可配置

临时目录清理：
├── 执行完成后清理
├── 失败时保留
├── 可配置保留时间
└── 手动清理
```

---

## 1.2 Ansible配置

### 1.2.1 ansible.cfg配置

```
ansible.cfg配置：

┌─────────────────────────────────────────────────────────────────┐
│  ansible.cfg配置                                    │
└─────────────────────────────────────────────────────────────────┘

1. 配置文件位置

配置文件优先级（从高到低）：
├── ANSIBLE_CONFIG环境变量
├── ./ansible.cfg（当前目录）
├── ~/.ansible.cfg（用户目录）
├── /etc/ansible/ansible.cfg（系统目录）
└── 默认配置

2. 配置文件示例

[defaults]
# Inventory文件路径
inventory = ./inventory

# 主机密钥检查
host_key_checking = False

# 重试文件
retry_files_enabled = False

# Facts收集策略
gathering = smart

# Facts缓存
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

# 并发数
forks = 5

# 超时时间
timeout = 30

# 显示输出
display_skipped_hosts = False
display_ok_hosts = True

# 日志
log_path = /var/log/ansible.log

[privilege_escalation]
# 权限提升
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
# SSH连接参数
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[colors]
# 颜色输出
highlight = white
verbose = blue
warn = bright purple
error = red
debug = dark gray
deprecate = purple
skip = cyan
unreachable = red
ok = green
changed = yellow
diff_add = green
diff_remove = red
diff_lines = cyan

3. 配置文件最佳实践

配置文件组织：
├── 使用注释说明配置
├── 分组相关配置
├── 使用默认值
└── 版本控制

配置文件安全：
├── 敏感信息使用Vault加密
├── 限制文件权限
├── 使用环境变量
└── 定期审查
```

### 1.2.2 Inventory配置

```
Inventory配置：

┌─────────────────────────────────────────────────────────────────┐
│  Inventory配置                                    │
└─────────────────────────────────────────────────────────────────┘

1. 静态Inventory

INI格式：
[webservers]
web1.example.com
web2.example.com
web3.example.com

[dbservers]
db1.example.com
db2.example.com

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

YAML格式：
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
        web3.example.com:
    dbservers:
      hosts:
        db1.example.com:
        db2.example.com:
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_python_interpreter: /usr/bin/python3

2. 主机变量

主机变量定义：
[webservers]
web1.example.com ansible_host=192.168.1.10 ansible_port=2222
web2.example.com ansible_host=192.168.1.11
web3.example.com ansible_host=192.168.1.12

[webservers:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa

主机变量文件：
host_vars/web1.example.com:
---
ansible_host: 192.168.1.10
ansible_port: 2222
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa

3. 组变量

组变量定义：
[webservers]
web1.example.com
web2.example.com
web3.example.com

[webservers:vars]
http_port: 80
https_port: 443
document_root: /var/www/html

组变量文件：
group_vars/webservers.yml:
---
http_port: 80
https_port: 443
document_root: /var/www/html

4. 动态Inventory

动态Inventory脚本：
#!/usr/bin/env python3

import json
import sys

def get_inventory():
    inventory = {
        "webservers": {
            "hosts": ["web1.example.com", "web2.example.com"],
            "vars": {
                "ansible_user": "ansible",
                "ansible_ssh_private_key_file": "~/.ssh/id_rsa"
            }
        },
        "dbservers": {
            "hosts": ["db1.example.com", "db2.example.com"],
            "vars": {
                "ansible_user": "ansible",
                "ansible_ssh_private_key_file": "~/.ssh/id_rsa"
            }
        },
        "_meta": {
            "hostvars": {
                "web1.example.com": {
                    "ansible_host": "192.168.1.10"
                },
                "web2.example.com": {
                    "ansible_host": "192.168.1.11"
                }
            }
        }
    }
    return inventory

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        print(json.dumps(get_inventory()))
    else:
        print(json.dumps({}))
```

---

## 1.3 实战：安装和配置Ansible

### 1.3.1 安装Ansible

```bash
# 安装Ansible

# 方法1：使用包管理器安装

# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# CentOS/RHEL
sudo yum install ansible

# 方法2：使用pip安装
pip install ansible

# 方法3：使用虚拟环境安装
python3 -m venv ansible-env
source ansible-env/bin/activate
pip install ansible

# 验证安装
ansible --version

# 预期输出：
# ansible [core 2.15.0]
#   config file = None
#   configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
#   ansible python module location = /usr/local/lib/python3.10/site-packages/ansible
#   ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
#   executable location = /usr/local/bin/ansible
#   python version = 3.10.12
#   jinja version = 3.1.2
#   libyaml = True
```

### 1.3.2 配置Ansible

```bash
# 配置Ansible

# 创建配置目录
mkdir -p ~/.ansible

# 创建配置文件
cat > ~/.ansible/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
forks = 5
timeout = 30
display_skipped_hosts = False
display_ok_hosts = True
log_path = /var/log/ansible.log

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[colors]
highlight = white
verbose = blue
warn = bright purple
error = red
debug = dark gray
deprecate = purple
skip = cyan
unreachable = red
ok = green
changed = yellow
diff_add = green
diff_remove = red
diff_lines = cyan
EOF

# 验证配置
ansible --version

# 预期输出：
# ansible [core 2.15.0]
#   config file = /home/user/.ansible/ansible.cfg
#   configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
#   ansible python module location = /usr/local/lib/python3.10/site-packages/ansible
#   ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
#   executable location = /usr/local/bin/ansible
#   python version = 3.10.12
#   jinja version = 3.1.2
#   libyaml = True
```

### 1.3.3 创建Inventory

```bash
# 创建Inventory

# 创建Inventory文件
cat > inventory << 'EOF'
[webservers]
localhost ansible_connection=local

[dbservers]
localhost ansible_connection=local

[all:vars]
ansible_user=ansible
ansible_python_interpreter=/usr/bin/python3
EOF

# 验证Inventory
ansible-inventory --list

# 预期输出：
# {
#     "_meta": {
#         "hostvars": {}
#     },
#     "all": {
#         "children": [
#             "dbservers",
#             "ungrouped",
#             "webservers"
#         ]
#     },
#     "dbservers": {
#         "hosts": [
#             "localhost"
#         ]
#     },
#     "webservers": {
#         "hosts": [
#             "localhost"
#         ]
#     }
# }

# 测试连接
ansible all -m ping

# 预期输出：
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### 1.3.4 运行第一个命令

```bash
# 运行第一个命令

# 收集Facts
ansible all -m setup

# 预期输出：
# localhost | SUCCESS => {
#     "ansible_facts": {
#         "ansible_all_ipv4_addresses": [
#             "192.168.1.10"
#         ],
#         "ansible_all_ipv6_addresses": [
#             "fe80::1"
#         ],
#         "ansible_apparmor": {
#             "status": "enabled"
#         },
#         "ansible_architecture": "x86_64",
#         "ansible_bios_date": "01/01/2011",
#         "ansible_bios_version": "1.0",
#         "ansible_cmdline": {
#             "BOOT_IMAGE": "/boot/vmlinuz-5.15.0-91-generic",
#             "quiet": true,
#             "ro": true,
#             "root": "UUID=12345678-1234-1234-1234-123456789012"
#         },
#         "ansible_date_time": {
#             "date": "2024-01-15",
#             "day": "15",
#             "epoch": "1705296000",
#             "hour": "10",
#             "iso8601_basic": "20240115T100000Z",
#             "iso8601_basic_short": "20240115T100000",
#             "iso8601_micro": "2024-01-15T10:00:00.000000Z",
#             "minute": "00",
#             "month": "01",
#             "second": "00",
#             "time": "10:00:00",
#             "weekday": "Monday",
#             "weekday_number": "1",
#             "weekday_short": "Mon",
#             "year": "2024"
#         },
#         "ansible_default_ipv4": {
#             "address": "192.168.1.10",
#             "alias": "eth0",
#             "broadcast": "192.168.1.255",
#             "device": "eth0",
#             "gateway": "192.168.1.1",
#             "interface": "eth0",
#             "macaddress": "00:11:22:33:44:55",
#             "mtu": 1500,
#             "netmask": "255.255.255.0",
#             "network": "192.168.1.0",
#             "type": "ether"
#         },
#         "ansible_distribution": "Ubuntu",
#         "ansible_distribution_file_parsed": true,
#         "ansible_distribution_file_path": "/etc/os-release",
#         "ansible_distribution_file_variety": "Ubuntu",
#         "ansible_distribution_major_version": "22",
#         "ansible_distribution_release": "jammy",
#         "ansible_distribution_version": "22.04",
#         "ansible_dns": {
#             "nameservers": [
#                 "127.0.0.53"
#             ],
#             "search": [
#                 "localdomain"
#             ]
#         },
#         "ansible_domain": "",
#         "ansible_effective_group_id": 1000,
#         "ansible_effective_user_id": 1000,
#         "ansible_env": {
#             "HOME": "/home/user",
#             "LANG": "en_US.UTF-8",
#             "LC_ALL": "en_US.UTF-8",
#             "LOGNAME": "user",
#             "PATH": "/usr/local/bin:/usr/bin:/bin",
#             "PWD": "/home/user",
#             "SHELL": "/bin/bash",
#             "USER": "user"
#         },
#         "ansible_fips": false,
#         "ansible_fqdn": "localhost",
#         "ansible_hostname": "localhost",
#         "ansible_hostnqn": "",
#         "ansible_kernel": "5.15.0-91-generic",
#         "ansible_local": {},
#         "ansible_lsb": {
#             "codename": "jammy",
#             "description": "Ubuntu 22.04.3 LTS",
#             "id": "Ubuntu",
#             "major_release": "22",
#             "release": "22.04"
#         },
#         "ansible_machine": "x86_64",
#         "ansible_machine_id": "1234567890abcdef1234567890abcdef",
#         "ansible_memtotal_mb": 8192,
#         "ansible_memory_mb": {
#             "nocache": {
#                 "free": 4096,
#                 "real": {
#                     "free": 4096,
#                     "total": 8192,
#                     "used": 4096
#                 },
#                 "swap": {
#                     "cached": 0,
#                     "free": 2048,
#                     "total": 2048,
#                     "used": 0
#                 }
#             },
#             "real": {
#                 "free": 2048,
#                 "total": 8192,
#                 "used": 6144
#             },
#             "swap": {
#                 "cached": 0,
#                 "free": 2048,
#                 "total": 2048,
#                 "used": 0
#             }
#         },
#         "ansible_nodename": "localhost",
#         "ansible_os_family": "Debian",
#         "ansible_pkg_mgr": "apt",
#         "ansible_processor": [
#             "0",
#             "1",
#             "2",
#             "3"
#         ],
#         "ansible_processor_cores": 4,
#         "ansible_processor_count": 1,
#         "ansible_processor_threads_per_core": 1,
#         "ansible_processor_vcpus": 4,
#         "ansible_product_name": "VMware Virtual Platform",
#         "ansible_product_serial": "VMware-56 4d 12 34 56 78 90 ab cd",
#         "ansible_product_uuid": "564d1234-5678-90ab-cdef-1234567890ab",
#         "ansible_product_version": "None",
#         "ansible_python": {
#             "executable": "/usr/bin/python3",
#             "has_sslcontext": true,
#             "type": "cpython",
#             "version": {
#                 "major": 3,
#                 "micro": 12,
#                 "minor": 10,
#                 "releaselevel": "final",
#                 "serial": 0
#             },
#             "version_info": [
#                 3,
#                 10,
#                 12,
#                 "final",
#                 0
#             ]
#         },
#         "ansible_python_version": "3.10.12",
#         "ansible_real_group_id": 1000,
#         "ansible_real_user_id": 1000,
#         "ansible_selinux": {
#             "status": "Missing SELinux library"
#         },
#         "ansible_selinux_python_present": false,
#         "ansible_service_mgr": "systemd",
#         "ansible_ssh_host_key_dsa_public": "AAAAB3NzaC1kc3MAAACBAJ5/...",
#         "ansible_ssh_host_key_ecdsa_public": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENj...",
#         "ansible_ssh_host_key_ed25519_public": "AAAAC3NzaC1lZDI1NTE5AAAAIM4v...",
#         "ansible_ssh_host_key_rsa_public": "AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/...",
#         "ansible_system": "Linux",
#         "ansible_system_vendor": "VMware, Inc.",
#         "ansible_uptime_seconds": 86400,
#         "ansible_user_dir": "/home/user",
#         "ansible_user_gecos": "User",
#         "ansible_user_gid": 1000,
#         "ansible_user_id": "user",
#         "ansible_user_shell": "/bin/bash",
#         "ansible_user_uid": 1000,
#         "ansible_userspace_architecture": "x86_64",
#         "ansible_userspace_bits": "64",
#         "ansible_virtualization_role": "guest",
#         "ansible_virtualization_type": "VMware",
#         "discovered_interpreter_python": "/usr/bin/python3"
#     },
#     "changed": false
# }

# 执行命令
ansible all -m command -a "echo 'Hello, World!'"

# 预期输出：
# localhost | CHANGED | rc=0 >>
# Hello, World!
```

---

## 本章小结

- Ansible是一个开源的自动化工具，用于配置管理、应用部署、任务编排
- Ansible采用无代理架构，使用SSH连接被管理主机，使用Python执行任务
- Ansible具有幂等性、声明式语言、模块化设计、推送模式等特点
- Ansible架构包括控制节点和被管理节点，控制节点推送任务，被管理节点执行任务
- Ansible配置文件包括ansible.cfg、Inventory、Playbook等
- ansible.cfg配置包括Inventory路径、主机密钥检查、Facts收集策略、并发数、超时时间等
- Inventory配置包括静态Inventory、动态Inventory、主机变量、组变量等
- 可以使用包管理器、pip、虚拟环境等方式安装Ansible
- 可以使用ansible命令测试连接、收集Facts、执行命令等

---

**下一章：Inventory管理**
