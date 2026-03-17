# Linux基础

## 本章概述

Linux是云计算的核心操作系统。本章将系统介绍Linux基础知识，为云服务器管理和运维打下基础。

## 学习目标

- 掌握Linux文件系统结构
- 理解用户与权限管理
- 熟练使用常用命令
- 掌握Shell脚本基础
- 了解进程管理和系统监控

---

## 1. Linux文件系统

### 1.1 目录结构

Linux采用树形目录结构，根目录为 `/`：

```
/                           根目录
├── bin/                    基本命令（所有用户可用）
├── sbin/                   系统管理命令（root用户）
├── etc/                    配置文件
│   ├── passwd              用户信息
│   ├── shadow              用户密码
│   ├── hosts               主机名解析
│   └── ssh/                SSH配置
├── home/                   普通用户主目录
│   ├── user1/
│   └── user2/
├── root/                   root用户主目录
├── var/                    可变数据
│   ├── log/                日志文件
│   ├── www/                Web数据
│   └── lib/                应用数据
├── usr/                    用户程序
│   ├── bin/                用户命令
│   ├── lib/                库文件
│   └── local/              本地安装软件
├── tmp/                    临时文件
├── dev/                    设备文件
├── proc/                   进程信息（虚拟文件系统）
├── sys/                    系统信息（虚拟文件系统）
└── boot/                   启动文件
```

### 1.2 重要目录说明

| 目录 | 说明 | 示例 |
|-----|------|------|
| /etc | 系统配置文件 | /etc/hosts, /etc/passwd |
| /var/log | 系统日志 | /var/log/messages |
| /home | 用户目录 | /home/user1 |
| /tmp | 临时文件 | 重启后清空 |
| /proc | 进程信息 | /proc/[pid]/status |

### 1.3 文件路径

```bash
绝对路径：从根目录开始的完整路径
/home/user1/documents/file.txt

相对路径：从当前目录开始的路径
./documents/file.txt
../user2/file.txt

特殊目录：
.   当前目录
..  上级目录
~   用户主目录
-   上一个工作目录
```

---

## 2. 常用命令

### 2.1 文件操作命令

```bash
ls          列出目录内容
ls -l       详细列表
ls -la      包含隐藏文件
ls -lh      人类可读大小

cd          切换目录
cd /etc     切换到/etc
cd ~        切换到主目录
cd -        切换到上一个目录

pwd         显示当前目录

mkdir       创建目录
mkdir -p a/b/c  递归创建

rmdir       删除空目录
rm -r       递归删除目录
rm -rf      强制递归删除（慎用）

touch       创建空文件或更新时间戳

cp          复制
cp file1 file2          复制文件
cp -r dir1 dir2         复制目录

mv          移动或重命名
mv file1 file2          重命名
mv file /tmp/           移动

rm          删除
rm file                 删除文件
rm -r directory         删除目录
```

### 2.2 文件查看命令

```bash
cat         显示文件全部内容
cat file1 file2 > merged   合并文件

less        分页查看（可上下翻页）
more        分页查看（只能向下）

head        显示文件开头
head -n 20 file    显示前20行

tail        显示文件结尾
tail -n 20 file    显示后20行
tail -f file       实时跟踪（查看日志）

wc          统计
wc -l file         统计行数
wc -w file         统计单词数

grep        搜索
grep "error" /var/log/messages   搜索关键字
grep -r "error" /var/log/        递归搜索
grep -i "ERROR" file             忽略大小写
grep -v "debug" file             排除匹配行
```

### 2.3 文件查找命令

```bash
find        查找文件
find /etc -name "*.conf"         按名称查找
find /var -type d -name "log"    查找目录
find /home -user root            按用户查找
find /tmp -mtime +7              7天前修改的文件
find . -size +100M               大于100M的文件

locate      快速查找（需要更新数据库）
locate nginx.conf
updatedb    更新数据库

which       查找命令位置
which python

whereis     查找命令及相关文件
whereis nginx
```

