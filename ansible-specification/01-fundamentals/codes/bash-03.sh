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