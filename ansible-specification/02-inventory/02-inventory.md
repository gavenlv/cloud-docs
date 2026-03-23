# Inventory管理

## 2.1 Inventory原理

### 2.1.1 Inventory的核心概念

```
Inventory的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Inventory是什么？                                   │
└─────────────────────────────────────────────────────────────────┘

Inventory是Ansible中用于管理被管理主机的配置文件：

1. 主机管理
   ├── 定义主机列表
   ├── 主机分组
   ├── 主机变量
   └── 主机连接配置

2. 分组管理
   ├── 逻辑分组
   ├── 分组嵌套
   ├── 分组变量
   └── 分组继承

3. 变量管理
   ├── 主机变量
   ├── 组变量
   ├── 变量优先级
   └── 变量作用域

4. 动态管理
   ├── 静态Inventory
   ├── 动态Inventory
   ├── 混合Inventory
   └── Inventory脚本

5. 连接配置
   ├── SSH连接
   ├── 认证方式
   ├── 连接参数
   └── 连接优化
```

### 2.1.2 Inventory数据结构

```
Inventory数据结构：

┌─────────────────────────────────────────────────────────────────┐
│  Inventory数据结构                                   │
└─────────────────────────────────────────────────────────────────┘

1. 主机（Host）

主机属性：
├── 主机名
├── IP地址
├── 端口
├── 连接方式
└── 连接参数

主机示例：
web1.example.com
web2.example.com ansible_host=192.168.1.10 ansible_port=2222

2. 分组（Group）

分组属性：
├── 分组名
├── 主机列表
├── 子分组
├── 分组变量
└── 分组继承

分组示例：
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

[production:children]
webservers
dbservers

3. 变量（Variable）

变量类型：
├── 主机变量
├── 组变量
├── 连接变量
└── 自定义变量

变量示例：
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[webservers:vars]
http_port=80
https_port=443
document_root=/var/www/html

4. 连接配置（Connection）

连接参数：
├── ansible_host
├── ansible_port
├── ansible_user
├── ansible_ssh_private_key_file
├── ansible_ssh_common_args
├── ansible_connection
└── ansible_python_interpreter

连接示例：
web1.example.com ansible_host=192.168.1.10 ansible_port=2222 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_connection=ssh ansible_python_interpreter=/usr/bin/python3
```

---

## 2.2 静态Inventory

### 2.2.1 INI格式

```ini
# INI格式Inventory

# 基本格式
[webservers]
web1.example.com
web2.example.com
web3.example.com

[dbservers]
db1.example.com
db2.example.com

# 主机变量
[webservers]
web1.example.com ansible_host=192.168.1.10 ansible_port=2222
web2.example.com ansible_host=192.168.1.11
web3.example.com ansible_host=192.168.1.12

# 组变量
[webservers:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
http_port=80
https_port=443
document_root=/var/www/html

[dbservers:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
mysql_port=3306
mysql_root_password=secret

# 分组嵌套
[production:children]
webservers
dbservers

[staging:children]
webservers
dbservers

# 全局变量
[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

# 未分组主机
[ungrouped]
standalone.example.com
```

### 2.2.2 YAML格式

```yaml
# YAML格式Inventory

all:
  children:
    webservers:
      hosts:
        web1.example.com:
          ansible_host: 192.168.1.10
          ansible_port: 2222
          http_port: 80
        web2.example.com:
          ansible_host: 192.168.1.11
          ansible_port: 2222
          http_port: 80
        web3.example.com:
          ansible_host: 192.168.1.12
          ansible_port: 2222
          http_port: 80
      vars:
        ansible_user: ansible
        ansible_ssh_private_key_file: ~/.ssh/id_rsa
        ansible_python_interpreter: /usr/bin/python3
        https_port: 443
        document_root: /var/www/html
    dbservers:
      hosts:
        db1.example.com:
          ansible_host: 192.168.1.20
          mysql_port: 3306
        db2.example.com:
          ansible_host: 192.168.1.21
          mysql_port: 3306
      vars:
        ansible_user: ansible
        ansible_ssh_private_key_file: ~/.ssh/id_rsa
        ansible_python_interpreter: /usr/bin/python3
        mysql_root_password: secret
    production:
      children:
        webservers:
        dbservers:
    staging:
      children:
        webservers:
        dbservers:
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
    ansible_python_interpreter: /usr/bin/python3
```

### 2.2.3 主机变量文件

```yaml
# host_vars/web1.example.com
---
ansible_host: 192.168.1.10
ansible_port: 2222
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# 主机特定变量
http_port: 80
https_port: 443
document_root: /var/www/html/web1
server_name: web1.example.com

# 主机标签
tags:
  - web
  - production
  - frontend

# 主机配置
nginx:
  worker_processes: 4
  worker_connections: 1024
  keepalive_timeout: 65

# 主机监控
monitoring:
  enabled: true
  metrics_port: 9090
  alerting_enabled: true
```

