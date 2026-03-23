# 创建使用文件模块的Playbook

# 创建Playbook文件
cat > playbook-file-modules.yml << 'EOF'
---
- name: 使用文件模块的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 创建目录
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
    
    - name: 创建文件
      file:
        path: /var/www/html/index.html
        state: touch
        owner: www-data
        group: www-data
        mode: '0644'
    
    - name: 创建符号链接
      file:
        src: /var/www/html
        dest: /var/www
        state: link
    
    - name: 获取文件信息
      stat:
        path: /var/www/html/index.html
      register: file_info
    
    - name: 显示文件信息
      debug:
        msg:
          - "文件路径: {{ file_info.stat.path }}"
          - "文件大小: {{ file_info.stat.size }} 字节"
          - "文件权限: {{ file_info.stat.mode }}"
          - "文件所有者: {{ file_info.stat.pw_name }}"
          - "文件组: {{ file_info.stat.gr_name }}"
EOF

# 运行Playbook
ansible-playbook playbook-file-modules.yml

# 预期输出：
# PLAY [使用文件模块的Playbook示例] ************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [创建目录] ********************************************************
# changed: [localhost]
# TASK [创建文件] ********************************************************
# changed: [localhost]
# TASK [创建符号链接] ****************************************************
# changed: [localhost]
# TASK [获取文件信息] ****************************************************
# ok: [localhost]
# TASK [显示文件信息] ****************************************************
# ok: [localhost] => {
#     "msg": [
#         "文件路径: /var/www/html/index.html",
#         "文件大小: 0 字节",
#         "文件权限: 0644",
#         "文件所有者: www-data",
#         "文件组: www-data"
#     ]
# }
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=3    unreachable=0    failed=0