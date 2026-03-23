# 配置Ansible

# 创建配置目录
mkdir -p ~/.ansible

# 创建配置文件
cat > ~/.ansible/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
forks = 5
timeout = 30
display_skipped_hosts = False
display_ok_hosts = True
log_path = /var/log/ansible.log

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[colors]
highlight = white
verbose = blue
warn = bright purple
error = red
debug = dark gray
deprecate = purple
skip = cyan
unreachable = red
ok = green
changed = yellow
diff_add = green
diff_remove = red
diff_lines = cyan
EOF

# 验证配置
ansible --version

# 预期输出：
# ansible [core 2.15.0]
#   config file = /home/user/.ansible/ansible.cfg
#   configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
#   ansible python module location = /usr/local/lib/python3.10/site-packages/ansible
#   ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
#   executable location = /usr/local/bin/ansible
#   python version = 3.10.12
#   jinja version = 3.1.2
#   libyaml = True