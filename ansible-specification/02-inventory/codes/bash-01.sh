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