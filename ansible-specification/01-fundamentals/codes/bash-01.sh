# 安装Ansible

# 方法1：使用包管理器安装

# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# CentOS/RHEL
sudo yum install ansible

# 方法2：使用pip安装
pip install ansible

# 方法3：使用虚拟环境安装
python3 -m venv ansible-env
source ansible-env/bin/activate
pip install ansible

# 验证安装
ansible --version

# 预期输出：
# ansible [core 2.15.0]
#   config file = None
#   configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
#   ansible python module location = /usr/local/lib/python3.10/site-packages/ansible
#   ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
#   executable location = /usr/local/bin/ansible
#   python version = 3.10.12
#   jinja version = 3.1.2
#   libyaml = True