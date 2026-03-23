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