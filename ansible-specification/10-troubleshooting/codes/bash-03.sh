# 使用单步执行

# 单步执行模式
ansible-playbook playbook.yml --step

# 单步执行 + 详细输出
ansible-playbook playbook.yml --step -v

# 单步执行 + 检查模式
ansible-playbook playbook.yml --step --check