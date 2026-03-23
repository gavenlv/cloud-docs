# 用户和权限管理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux权限模型的**底层原理**（用户/组/进程关系）
- 掌握用户和组的创建、修改、删除操作
- 熟练使用chmod/chown/chgrp管理文件权限
- 理解SUID/SGID/Sticky Bit的特殊权限
- 理解PAM可插拔认证模块机制
- 从**内核角度**理解权限检查是如何进行的

**学习方法：**

```
权限模型 → 用户管理 → 组管理 → 文件权限 → 特殊权限 → PAM → 实战操作
```

---

# 1. Linux权限模型

## 1.1 权限检查原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux权限检查流程                              │
└─────────────────────────────────────────────────────────────────┘

当进程访问文件时:

1. 获取进程的有效用户ID (euid) 和有效组ID (egid)
2. 获取文件的UID和GID
3. 检查权限:

┌─────────────────────────────────────────────────────────────────┐
│                    权限检查逻辑                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────┐     ┌─────────┐     ┌─────────┐
│ euid=0  │────►│  root   │────►│  允许   │  (root用户绕过所有检查)
└─────────┘     └─────────┘     └─────────┘
     │
     │ no
     ▼
┌─────────┐     ┌─────────┐     ┌─────────┐
│ euid=   │────►│ 文件UID │────►│  Owner? │──yes──► 检查Owner权限
│ 文件UID │yes  └─────────┘     └─────────┘
└─────────┘                         │
     │ no                           │ no
     ▼                             ▼
┌─────────┐     ┌─────────┐     ┌─────────┐
│ egid in │────►│ 文件GID │────►│  Group? │──yes──► 检查Group权限
│ 文件GIDs│yes  └─────────┘     └─────────┘
└─────────┘                         │
     │ no                           │ no
     ▼                             ▼
                         检查Other权限

# 权限位检查:
# 进程请求操作 (r/w/x)
# 进程属于owner → 检查owner位
# 进程属于group → 检查group位
# 其他情况     → 检查other位
```

## 1.2 进程与用户的关系

```bash
# 进程的用户身份

# 查看当前进程的用户信息
id
# uid=1000(user) gid=1000(user) groups=1000(user),4(adm),27(sudo)

# 查看进程的有效/实际用户
cat /proc/self/status | grep -E "^(Uid|Gid)"
# Uid:    1000    1000    1000    1000   (实际/有效/保存 set/文件系统)
# Gid:    1000    1000    1000    1000

# 有效用户 vs 实际用户
# 实际用户 (ruid): 登录时的用户
# 有效用户 (euid): 当前使用的用户身份 (用于权限检查)
# 保存的用户 (suid): 保存的用户ID (用于切换回原用户)
# 文件系统用户 (fsuid): 用于文件系统操作

# 示例: sudo
cat > check_ids.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("UID:  real=%d, effective=%d, saved=%d\n",
           getuid(), geteuid(), getuid());
    printf("GID:  real=%d, effective=%d, saved=%d\n",
           getgid(), getegid(), getgid());
    return 0;
}
EOF

gcc check_ids.c -o check_ids
./check_ids
sudo ./check_ids
# UID:  real=1000, effective=1000, saved=1000
# UID:  real=0, effective=0, saved=1000  <- sudo提升了euid
```

---

# 2. 用户管理

## 2.1 用户账户结构

```bash
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
```

## 2.2 用户操作

```bash
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
```

## 2.3 用户密码管理

```bash
# /etc/shadow - 用户密码信息

cat /etc/shadow | head -5
# root:$6$salthash$:17650:0:99999:7:::
# user:$6$salthash$:18150:0:99999:7:::
# daemon:*:17985:0:99999:7:::

# 字段说明:
# 用户名:加密密码:最后修改日期:最小天数:最大天数:警告期:宽限期:失效期:保留
#
# 密码字段特殊值:
# *        - 账户禁用
# !        - 账户锁定
# !!       - 从未设置密码
# 空       - 无密码登录

# 密码时效管理
# 设置密码有效期
passwd -x 90 username              # 密码90天后过期
passwd -n 7 username               # 密码至少使用7天
passwd -w 7 username               # 提前7天警告
passwd -i 30 username              # 过期30天后禁用

