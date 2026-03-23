# 创建简单Playbook

# 创建Playbook文件
cat > playbook-simple.yml << 'EOF'
---
- name: 简单Playbook示例
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
    
    - name: 创建文档根目录
      file:
        path: /var/www/html
        state: directory
        mode: '0755'
    
    - name: 创建首页文件
      copy:
        content: "Hello, World!"
        dest: /var/www/html/index.html
        mode: '0644'
EOF

# 运行Playbook
ansible-playbook playbook-simple.yml

# 预期输出：
# PLAY [简单Playbook示例] **************************************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx] ********************************************************
# changed: [localhost]
# TASK [启动Nginx服务] ****************************************************
# changed: [localhost]
# TASK [创建文档根目录] ***************************************************
# changed: [localhost]
# TASK [创建首页文件] *****************************************************
# changed: [localhost]
# PLAY RECAP **************************************************************
# localhost: ok=5    changed=4    unreachable=0    failed=0