### 2.4 文件权限命令

```bash
chmod       修改权限
chmod 755 file        数字方式
chmod u+x file        符号方式（用户加执行权限）
chmod g-w file        符号方式（组减写权限）
chmod -R 755 dir      递归修改

chown      修改所有者
chown user:group file
chown -R user:group dir

chgrp      修改所属组
chgrp group file
```

---

## 3. 用户与权限管理

### 3.1 用户管理

```bash
useradd     创建用户
useradd -m -s /bin/bash username   创建用户并创建主目录
useradd -G sudo,docker username    创建用户并加入组

userdel     删除用户
userdel -r username    删除用户及主目录

usermod     修改用户
usermod -aG docker username   添加到附加组
usermod -l newname oldname    修改用户名

passwd      修改密码
passwd username        修改用户密码
passwd -e username     强制用户下次登录修改密码

id          查看用户信息
id username

whoami      查看当前用户
who
w           查看登录用户
```

### 3.2 组管理

```bash
groupadd    创建组
groupadd developers

groupdel    删除组
groupdel developers

groupmod    修改组
groupmod -n newname oldname

groups      查看用户所属组
groups username

gpasswd     组管理员命令
gpasswd -a user group    添加用户到组
gpasswd -d user group    从组删除用户
```

### 3.3 权限系统

**权限类型**：
```
r (read)    读权限    值：4
w (write)   写权限    值：2
x (execute) 执行权限  值：1
- (none)    无权限    值：0
```

**权限表示**：
```
-rwxr-xr--
│└┬┘└┬┘└┬┘
│ │  │  └── 其他用户权限：r-- (4)
│ │  └───── 所属组权限：r-x (5)
│ └──────── 文件所有者权限：rwx (7)
└────────── 文件类型：-普通文件 d目录 l链接

权限数字计算：
rwx = 4+2+1 = 7
r-x = 4+0+1 = 5
r-- = 4+0+0 = 4
```

**常用权限设置**：
```
chmod 755 file    rwxr-xr-x  脚本/程序
chmod 644 file    rw-r--r--  配置文件
chmod 600 file    rw-------  私钥文件
chmod 700 dir     rwx------  私有目录
```

### 3.4 sudo权限

```bash
visudo      编辑sudoers文件

配置示例：
root    ALL=(ALL:ALL) ALL
user    ALL=(ALL) NOPASSWD: ALL
%admin  ALL=(ALL) ALL

使用sudo：
sudo command
sudo -u username command
```

---

## 4. Shell脚本基础

### 4.1 脚本结构

```bash
#!/bin/bash

echo "Hello World"
```

**执行方式**：
```bash
chmod +x script.sh
./script.sh

或
bash script.sh
```

### 4.2 变量

```bash
name="John"          赋值（等号两边不能有空格）
echo $name           使用变量
echo ${name}         推荐方式

特殊变量：
$0    脚本名称
$1-$9 位置参数
$#    参数个数
$@    所有参数
$?    上一个命令退出状态
$$    当前进程PID
$!    后台进程PID
```

### 4.3 条件判断

```bash
if [ condition ]; then
    commands
elif [ condition ]; then
    commands
else
    commands
fi

条件测试：
[ -f file ]        文件存在且是普通文件
[ -d dir ]         目录存在
[ -r file ]        文件可读
[ -w file ]        文件可写
[ -x file ]        文件可执行
[ -z string ]      字符串为空
[ -n string ]      字符串非空
[ $a -eq $b ]      整数相等
[ $a -ne $b ]      整数不等
[ $a -gt $b ]      大于
[ $a -lt $b ]      小于
```

**示例**：
```bash
#!/bin/bash

file="/etc/passwd"

if [ -f "$file" ]; then
    echo "File exists"
    if [ -r "$file" ]; then
        echo "File is readable"
    fi
else
    echo "File does not exist"
fi
```

### 4.4 循环

