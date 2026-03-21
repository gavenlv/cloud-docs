# Linux常见错误处理

## 本章导学

**学完本章后，你将能够：**

- 掌握Linux常见错误的**诊断和解决方法**
- 熟练使用诊断工具定位问题
- 理解系统各组件的排错思路
- 从**实战角度**快速解决实际问题

**学习方法：**

```
问题现象 → 诊断思路 → 排查命令 → 解决方案 → 预防措施
```

---

# 1. 系统启动问题

## 1.1 启动失败

```bash
# 1. 忘记root密码
# 解决: 进入单用户模式重置密码

# Grub菜单按e编辑
# 找到 linux 行的末尾
# 添加: init=/bin/bash
# 按Ctrl+x启动
# 挂载根文件系统
mount -o remount,rw /
# 修改密码
passwd root
# 重启
exec /sbin/init

# 2. 修复Grub
# 使用Live CD启动
# 挂载系统分区
mount /dev/sda1 /mnt
# 重新安装Grub
grub-install --root-directory=/mnt /dev/sda

# 3. 文件系统损坏
# 检查并修复
fsck /dev/sda1
fsck.ext4 -p /dev/sda1  # 自动修复

# 4. 查看启动日志
journalctl -b -1          # 上次启动日志
dmesg | grep -i error
cat /var/log/boot.log
```

## 1.2 服务启动失败

```bash
# 查看服务状态
systemctl status nginx

# 查看详细日志
journalctl -u nginx -n 50
journalctl -u nginx --since "10 minutes ago"

# 检查配置
nginx -t

# 检查依赖
systemctl list-dependencies nginx
systemctl --failed

# 手动启动调试
/usr/sbin/nginx -g 'daemon off;' &
```

---

# 2. 网络问题

## 2.1 网络连接故障

```bash
# 1. 接口未启用
ip link show
ip link set eth0 up
ip addr show eth0

# 2. DHCP获取IP失败
dhclient -r eth0          # 释放
dhclient eth0             # 重新获取

# 3. DNS解析失败
cat /etc/resolv.conf
ping -c 2 8.8.8.8        # 测试网络
ping -c 2 google.com       # 测试DNS

# 4. 路由问题
ip route show
ip route get 8.8.8.8

# 5. 防火墙阻止
iptables -L -n
iptables -L -n -t nat
```

## 2.2 网络性能问题

```bash
# 1. 查看连接状态
ss -s
netstat -an | grep ESTABLISHED | wc -l

# 2. 查看网络错误
ip -s link show eth0
cat /proc/net/dev

# 3. 测试带宽
iperf3 -s &               # 服务器
iperf3 -c server_ip     # 客户端

# 4. 查看路由跳数
traceroute 8.8.8.8
mtr 8.8.8.8
```

---

# 3. 磁盘问题

## 3.1 磁盘空间不足

```bash
# 1. 查找大文件
du -sh /* 2>/dev/null | sort -rh | head -10
du -sh /var/* 2>/dev/null | sort -rh

# 2. 查找大目录
find / -type f -size +100M -exec ls -lh {} \;

# 3. 日志文件
journalctl --disk-usage
journalctl --vacuum-size=100M
du -sh /var/log

# 4. 清理旧内核 (Ubuntu)
apt autoremove --purge
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r)"/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'

# 5. 清理缓存
apt clean
yum clean all
```

## 3.2 inode耗尽

```bash
# 查看inode使用
df -i

# 查找inode占用
for dir in /*; do
    echo "$dir: $(find $dir -type f | wc -l)"
done

# 找出大量小文件的目录
find / -type d -exec sh -c 'echo "$(find {} -type f | wc -l) $dir"' _ {} \;
```

---

# 4. 性能问题

## 4.1 CPU高负载

```bash
# 1. 查看CPU使用
top
htop

# 找出CPU占用最高的进程
ps aux --sort=-%cpu | head -10

# 2. 查看进程详情
top -p PID
strace -p PID

# 3. 查看系统调用
strace -c -p PID
```

## 4.2 内存问题

```bash
# 1. 查看内存使用
free -h
cat /proc/meminfo

# 2. OOM问题
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# 3. 查看OOM分数
cat /proc/PID/oom_score

# 4. 调整OOM偏好
echo 1000 > /proc/PID/oom_score_adj
```

## 4.3 磁盘I/O高

```bash
# 1. 查看I/O
iostat -xz 1
iotop

# 2. 找出高I/O进程
pidstat -d 1
```

---

# 5. 用户和权限问题

## 5.1 无法登录

```bash
# 1. 检查Shell
cat /etc/passwd | grep username
chsh -s /bin/bash username

# 2. 检查密码
passwd username

# 3. 检查pam配置
auth.log | grep username
```

## 5.2 权限被拒绝

```bash
# 1. 检查文件权限
ls -la /path/to/file

# 2. 检查SELinux
getenforce
sestatus
ls -Z /path/to/file

# 3. 检查ACL
getfacl /path/to/file
```

---

# 6. 软件包问题

## 6.1 APT问题

```bash
# 1. 损坏的包状态
sudo dpkg --configure -a
sudo apt install -f

# 2. 清理缓存
sudo apt clean
sudo apt autoclean

# 3. 修复依赖
sudo apt-get install -f
```

## 6.2 RPM问题

```bash
# 1. 损坏的数据库
sudo rpm --rebuilddb

# 2. 验证包
rpm -Va
```

---

## 本章小结

- 启动问题需要查看Grub、内核日志、系统日志
- 网络问题先检查物理连接,再检查IP/路由/DNS
- 磁盘问题关注空间和inode使用
- 性能问题使用top/htop/iostat定位
- 用户问题检查Shell和pam配置

**关键诊断命令:**

```bash
dmesg, journalctl, systemctl status, ss, df, du, top, strace, lsof
```