创建开发用户：
sudo useradd -m -s /bin/bash devuser
sudo passwd devuser
sudo usermod -aG sudo devuser

创建项目目录：
sudo mkdir /projects
sudo chown devuser:devuser /projects
sudo chmod 750 /projects