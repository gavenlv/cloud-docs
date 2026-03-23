# 创建用户
useradd -m username                  # 创建用户并创建主目录
useradd -m -s /bin/bash username    # 指定登录Shell
useradd -m -u 1500 username         # 指定UID
useradd -m -g groupname username     # 指定主组
useradd -m -G group1,group2 username # 指定附加组
useradd -m -d /custom/home username  # 指定主目录

# 交互式创建 (Debian)
adduser username

# 修改用户
usermod -l newname oldname          # 修改用户名
usermod -u 1500 username             # 修改UID
usermod -g groupname username        # 修改主组
usermod -G group1,group2 username   # 修改附加组 (覆盖)
usermod -aG groupname username       # 添加附加组 (追加)
usermod -s /bin/zsh username        # 修改登录Shell
usermod -d /new/home username       # 修改主目录
usermod -L username                 # 锁定账户
usermod -U username                 # 解锁账户

# 设置/修改密码
passwd username                     # 交互式修改密码
echo "password" | passwd --stdin username  # 非交互式 (CentOS)
sudo chpasswd                       # 批量修改密码

# 删除用户
userdel username                    # 删除用户(保留主目录)
userdel -r username                 # 删除用户并删除主目录

# 查看用户信息
id username
finger username
getent passwd username