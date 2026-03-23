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