### 2.2.4 组变量文件

```yaml
# group_vars/webservers.yml
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# Web服务器配置
http_port: 80
https_port: 443
document_root: /var/www/html

# Nginx配置
nginx:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65
  client_max_body_size: 100M

# 应用配置
app:
  name: webapp
  version: 1.0.0
  port: 8080
  environment: production

# 监控配置
monitoring:
  enabled: true
  metrics_port: 9090
  alerting_enabled: true
```

---

## 2.3 动态Inventory

### 2.3.1 动态Inventory脚本

```python
#!/usr/bin/env python3
"""
动态Inventory脚本
支持从外部数据源获取主机信息
"""

import json
import sys
import argparse
from typing import Dict, List, Any

class DynamicInventory:
    """动态Inventory类"""
    
    def __init__(self):
        self.inventory = {
            "_meta": {
                "hostvars": {}
            }
        }
    
    def add_group(self, group_name: str, hosts: List[str] = None, 
                  vars: Dict[str, Any] = None, children: List[str] = None):
        """添加分组"""
        group = {
            "hosts": hosts or [],
            "vars": vars or {},
            "children": children or []
        }
        self.inventory[group_name] = group
    
    def add_host(self, host: str, group: str = None, 
                 vars: Dict[str, Any] = None):
        """添加主机"""
        if group and group in self.inventory:
            self.inventory[group]["hosts"].append(host)
        
        if vars:
            self.inventory["_meta"]["hostvars"][host] = vars
    
    def get_inventory(self) -> Dict[str, Any]:
        """获取Inventory"""
        return self.inventory
    
    def print_inventory(self):
        """打印Inventory"""
        print(json.dumps(self.inventory, indent=2))

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='动态Inventory脚本')
    parser.add_argument('--list', action='store_true', help='列出所有主机')
    parser.add_argument('--host', help='列出指定主机')
    args = parser.parse_args()
    
    inventory = DynamicInventory()
    
    # 添加Web服务器分组
    inventory.add_group(
        group_name="webservers",
        hosts=["web1.example.com", "web2.example.com", "web3.example.com"],
        vars={
            "ansible_user": "ansible",
            "ansible_ssh_private_key_file": "~/.ssh/id_rsa",
            "ansible_python_interpreter": "/usr/bin/python3",
            "http_port": 80,
            "https_port": 443
        }
    )
    
    # 添加数据库服务器分组
    inventory.add_group(
        group_name="dbservers",
        hosts=["db1.example.com", "db2.example.com"],
        vars={
            "ansible_user": "ansible",
            "ansible_ssh_private_key_file": "~/.ssh/id_rsa",
            "ansible_python_interpreter": "/usr/bin/python3",
            "mysql_port": 3306
        }
    )
    
    # 添加生产环境分组
    inventory.add_group(
        group_name="production",
        children=["webservers", "dbservers"]
    )
    
    # 添加主机变量
    inventory.add_host(
        host="web1.example.com",
        vars={
            "ansible_host": "192.168.1.10",
            "ansible_port": 2222
        }
    )
    
    inventory.add_host(
        host="web2.example.com",
        vars={
            "ansible_host": "192.168.1.11",
            "ansible_port": 2222
        }
    )
    
    inventory.add_host(
        host="web3.example.com",
        vars={
            "ansible_host": "192.168.1.12",
            "ansible_port": 2222
        }
    )
    
    inventory.add_host(
        host="db1.example.com",
        vars={
            "ansible_host": "192.168.1.20",
            "ansible_port": 2222
        }
    )
    
    inventory.add_host(
        host="db2.example.com",
        vars={
            "ansible_host": "192.168.1.21",
            "ansible_port": 2222
        }
    )
    
    if args.list:
        inventory.print_inventory()
    elif args.host:
        host_vars = inventory.get_inventory()["_meta"]["hostvars"].get(args.host, {})
        print(json.dumps(host_vars, indent=2))
    else:
        inventory.print_inventory()

if __name__ == "__main__":
    main()
```

### 2.3.2 AWS动态Inventory

