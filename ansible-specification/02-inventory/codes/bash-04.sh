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