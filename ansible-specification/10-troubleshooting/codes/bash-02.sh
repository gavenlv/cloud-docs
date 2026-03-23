# 使用检查模式

# 基本检查模式
ansible-playbook playbook.yml --check

# 检查模式 + 详细输出
ansible-playbook playbook.yml --check -v

# 检查模式 + 差异输出
ansible-playbook playbook.yml --check --diff

# 检查模式 + 跳过标签
ansible-playbook playbook.yml --check --skip-tags install