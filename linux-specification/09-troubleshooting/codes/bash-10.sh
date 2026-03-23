# 1. 检查Shell
cat /etc/passwd | grep username
chsh -s /bin/bash username

# 2. 检查密码
passwd username

# 3. 检查pam配置
auth.log | grep username