```bash
for循环：
for i in 1 2 3 4 5; do
    echo $i
done

for i in {1..10}; do
    echo $i
done

for file in *.txt; do
    echo "Processing $file"
done

while循环：
count=0
while [ $count -lt 10 ]; do
    echo $count
    count=$((count + 1))
done

until循环：
until [ $count -ge 10 ]; do
    echo $count
    count=$((count + 1))
done
```

### 4.5 函数

```bash
定义函数：
function greet() {
    echo "Hello, $1!"
}

greet "World"

带返回值的函数：
add() {
    result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "Sum: $sum"
```

### 4.6 实用脚本示例

**备份脚本**：
```bash
#!/bin/bash

SOURCE="/var/www/html"
DEST="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DATE}.tar.gz"

echo "Starting backup..."
tar -czf "${DEST}/${BACKUP_FILE}" "${SOURCE}"

if [ $? -eq 0 ]; then
    echo "Backup completed: ${BACKUP_FILE}"
    
    find ${DEST} -name "backup_*.tar.gz" -mtime +7 -delete
    echo "Old backups cleaned"
else
    echo "Backup failed!"
    exit 1
fi
```

---

## 5. 进程管理

### 5.1 进程查看

```bash
ps          查看进程
ps aux      显示所有进程详细信息
ps -ef      完整格式显示
ps aux | grep nginx    查找特定进程

top         动态显示进程
htop        增强版top（需安装）

pstree      以树形显示进程

pgrep       按名称查找进程ID
pgrep nginx
pgrep -l nginx    显示进程名

pidof       查找进程ID
pidof nginx
```

### 5.2 进程控制

```bash
前台/后台：
command &           后台运行
nohup command &     忽略挂断信号后台运行
jobs                查看后台任务
fg %1               将任务1调到前台
bg %1               将任务1放到后台

进程终止：
kill PID            发送TERM信号
kill -9 PID         发送KILL信号（强制）
kill -HUP PID       发送HUP信号（重载配置）
killall name        按名称终止进程
pkill pattern       按模式终止进程
```

### 5.3 系统服务管理

```bash
systemctl           systemd服务管理
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx
systemctl status nginx
systemctl enable nginx    开机自启
systemctl disable nginx   禁用自启
systemctl list-units      列出所有单元
systemctl list-unit-files 列出所有服务文件

service             传统服务管理（兼容）
service nginx start
service nginx stop
service nginx status
```

---

## 6. 系统监控

### 6.1 系统信息

```bash
uname -a            显示系统信息
hostname            显示主机名
hostnamectl         显示主机信息（systemd）
uptime              显示运行时间和负载
date                显示日期时间
cal                 显示日历
```

### 6.2 资源监控

```bash
CPU监控：
top                 实时进程监控
htop                增强版监控
mpstat              CPU统计

内存监控：
free -h             内存使用情况
vmstat              虚拟内存统计

磁盘监控：
df -h               磁盘使用情况
du -sh /var         目录大小
du -h --max-depth=1 /var
iostat              IO统计

网络监控：
ifconfig            网络接口配置
ip addr             IP地址
ip route            路由表
netstat -tuln       监听端口
ss -tuln            socket统计
netstat -anp        所有连接
lsof -i :80         查看端口占用
```

### 6.3 日志查看

```bash
journalctl          systemd日志
journalctl -u nginx 服务日志
journalctl -f       实时跟踪
journalctl --since "1 hour ago"

/var/log/           传统日志目录
/var/log/messages   系统消息
/var/log/secure     安全日志
/var/log/syslog     系统日志

tail -f /var/log/messages
grep "error" /var/log/messages
```

---

## 7. 软件包管理

### 7.1 apt (Debian/Ubuntu)

```bash
apt update          更新软件源
apt upgrade         升级所有软件
apt install package 安装软件
apt remove package  卸载软件
apt purge package   卸载并删除配置
apt search package  搜索软件
apt show package    显示软件信息
apt list --installed 列出已安装软件
```