```python
#!/usr/bin/env python3
"""
AWS动态Inventory脚本
从AWS EC2获取主机信息
"""

import json
import sys
import argparse
import boto3
from typing import Dict, List, Any

class AWSInventory:
    """AWS Inventory类"""
    
    def __init__(self, region: str = 'us-west-2'):
        self.region = region
        self.ec2 = boto3.client('ec2', region_name=region)
        self.inventory = {
            "_meta": {
                "hostvars": {}
            }
        }
    
    def get_instances(self) -> List[Dict[str, Any]]:
        """获取所有EC2实例"""
        response = self.ec2.describe_instances()
        instances = []
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    instances.append(instance)
        
        return instances
    
    def get_instance_tags(self, instance: Dict[str, Any]) -> Dict[str, str]:
        """获取实例标签"""
        tags = {}
        for tag in instance.get('Tags', []):
            tags[tag['Key']] = tag['Value']
        return tags
    
    def get_instance_ip(self, instance: Dict[str, Any]) -> str:
        """获取实例IP地址"""
        return instance.get('PublicIpAddress') or instance.get('PrivateIpAddress', '')
    
    def build_inventory(self):
        """构建Inventory"""
        instances = self.get_instances()
        
        for instance in instances:
            tags = self.get_instance_tags(instance)
            ip = self.get_instance_ip(instance)
            
            if not ip:
                continue
            
            # 获取组名
            groups = []
            if 'Environment' in tags:
                groups.append(tags['Environment'])
            if 'Role' in tags:
                groups.append(tags['Role'])
            
            # 添加主机到组
            for group in groups:
                if group not in self.inventory:
                    self.inventory[group] = {
                        "hosts": [],
                        "vars": {},
                        "children": []
                    }
                self.inventory[group]["hosts"].append(ip)
            
            # 添加主机变量
            self.inventory["_meta"]["hostvars"][ip] = {
                "ansible_host": ip,
                "ansible_user": "ec2-user",
                "ansible_ssh_private_key_file": "~/.ssh/aws_key.pem",
                "ansible_python_interpreter": "/usr/bin/python3",
                "instance_id": instance['InstanceId'],
                "instance_type": instance['InstanceType'],
                "availability_zone": instance['Placement']['AvailabilityZone']
            }
    
    def print_inventory(self):
        """打印Inventory"""
        print(json.dumps(self.inventory, indent=2))

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='AWS动态Inventory脚本')
    parser.add_argument('--list', action='store_true', help='列出所有主机')
    parser.add_argument('--host', help='列出指定主机')
    parser.add_argument('--region', default='us-west-2', help='AWS区域')
    args = parser.parse_args()
    
    inventory = AWSInventory(region=args.region)
    inventory.build_inventory()
    
    if args.list:
        inventory.print_inventory()
    elif args.host:
        host_vars = inventory.inventory["_meta"]["hostvars"].get(args.host, {})
        print(json.dumps(host_vars, indent=2))
    else:
        inventory.print_inventory()

if __name__ == "__main__":
    main()
```

---

## 2.4 实战：管理Inventory

### 2.4.1 创建静态Inventory

```bash
# 创建静态Inventory

# 创建INI格式Inventory
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

# 查看特定分组
ansible-inventory --graph webservers

# 预期输出：
# @webservers:
#  |--localhost
```

### 2.4.2 创建主机变量文件

```bash
# 创建主机变量文件

# 创建host_vars目录
mkdir -p host_vars

# 创建主机变量文件
cat > host_vars/localhost.yml << 'EOF'
---
ansible_connection: local
ansible_python_interpreter: /usr/bin/python3

# 主机配置
hostname: localhost
timezone: UTC

# 系统配置
system:
  packages:
    - vim
    - git
    - curl
    - wget
  services:
    - name: ssh
      state: started
      enabled: true
    - name: cron
      state: started
      enabled: true

# 用户配置
users:
  - name: ansible
    shell: /bin/bash
    groups:
      - sudo
    ssh_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/..."

# 网络配置
network:
  firewall:
    enabled: true
    rules:
      - port: 22
        protocol: tcp
        state: enabled
      - port: 80
        protocol: tcp
        state: enabled
      - port: 443
        protocol: tcp
        state: enabled
EOF

# 验证主机变量
ansible localhost -m debug -a "var=hostvars[inventory_hostname]"

# 预期输出：
# localhost | SUCCESS => {
#     "hostvars[inventory_hostname]": {
#         "ansible_connection": "local",
#         "ansible_python_interpreter": "/usr/bin/python3",
#         "hostname": "localhost",
#         "timezone": "UTC",
#         "system": {
#             "packages": [
#                 "vim",
#                 "git",
#                 "curl",
#                 "wget"
#             ],
#             "services": [
#                 {
#                     "name": "ssh",
#                     "state": "started",
#                     "enabled": true
#                 },
#                 {
#                     "name": "cron",
#                     "state": "started",
#                     "enabled": true
#                 }
#             ]
#         },
#         "users": [
#             {
#                 "name": "ansible",
#                 "shell": "/bin/bash",
#                 "groups": [
#                     "sudo"
#                 ],
#                 "ssh_keys": [
#                     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/..."
#                 ]
#             }
#         ],
#         "network": {
#             "firewall": {
#                 "enabled": true,
#                 "rules": [
#                     {
#                         "port": 22,
#                         "protocol": "tcp",
#                         "state": "enabled"
#                     },
#                     {
#                         "port": 80,
#                         "protocol": "tcp",
#                         "state": "enabled"
#                     },
#                     {
#                         "port": 443,
#                         "protocol": "tcp",
#                         "state": "enabled"
#                     }
#                 ]
#             }
#         }
#     }
# }
```

