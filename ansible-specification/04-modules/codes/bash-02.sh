# 创建使用包管理模块的Playbook

# 创建Playbook文件
cat > playbook-package-modules.yml << 'EOF'
---
- name: 使用包管理模块的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 更新系统包
      apt:
        update_cache: yes
        cache_valid_time: 3600
      changed_when: false
    
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
    
    - name: 显示安装状态
      debug:
        msg: "Nginx安装状态: {{ nginx_install.changed }}"
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: 检查Nginx版本
      command: nginx -v
      register: nginx_version
      changed_when: false
      failed_when: false
    
    - name: 显示Nginx版本
      debug:
        msg: "Nginx版本: {{ nginx_version.stderr }}"
EOF

# 运行Playbook
ansible-playbook playbook-package-modules.yml

# 预期输出：
# PLAY [使用包管理模块的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [更新系统包] ********************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [显示安装状态] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装状态: true"
# }
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [检查Nginx版本] ****************************************************
# ok: [localhost]
# TASK [显示Nginx版本] ****************************************************
# ok: [localhost] => {
#     "msg": "Nginx版本: nginx version: nginx/1.18.0"
# }
# PLAY RECAP **************************************************************
# localhost: ok=6    changed=2    unreachable=0    failed=0