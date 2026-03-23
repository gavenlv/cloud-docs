# 创建处理连接错误的Playbook

# 创建Playbook文件
cat > playbook-connection-errors.yml << 'EOF'
---
- name: 处理连接错误的Playbook示例
  hosts: webservers
  become: true
  vars:
    ansible_ssh_timeout: 60
    ansible_ssh_retries: 3
  tasks:
    - name: 测试SSH连接
      wait_for:
        host: "{{ ansible_host }}"
        port: "{{ ansible_port | default(22) }}"
        timeout: "{{ ansible_ssh_timeout }}"
      delegate_to: localhost
      register: ssh_connection
    
    - name: 显示SSH连接结果
      debug:
        msg: "SSH连接结果: {{ ssh_connection }}"
    
    - name: 测试SSH认证
      command: ssh -o ConnectTimeout={{ ansible_ssh_timeout }} -o StrictHostKeyChecking=no {{ ansible_user }}@{{ ansible_host }} echo "SSH认证成功"
      register: ssh_auth
      changed_when: false
      failed_when: false
    
    - name: 显示SSH认证结果
      debug:
        msg: "SSH认证结果: {{ ssh_auth }}"
    
    - name: 安装Nginx（带重试）
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
      retries: 3
      delay: 5
      until: nginx_install is succeeded
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
EOF

# 运行Playbook
ansible-playbook playbook-connection-errors.yml

# 预期输出：
# PLAY [处理连接错误的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [测试SSH连接] *****************************************************
# ok: [localhost]
# TASK [显示SSH连接结果] *********************************************
# ok: [localhost] => {
#     "msg": "SSH连接结果: {\"changed\": false, \"elapsed\": 0, \"failed\": false, \"match_groupdict\": {}, \"msg\": \"All items completed\", \"path\": null, \"port\": 22, \"search_regex\": null, \"state\": \"started\"}"
# }
# TASK [测试SSH认证] *****************************************************
# ok: [localhost]
# TASK [显示SSH认证结果] *********************************************
# ok: [localhost] => {
#     "msg": "SSH认证结果: {\"changed\": false, \"cmd\": [\"ssh\", \"-o\", \"ConnectTimeout=60\", \"-o\", \"StrictHostKeyChecking=no\", \"ansible@localhost\", \"echo\", \"SSH认证成功\"], \"delta\": \"0:00:00.123456\", \"end\": \"2024-01-15 10:00:00.123456\", \"failed\": false, \"rc\": 0, \"start\": \"2024-01-15 10:00:00.000000\", \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"SSH认证成功\", \"stdout_lines\": [\"SSH认证成功\"]}"
# }
# TASK [安装Nginx（带重试）] *******************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\\nNeed to get 0 B/1,234 kB of archives.\\nAfter this operation, 5,678 kB of additional disk space will be used.\\nSelecting previously unselected package nginx.\\n(Reading database ... 123456 files and directories currently installed.)\\nPreparing to unpack .../nginx_1.18.0-0ubuntu1_amd64.deb ...\\nUnpacking nginx (1.18.0-0ubuntu1) ...\\nSetting up nginx (1.18.0-0ubuntu1) ...\\nProcessing triggers for ufw (0.36.1-0ubuntu0.20.04.1) ...\\nProcessing triggers for systemd (245.4-4ubuntu3.13) ...\\nProcessing triggers for man-db (2.9.1-1) ...\\n\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"Need to get 0 B/1,234 kB of archives.\", \"After this operation, 5,678 kB of additional disk space will be used.\", \"Selecting previously unselected package nginx.\", \"(Reading database ... 123456 files and directories currently installed.)\", \"Preparing to unpack .../nginx_1.18.0-0ubuntu1_amd64.deb ...\", \"Unpacking nginx (1.18.0-0ubuntu1) ...\", \"Setting up nginx (1.18.0-0ubuntu1) ...\", \"Processing triggers for ufw (0.36.1-0ubuntu0.20.04.1) ...\", \"Processing triggers for systemd (245.4-4ubuntu3.13) ...\", \"Processing triggers for man-db (2.9.1-1) ...\"]}"
# }
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=1    unreachable=0    failed=0