# 查看密码状态
passwd -S username
# username P 03/21/2026 0 90 7 30
# 状态: P=有密码, NP=无密码, L=锁定

# 强制用户修改密码
chage -d 0 username                # 下次登录强制修改
chage -E 2026-12-31 username      # 设置账户过期日期
```

---

# 3. 组管理

## 3.1 组账户结构

```bash
# /etc/group - 组账户信息

cat /etc/group | head -5
# root:x:0:
# daemon:x:1:
# bin:x:2:
# sys:x:3:
# user:x:1000:user1,user2

# 字段说明:
# 组名:密码占位符:GID:成员列表(逗号分隔)

# 查看组
getent group
getent group groupname
groups username                     # 用户所属的组
groupmems -g groupname -l          # 组成员列表
```

## 3.2 组操作

```bash
# 创建组
groupadd groupname                  # 创建组
groupadd -g 1500 groupname         # 指定GID

# 修改组
groupmod -n newname oldname        # 修改组名
groupmod -g 1500 groupname         # 修改GID

# 删除组
groupdel groupname

# 管理组成员
gpasswd -a user groupname          # 添加成员
gpasswd -d user groupname          # 删除成员
gpasswd -A user groupname          # 设置管理员
gpasswd -M user1,user2 groupname   # 设置所有成员(覆盖)

# groups命令
groups                              # 当前用户的组
groups username                     # 指定用户的组
```

---

# 4. 文件权限管理

## 4.1 权限表示方法

```bash
# 权限表示: rwx (读写执行)

# 字符表示
# r = 4 (可读)
# w = 2 (可写)
# x = 1 (可执行)
# - = 0 (无权限)

# 数字表示
# 7 = rwx (4+2+1)
# 6 = rw- (4+2)
# 5 = r-x (4+1)
# 4 = r-- (4)
# 3 = -wx (2+1)
# 2 = -w- (2)
# 1 = --x (1)
# 0 = --- (0)

# 示例:
chmod 755 file        # rwxr-xr-x
chmod 644 file        # rw-r--r--
chmod 700 file        # rwx------
chmod 600 file        # rw-------
chmod 750 dir         # rwxr-x---
```

## 4.2 chmod - 修改权限

```bash
# 符号方式
chmod u+x file                # owner添加执行权限
chmod g-x file                # group移除执行权限
chmod o+r file                # others添加读取权限
chmod a+x file                # 所有用户添加执行权限
chmod +x file                 # 同a+x

# 组合
chmod u+rwx,g+rx,o+r file    # rwxr-xr--
chmod u=rw,g=r,o= file        # rw-r-----

# 移除所有权限
chmod a-rwx file
chmod = file                   # 清空所有权限

# 递归修改
chmod -R 755 /path/to/dir

# 参考另一个文件的权限
chmod --reference=file1 file2

# 权限组合示例
chmod 1777 /tmp                # 1777 = rwsrwxrwt (Sticky Bit)
chmod 2755 /path               # 2755 = rwxr-sr-x (SGID)
chmod 4755 /path               # 4755 = rwsr-xr-x (SUID)
```

## 4.3 chown/chgrp - 修改所有者

```bash
# chown - 修改文件所有者

chown user file                 # 修改owner
chown user:group file          # 修改owner和group
chown :group file              # 只修改group (等价于chgrp)
chown -R user:group /path      # 递归修改

# 参考另一个文件
chown --reference=file1 file2

