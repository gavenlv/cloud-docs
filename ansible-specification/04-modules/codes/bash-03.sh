# 创建使用服务模块的Playbook

# 创建Playbook文件
cat > playbook-service-modules.yml << 'EOF'
---
- name: 使用服务模块的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    
    - name: 启动Nginx服务
      service:
        name: nginx
        state: started
        enabled: yes
      register: nginx_service
    
    - name: 显示服务状态
      debug:
        msg: "Nginx服务状态: {{ nginx_service.status.ActiveState }}"
    
    - name: 检查Nginx服务
      service:
        name: nginx
        state: started
      register: nginx_check
    
    - name: 显示检查结果
      debug:
        msg: "Nginx服务检查结果: {{ nginx_check.status.ActiveState }}"
    
    - name: 重新加载Nginx服务
      service:
        name: nginx
        state: reloaded
    
    - name: 重启Nginx服务
      service:
        name: nginx
        state: restarted
EOF

# 运行Playbook
ansible-playbook playbook-service-modules.yml

# 预期输出：
# PLAY [使用服务模块的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [显示服务状态] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务状态: active"
# }
# TASK [检查Nginx服务] ****************************************************
# ok: [localhost]
# TASK [显示检查结果] *****************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务检查结果: active"
# }
# TASK [重新加载Nginx服务] ************************************************
# changed: [localhost]
# TASK [重启Nginx服务] ****************************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=4    unreachable=0    failed=0