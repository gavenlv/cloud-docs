# 在Ubuntu/Debian上安装

# 1. 添加Jenkins仓库
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# 2. 安装
sudo apt-get update
sudo apt-get install jenkins

# 3. 启动服务
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 4. 查看状态
sudo systemctl status jenkins

# 5. 访问
# http://your_server:8080

# 配置文件位置:
# /etc/default/jenkins          # 配置参数
# /var/lib/jenkins/             # 主目录 (Home)
# /var/log/jenkins/             # 日志