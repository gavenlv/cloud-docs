# 创建主Playbook

# 创建Playbook文件
cat > ansible-project/playbooks/site.yml << 'EOF'
---
# 主Playbook
# 作者：Ansible User
# 描述：配置所有服务器

- name: 配置所有服务器
  hosts: all
  become: true
  vars_files:
    - ../group_vars/all.yml
  pre_tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags:
        - always

- name: 配置Web服务器
  import_playbook: webservers.yml

- name: 配置数据库服务器
  import_playbook: dbservers.yml
EOF

# 创建Web服务器Playbook
cat > ansible-project/playbooks/webservers.yml << 'EOF'
---
# Web服务器Playbook
# 作者：Ansible User
# 描述：配置Web服务器

- name: 配置Web服务器
  hosts: webservers
  become: true
  vars_files:
    - ../group_vars/webservers.yml
  roles:
    - role: nginx
      tags:
        - nginx
    - role: app
      tags:
        - app
EOF

# 创建数据库服务器Playbook
cat > ansible-project/playbooks/dbservers.yml << 'EOF'
---
# 数据库服务器Playbook
# 作者：Ansible User
# 描述：配置数据库服务器

- name: 配置数据库服务器
  hosts: dbservers
  become: true
  vars_files:
    - ../group_vars/dbservers.yml
  roles:
    - role: mysql
      tags:
        - mysql
EOF

# 验证Playbook
cat ansible-project/playbooks/site.yml
cat ansible-project/playbooks/webservers.yml
cat ansible-project/playbooks/dbservers.yml