### 7.2 yum/dnf (CentOS/RHEL)

```bash
yum update          更新所有软件
yum install package 安装软件
yum remove package  卸载软件
yum search package  搜索软件
yum info package    显示软件信息
yum list installed  列出已安装软件
yum clean all       清理缓存
```

---

## 8. 实操练习

### 练习1：用户管理

```bash
创建开发用户：
sudo useradd -m -s /bin/bash devuser
sudo passwd devuser
sudo usermod -aG sudo devuser

创建项目目录：
sudo mkdir /projects
sudo chown devuser:devuser /projects
sudo chmod 750 /projects
```

### 练习2：日志分析脚本

```bash
#!/bin/bash

LOG_FILE="/var/log/nginx/access.log"

echo "=== Top 10 IPs ==="
awk '{print $1}' $LOG_FILE | sort | uniq -c | sort -rn | head -10

echo "=== Top 10 URLs ==="
awk '{print $7}' $LOG_FILE | sort | uniq -c | sort -rn | head -10

echo "=== Status Codes ==="
awk '{print $9}' $LOG_FILE | sort | uniq -c | sort -rn

echo "=== Requests per Hour ==="
awk '{print substr($4, 14, 2)}' $LOG_FILE | sort | uniq -c
```

### 练习3：系统监控脚本

```bash
#!/bin/bash

echo "=== System Monitor ==="
echo "Date: $(date)"
echo ""

echo "=== Uptime ==="
uptime
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h | grep -E "^/dev|Filesystem"
echo ""

echo "=== Top 5 CPU Processes ==="
ps aux --sort=-%cpu | head -6
echo ""

echo "=== Top 5 Memory Processes ==="
ps aux --sort=-%mem | head -6
echo ""

echo "=== Network Connections ==="
ss -tuln | head -20
```

### 练习4：自动部署脚本

```bash
#!/bin/bash

APP_NAME="webapp"
DEPLOY_DIR="/var/www/${APP_NAME}"
BACKUP_DIR="/backup/${APP_NAME}"
GIT_REPO="https://github.com/user/webapp.git"

echo "Starting deployment..."

if [ -d "$DEPLOY_DIR" ]; then
    echo "Backing up current version..."
    mkdir -p "$BACKUP_DIR"
    tar -czf "${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$DEPLOY_DIR" .
fi

echo "Pulling latest code..."
if [ -d "${DEPLOY_DIR}/.git" ]; then
    cd "$DEPLOY_DIR"
    git pull
else
    git clone "$GIT_REPO" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

echo "Installing dependencies..."
npm install --production

echo "Restarting service..."
sudo systemctl restart ${APP_NAME}

echo "Deployment completed!"
```

---

## 9. 知识检测

### 选择题

1. 以下哪个命令可以递归删除目录？
   - A. rm dir
   - B. rm -r dir
   - C. rmdir dir
   - D. del dir

2. 文件权限 755 对应的是什么？
   - A. rwxrwxrwx
   - B. rwxr-xr-x
   - C. rw-r--r--
   - D. rwx------

3. 如何查看端口占用情况？
   - A. netstat -tuln
   - B. ps aux
   - C. top
   - D. df -h

### 实操题

1. 编写一个脚本，自动备份指定目录并保留最近7天的备份
2. 编写一个脚本，监控磁盘使用率，超过80%时发送告警
3. 编写一个脚本，批量创建用户并设置初始密码

---

## 10. 扩展阅读

- [Linux命令行大全](https://book.douban.com/subject/22226727/)
- [鸟哥的Linux私房菜](https://book.douban.com/subject/30359954/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

---

## 学习进度

- [ ] 掌握Linux文件系统结构
- [ ] 熟练使用常用命令
- [ ] 理解用户与权限管理
- [ ] 掌握Shell脚本基础
- [ ] 了解进程管理
- [ ] 掌握系统监控方法
- [ ] 完成实操练习
