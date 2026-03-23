# /etc/sudoers - sudo配置文件

# 基础语法
# user    ALL=(ALL:ALL)    ALL

# 字段说明:
# user    - 用户名或%组名
# ALL     - 允许来自任何主机
# (ALL:ALL) - 可以作为任何用户:任何组运行
# ALL     - 允许执行任何命令

# 常用配置示例

# 允许user执行所有命令
user    ALL=(ALL:ALL)    ALL

# 允许user无密码执行特定命令
user    ALL=(root)       NOPASSWD: /usr/bin/systemctl restart nginx

# 允许user作为mysql用户执行命令
user    ALL=(mysql:)     /usr/bin/mysql, /usr/bin/mysqldump

# 允许wheel组无密码sudo
%wheel  ALL=(ALL:ALL)    NOPASSWD: ALL

# 允许user从特定IP登录时sudo
user    192.168.1.100=(ALL:ALL)    ALL

# 设置默认选项
Defaults    !authenticate     # 禁用密码验证
Defaults    logfile=/var/log/sudo.log   # 日志文件
Defaults    timestamp_timeout=30  # 密码缓存时间(分钟)

# 别名定义
User_Alias ADMINS = user1, user2
Host_Alias SERVERS = server1, server2
Cmnd_Alias COMMANDS = /usr/bin/systemctl, /usr/bin/service

ADMINS SERVERS=(ALL) COMMANDS