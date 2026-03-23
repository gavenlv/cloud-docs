# 自定义PAM模块限制用户登录

# 禁止用户登录Shell
usermod -s /usr/sbin/nologin username
# 或
usermod -s /bin/false username

# 限制root SSH登录
# 编辑 /etc/ssh/sshd_config
# PermitRootLogin no

# 限制用户SSH登录
# 编辑 /etc/ssh/sshd_config
# AllowUsers user1 user2
# DenyUsers user3

# 创建PAM规则限制失败次数
# 编辑 /etc/pam.d/login 或 /etc/pam.d/sshd
# 添加:
# auth required pam_tally2.so deny=3 unlock_time=600

# 查看登录失败计数
pam_tally2 --user username
pam_tally2 --user username --reset