# 常用示例
chown -R www-data:www-data /var/www
chown root:root /etc/shadow
chown $USER:$USER ~/.ssh/*

# chgrp - 修改组所有权 (简写)
chgrp group file
chgrp -R group /path
```

---

# 5. 特殊权限

## 5.1 SUID (Set User ID)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SUID 特殊权限                                  │
└─────────────────────────────────────────────────────────────────┘

# 原理:
# - 文件有SUID位时,执行该文件的用户获得文件owner的身份
# - 常用于需要临时提升权限的程序 (如passwd, sudo)

# 示例: passwd命令
ls -l /usr/bin/passwd
# -rwsr-xr-x 1 root root 52256 ... /usr/bin/passwd
#            ^
#            | SUID位 (s代替x表示SUID)

# 执行流程:
# 1. 普通用户执行passwd
# 2. 进程的euid变成root (文件owner)
# 3. 可以写入/etc/shadow
# 4. 进程结束后恢复原用户身份

# 设置SUID
chmod u+s file
chmod 4755 file

# 移除SUID
chmod u-s file
chmod 0755 file
```

## 5.2 SGID (Set Group ID)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SGID 特殊权限                                  │
└─────────────────────────────────────────────────────────────────┘

# 文件SGID:
# - 执行时获得文件group的身份

# 目录SGID:
# - 目录下创建的文件继承目录的group
# - 常用于共享目录

# 示例: /usr/local/share
ls -ld /usr/local/share
# drwxrws--- 2 staff team 4096 ... /usr/local/share
#         ^
#         | SGID (s代替x表示SGID)

# 目录内创建文件:
touch /usr/local/share/newfile
ls -l /usr/local/share/newfile
# -rw-r--r-- 1 user team 0 ... /usr/local/share/newfile
#            ^
#            | 继承team组

# 设置SGID
chmod g+s /path
chmod 2755 /path

# 移除SGID
chmod g-s /path
```

## 5.3 Sticky Bit

```
┌─────────────────────────────────────────────────────────────────┐
│                    Sticky Bit                                   │
└─────────────────────────────────────────────────────────────────┘

# 原理:
# - 目录有Sticky Bit时,用户只能删除自己的文件
# - 不能删除/重命名他人的文件
# - 常用于/tmp目录

# 示例: /tmp
ls -ld /tmp
# drwxrwxrwt 10 root root 4096 ... /tmp
#          ^
#          | Sticky Bit (t代替x表示)

# 不带Sticky Bit的目录:
# 用户A可以删除用户B创建的文件

# 带Sticky Bit的目录:
# 用户A只能删除自己创建的文件

# 设置Sticky Bit
chmod +t /path
chmod 1777 /path

# 移除Sticky Bit
chmod -t /path
chmod 0777 /path
```

## 5.4 特殊权限组合

```bash
# 完整权限示例

# SUID + owner(rwx) + SGID + group(rx) + Sticky + other(rx)
chmod 5755 file       # SUID设置
ls -l file
# -rwsr-xr-x ...  <- SUID (s), others的x是执行

# SGID + group(rwx) + Sticky + other(rx)
chmod 3755 file       # SGID设置
ls -l file
# -rwxr-sr-x ...  <- SGID (s)

# SUID + SGID + Sticky
chmod 7755 file
ls -l file
# -rwsr-sr-t ...  <- SUID (s), SGID (s), Sticky (t)

# 查看特殊权限
stat file | grep Access
# Access: (4755/-rwsr-xr-x)
```

---

# 6. PAM可插拔认证模块

## 6.1 PAM架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    PAM 架构                                      │
└─────────────────────────────────────────────────────────────────┘

应用程序                      PAM库 (libpam)
    │                              │
    │  pam_start()                 │
    ├─────────────────────────────►│
    │                              │
    │  pam_authenticate()          │
    ├─────────────────────────────►│
    │                              ├──► /etc/pam.d/system-auth
    │                              │     ├──► pam_unix.so      (本地密码)
    │                              │     ├──► pam_krb5.so      (Kerberos)
    │                              │     ├──► pam_ldap.so      (LDAP)
    │                              │     └──► pam_ecryptfs.so  (加密)
    │◄──────────────────────────────┤
    │                              │
    │  pam_acct_mgmt()             │
    ├─────────────────────────────►│
    │                              ├──► /etc/pam.d/system-auth
    │                              │     └──► 检查账户状态
    │◄──────────────────────────────┤
```

## 6.2 PAM配置文件

```bash
# /etc/pam.d/ - PAM配置文件

# 查看PAM配置
ls /etc/pam.d/
# atd                cron               login
# other              passwd             sshd
# system-auth        system-login       systemd-user

# system-auth (CentOS/RHEL)
cat /etc/pam.d/system-auth
# auth        required      pam_env.so
# auth        required      pam_faildelay.so delay=2000000
# auth        sufficient    pam_unix.so nullok try_first_pass
# auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
# auth        required      pam_deny.so

# account     required      pam_unix.so
# account     sufficient    pam_localuser.so
# account     sufficient    pam_succeed_if.so uid < 1000 quiet
# account     required      pam_permit.so

# password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
# password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
# password    required      pam_deny.so

# session     optional      pam_keyinit.so revoke
# session     required      pam_limits.so
# session     optional      pam_unix.so
# session     optional      pam_systemd.so

# PAM控制标记:
# required    - 必须成功,失败继续但最终返回失败
# requisite   - 必须成功,失败立即返回失败
# sufficient  - 成功则足够,忽略后续模块
# optional    - 结果可忽略
# include     - 包含其他配置文件
```

## 6.3 PAM配置示例

```bash
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
```

---

# 7. sudo配置

## 7.1 sudo原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    sudo 工作原理                                 │
└─────────────────────────────────────────────────────────────────┘

1. 用户执行sudo command
2. sudo检查/etc/sudoers配置文件
3. 如果允许:
   - 提升euid为root (或指定用户)
   - 执行command
   - 记录到日志
4. 如果不允许:
   - 拒绝执行

# sudoers配置语法:
# who  host = (runas) commands
# 用户  主机=(用户:组) 命令
```

## 7.2 sudoers配置

```bash
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
```

## 7.3 sudo操作

```bash
# 常用sudo命令
sudo -l                        # 查看当前用户sudo权限
sudo -u user command           # 以指定用户执行
sudo -u user -g group command # 以指定用户和组执行
sudo -i                        # 切换到root shell
sudo -s                        # 切换到root shell (不加载完整环境)

# 编辑sudoers (建议使用visudo)
sudo visudo                     # 编辑sudoers
sudo visudo -f /etc/sudoers.d/custom  # 编辑自定义文件

# sudo日志
cat /var/log/auth.log | grep sudo  # Debian/Ubuntu
cat /var/log/secure               # CentOS/RHEL
```

---

# 8. 权限管理实战

## 8.1 常见权限场景

```bash
# 场景1: Web服务器目录权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
# 上传目录需要可写
sudo chmod 775 /var/www/html/uploads

# 场景2: SSH密钥权限
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 场景3: 数据库数据目录
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod 700 /var/lib/mysql
sudo chmod 660 /var/lib/mysql/*.ibd

# 场景4: 共享目录 (使用SGID保证组继承)
sudo groupadd team
sudo usermod -aG team user1
sudo usermod -aG team user2
sudo mkdir /shared
sudo chgrp team /shared
sudo chmod 2775 /shared  # SGID + rwxrwxr-x
# 现在team成员创建的文件都继承team组
```

## 8.2 权限检查和修复

```bash
# 检查权限问题
ls -la /problematic/path

# 找出权限过于宽松的文件
find /home -perm -777 -type f 2>/dev/null

# 找出没有owner的文件
find / -nouser -o -nogroup 2>/dev/null

# 修复常见权限问题
# /tmp目录
chmod 1777 /tmp

# /var/tmp
chmod 1777 /var/tmp

# /home目录
chmod 755 /home
chmod 700 /home/username

# SSH配置
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 644 /etc/ssh/ssh_host_rsa_key.pub
```

---

## 本章小结

- **Linux权限模型**基于用户/组/其他(UGO)的读写执行权限
- **UID/GID**是用户和组的唯一标识符
- **文件权限**由10个字符表示,包括特殊权限位(SUID/SGID/Sticky)
- **SUID**让程序以owner身份运行,**SGID**让程序以group身份运行
- **Sticky Bit**保护共享目录中的文件不被他人删除
- **PAM**提供可插拔的认证模块,支持多种认证方式
- **sudo**允许普通用户以root权限执行特定命令
- **/etc/passwd, /etc/shadow, /etc/group**是用户/密码/组信息存储文件

**关键命令回顾:**

```bash
# 用户管理
useradd, usermod, userdel, passwd, id, chage

# 组管理
groupadd, groupmod, groupdel, gpasswd

# 权限管理
chmod, chown, chgrp

# 查看
getent passwd, getent group, groups, id

# sudo
sudo -l, visudo, sudo -i
```