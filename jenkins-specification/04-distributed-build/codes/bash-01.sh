# 1. 在Agent上安装Java
sudo apt update
sudo apt install openjdk-11-jdk

# 2. 创建jenkins用户
sudo useradd -m -s /bin/bash jenkins
sudo mkdir -p /home/jenkins
sudo chown jenkins:jenkins /home/jenkins

# 3. 生成SSH密钥对 (在Master上)
ssh-keygen -t rsa -b 4096 -C "jenkins@master" -f ~/.ssh/jenkins_agent
ssh-copy-id -i ~/.ssh/jenkins_agent.pub jenkins@agent-ip

# 4. 测试SSH连接
ssh -i ~/.ssh/jenkins_agent jenkins@agent-ip