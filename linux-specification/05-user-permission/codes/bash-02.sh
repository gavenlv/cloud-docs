# /etc/passwd - 用户账户信息

cat /etc/passwd | head -5
# root:x:0:0:root:/root:/bin/bash
# daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
# bin:x:2:2:bin:/bin:/usr/sbin/nologin
# user:x:1000:1000:user,,,:/home/user:/bin/bash

# 字段说明:
# 用户名:密码占位符:UID:GID:用户信息:主目录:登录Shell
#
# UID范围:
# 0         - root (超级用户)
# 1-999     - 系统用户 (daemon, bin, www-data等)
# 1000+     - 普通用户
# 65534     - nobody (用于NFS等)

# UID与用户名映射
getent passwd
getent passwd username