### 2.4.3 创建组变量文件

```bash
# 创建组变量文件

# 创建group_vars目录
mkdir -p group_vars

# 创建webservers组变量文件
cat > group_vars/webservers.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# Web服务器配置
http_port: 80
https_port: 443
document_root: /var/www/html

# Nginx配置
nginx:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65
  client_max_body_size: 100M
  server_tokens: off

# 应用配置
app:
  name: webapp
  version: 1.0.0
  port: 8080
  environment: production
  debug: false

# 监控配置
monitoring:
  enabled: true
  metrics_port: 9090
  alerting_enabled: true
  alerting_rules:
    - name: high_cpu
      condition: cpu_usage > 80
      duration: 5m
      severity: warning
    - name: high_memory
      condition: memory_usage > 80
      duration: 5m
      severity: warning

# 日志配置
logging:
  enabled: true
  log_dir: /var/log/webapp
  log_level: info
  log_rotation: true
  log_retention_days: 30
EOF

# 创建dbservers组变量文件
cat > group_vars/dbservers.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# 数据库配置
mysql_port: 3306
mysql_root_password: secret
mysql_database: appdb
mysql_user: appuser
mysql_password: apppass

# MySQL配置
mysql:
  max_connections: 200
  innodb_buffer_pool_size: 1G
  innodb_log_file_size: 256M
  query_cache_size: 64M
  slow_query_log: true
  slow_query_log_file: /var/log/mysql/slow.log
  long_query_time: 2

# 备份配置
backup:
  enabled: true
  backup_dir: /backup/mysql
  backup_schedule: "0 2 * * *"
  backup_retention_days: 7

# 监控配置
monitoring:
  enabled: true
  metrics_port: 9104
  alerting_enabled: true
  alerting_rules:
    - name: high_connections
      condition: connections > 150
      duration: 5m
      severity: warning
    - name: replication_lag
      condition: replication_lag > 60
      duration: 5m
      severity: critical
EOF

# 验证组变量
ansible webservers -m debug -a "var=groups"

# 预期输出：
# localhost | SUCCESS => {
#     "groups": {
#         "all": [
#             "localhost"
#         ],
#         "dbservers": [
#             "localhost"
#         ],
#         "ungrouped": [],
#         "webservers": [
#             "localhost"
#         ]
#     }
# }
```

### 2.4.4 测试Inventory

```bash
# 测试Inventory

# 测试连接
ansible all -m ping

# 预期输出：
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# 测试主机变量
ansible localhost -m debug -a "var=hostvars[inventory_hostname].system"

# 预期输出：
# localhost | SUCCESS => {
#     "hostvars[inventory_hostname].system": {
#         "packages": [
#             "vim",
#             "git",
#             "curl",
#             "wget"
#         ],
#         "services": [
#             {
#                 "name": "ssh",
#                 "state": "started",
#                 "enabled": true
#             },
#             {
#                 "name": "cron",
#                 "state": "started",
#                 "enabled": true
#             }
#         ]
#     }
# }

# 测试组变量
ansible webservers -m debug -a "var=nginx"

# 预期输出：
# localhost | SUCCESS => {
#     "nginx": {
#         "client_max_body_size": "100M",
#         "keepalive_timeout": 65,
#         "server_tokens": false,
#         "worker_connections": 1024,
#         "worker_processes": "auto"
#     }
# }

# 测试Facts
ansible webservers -m setup -a "filter=ansible_distribution*"

# 预期输出：
# localhost | SUCCESS => {
#     "ansible_facts": {
#         "ansible_distribution": "Ubuntu",
#         "ansible_distribution_file_parsed": true,
#         "ansible_distribution_file_path": "/etc/os-release",
#         "ansible_distribution_file_variety": "Ubuntu",
#         "ansible_distribution_major_version": "22",
#         "ansible_distribution_release": "jammy",
#         "ansible_distribution_version": "22.04"
#     },
#     "changed": false
# }
```

---

## 本章小结

- Inventory是Ansible中用于管理被管理主机的配置文件
- Inventory支持主机管理、分组管理、变量管理、动态管理、连接配置
- Inventory数据结构包括主机、分组、变量、连接配置
- 静态Inventory支持INI格式和YAML格式
- 主机变量文件使用host_vars目录，组变量文件使用group_vars目录
- 动态Inventory使用脚本从外部数据源获取主机信息
- 可以使用ansible-inventory命令查看和管理Inventory
- 可以使用ansible命令测试连接、测试变量、测试Facts

---

**下一章：Playbook编写**
