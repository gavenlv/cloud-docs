# 软件和服务管理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux软件包管理器的**底层原理**（APT/RPM/YUM/DNF）
- 掌握dpkg/RPM包管理命令
- 理解systemd服务管理机制的原理
- 熟练使用systemctl管理服务
- 理解服务依赖和启动顺序
- 从**内核角度**理解服务是如何被systemd管理的

**学习方法：**

```
包管理器架构 → dpkg/RPM → APT/YUM/DNF → systemd原理 → 服务管理 → 实战操作
```

---

# 1. 软件包管理器原理

## 1.1 包管理器架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux包管理器架构                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      APT (Debian/Ubuntu)                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  dpkg        │◄───►│   APT        │◄───►│  apt-get     │
│  (底层)      │     │  (中间层)    │     │  (高层)      │
└──────────────┘     └──────────────┘     └──────────────┘
      │                    │                    │
      ▼                    ▼                    ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ /var/lib/dpkg│     │ /var/lib/apt │     │ /etc/apt     │
│  数据库      │     │  缓存        │     │  配置        │
└──────────────┘     └──────────────┘     └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    RPM/YUM/DNF (RHEL/CentOS/Fedora)             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  RPM         │◄───►│   YUM/DNF    │◄───►│  dnf/yum     │
│  (底层)      │     │  (中间层)    │     │  (高层)      │
└──────────────┘     └──────────────┘     └──────────────┘
      │                    │                    │
      ▼                    ▼                    ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ /var/lib/rpm│     │ /var/cache   │     │ /etc/yum.repos.d
│  数据库      │     │  缓存        │     │  配置        │
└──────────────┘     └──────────────┘     └──────────────┘

# 包格式:
# Debian: .deb
# RHEL/CentOS: .rpm

# 依赖解析:
# 包管理器自动处理依赖关系
# 仓库提供包的元数据和实际文件
```

## 1.2 包格式详解

```bash
# DEB包结构
dpkg-deb -I package.deb
# 新包格式 debian 二进制包
#  包名: package
#  版本: 1.2.3
#  架构: amd64
#  描述: Package description

# 查看deb包内容
dpkg-deb -c package.deb
dpkg-deb -x package.deb /tmp/extracted

# RPM包结构
rpm -qpi package.rpm
# Name        : package
# Version     : 1.2.3
# Release     : 1.el8
# Architecture: x86_64
# Summary     : Package description

# 查看rpm包内容
rpm -qpl package.rpm
rpm2cpio package.rpm | cpio -idv
```

---

# 2. APT/Dpkg包管理

## 2.1 APT工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    APT工作流程                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ /etc/apt/sources│     # 软件源配置
│   .list         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  apt-get update  │     # 更新软件源索引
│  (下载Release    │
│   和Package.gz)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  apt-get install │     # 解析依赖树
│   package       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  依赖解析        │     # 下载所需包
│  (解决依赖冲突)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  dpkg -i        │     # 调用dpkg安装
│   *.deb         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ /var/lib/dpkg   │     # 包数据库
│   info/         │
│   status        │
└─────────────────┘
```

## 2.2 APT源配置

```bash
# /etc/apt/sources.list 格式
# deb/deb-src 镜像URL 发行版版本 组件

cat /etc/apt/sources.list
# deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
# deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
# deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted

# 源格式说明:
# deb     - 二进制包仓库
# deb-src - 源码包仓库
# 镜像URL - 软件源地址
# 发行版  - jammy (Ubuntu 22.04) 或 focal (Ubuntu 20.04)
# 组件    - main, restricted, universe, multiverse

# 添加PPA (Personal Package Archive)
sudo add-apt-repository ppa:user/ppa-name

# 添加第三方源
sudo bash -c 'echo "deb http://example.com/repo stable main" > /etc/apt/sources.list.d/example.list'

# 签名密钥
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYID
sudo apt-key fingerprint                          # 查看已添加的密钥
```

## 2.3 APT常用命令

```bash
# 更新软件源索引
sudo apt update

# 升级已安装包
sudo apt upgrade              # 不删除任何包
sudo apt full-upgrade        # 必要时可以删除包

# 安装包
sudo apt install package
sudo apt install package1 package2      # 安装多个
sudo apt install -y package              # 自动确认
sudo apt install --no-install-recommends package  # 不安装推荐

# 重新安装
sudo apt reinstall package

# 删除包
sudo apt remove package       # 删除包,保留配置
sudo apt purge package        # 删除包和配置
sudo apt autoremove          # 删除不需要的依赖

# 搜索包
apt search keyword
apt-cache search keyword
apt-cache show package       # 包详细信息
apt-cache depends package    # 包依赖

# 查看已安装
apt list --installed
dpkg -l                       # 列出所有已安装包
dpkg -l | grep package        # 查找特定包

# 查看包文件
dpkg -L package               # 包安装的文件列表
dpkg -S /path/to/file         # 文件属于哪个包
```

## 2.4 Dpkg操作

```bash
# 安装本地deb包
sudo dpkg -i package.deb

# 修复损坏的安装
sudo dpkg --configure -a

# 查看包状态
dpkg -s package
dpkg --status package

# 列出已配置的文件
dpkg -l

# 列出包的文件
dpkg -L package

# 找出包含文件的包
dpkg -S /bin/ls
```

---

# 3. YUM/DNF/RPM包管理

## 3.1 YUM/DNF工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    YUM/DNF工作流程                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ /etc/yum.repos.d│     # 仓库配置文件
│   *.repo        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  yum/dnf repolist│     # 列出可用仓库
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  yum/dnf install │     # 解析依赖
│   package       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  依赖解析        │     # 从仓库下载RPM包
│  (检查冲突)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  rpm -ivh       │     # 调用rpm安装
│   *.rpm         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ /var/lib/rpm    │     # RPM数据库
│   Packages.db   │
└─────────────────┘

# DNF (Dandified YUM) 是YUM的下一代:
# - 更好的依赖解析
# - 更低的内存占用
# - 支持模块化
# - 更好的API
```

## 3.2 YUM/DNF常用命令

```bash
# DNF (Fedora, RHEL 8+)
# 基础操作
dnf install package              # 安装包
dnf remove package               # 删除包
dnf update                       # 升级所有包
dnf update package               # 升级特定包
dnf check-update                 # 检查更新

# 查询
dnf search keyword
dnf info package
dnf list --installed
dnf list --available
dnf provides /path/to/file      # 找出提供文件的包

# 组操作
dnf group install "Development Tools"
dnf group list
dnf group remove "Development Tools"

# 仓库操作
dnf repolist                    # 列出仓库
dnf repoinfo                    # 仓库详情
dnf config-manager --add-repo=http://example.com/repo.repo

# 清理
dnf clean all                   # 清理缓存
dnf history                     # 查看操作历史

# YUM (RHEL 7及之前)
yum install package
yum remove package
yum update
yum check-update
yum search keyword
yum repolist
```

## 3.3 RPM操作

```bash
# 安装
rpm -ivh package.rpm            # 安装
rpm -ivh --nodeps package.rpm   # 不检查依赖
rpm -ivh --force package.rpm    # 强制安装

# 升级
rpm -Uvh package.rpm            # 升级(如果没有则安装)
rpm -Fvh package.rpm            # 升级(如果没有则不安装)

# 删除
rpm -e package                  # 删除
rpm -e --nodeps package        # 不检查依赖删除

# 查询
rpm -qa                         # 所有已安装包
rpm -qf /path/to/file          # 文件属于哪个包
rpm -qi package                 # 包信息
rpm -ql package                 # 包的文件列表
rpm -q --requires package       # 包依赖
rpm -q --whatrequires package   # 哪些包依赖此包

# 验证
rpm -V package                  # 验证包文件
rpm -Va                        # 验证所有包
rpm --import RPM-GPG-KEY       # 导入签名密钥
```

---

# 4. systemd服务管理原理

## 4.1 systemd架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    systemd 架构                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      systemd (PID 1)                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Unit Files │  │   Targets   │  │   Sockets   │            │
│  │  管理器     │  │   管理器    │  │   管理器    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Service   │  │    Timer    │  │   Mount     │            │
│  │   管理器    │  │   管理器    │  │   管理器    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘

# Unit类型:
# - service: 后台服务进程
# - socket: 套接字
# - target: 一组unit的组合
# - mount: 文件系统挂载点
# - timer: 定时任务
# - path: 文件系统路径监控
# - slice: 资源控制组
# - scope: 外部进程组
```

## 4.2 Unit文件结构

```bash
# Unit文件位置
/etc/systemd/system/           # 系统管理员创建的unit
/run/systemd/system/           # 运行时创建的unit
/lib/systemd/system/           # 包安装的unit

# service类型
cat /lib/systemd/system/nginx.service
#[Unit]
#Description=The NGINX HTTP and reverse proxy server
#Documentation=http://nginx.org/en/docs/
#After=network.target
#
#[Service]
#Type=forking
#PIDFile=/run/nginx.pid
#ExecStartPre=/usr/sbin/nginx -t
#ExecStart=/usr/sbin/nginx
#ExecReload=/bin/kill -s HUP $MAINPID
#ExecStop=/bin/kill -s QUIT $MAINPID
#PrivateTmp=true
#
#[Install]
#WantedBy=multi-user.target

# Unit字段说明:
# Description      - 描述
# Documentation    - 文档URL
# After            - 在哪些unit之后启动
# Before           - 在哪些unit之前启动
# Requires         - 强依赖(同时启动/停止)
# Wants            - 弱依赖(尝试启动)
# Conflicts        - 互斥(不能同时运行)

# Service字段说明:
# Type             - 启动类型 (simple, exec, forking, oneshot, dbus, notify, idle)
# ExecStart        - 启动命令
# ExecStop         - 停止命令
# ExecReload       - 重载命令
# Restart          - 自动重启 (no, on-success, on-failure, on-abnormal, always)
# RestartSec       - 重启间隔
# User             - 运行用户
# WorkingDirectory - 工作目录
# Environment      - 环境变量
# EnvironmentFile  - 环境变量文件
# PIDFile          - PID文件(用于Type=forking)
# StandardOutput   - 标准输出
# StandardError    - 标准错误

# Install字段说明:
# WantedBy         - 所属target
# Also            - 随此unit一起 enable/disable 的其他unit
```

## 4.3 服务管理命令

```bash
# systemd基础命令

# 查看服务状态
systemctl status nginx

# 启动/停止/重启
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 重载配置 (不中断服务)
sudo systemctl reload nginx

# 重启或重载
sudo systemctl reload-or-restart nginx

# 开机自启
sudo systemctl enable nginx
sudo systemctl disable nginx

# 检查是否enable
systemctl is-enabled nginx

# 查看依赖
systemctl list-dependencies nginx
systemctl list-dependencies --after nginx    # nginx之后启动的
systemctl list-dependencies --before nginx   # nginx之前启动的

# 屏蔽服务 (完全禁用)
sudo systemctl mask nginx        # 符号链接到 /dev/null
sudo systemctl unmask nginx      # 取消屏蔽

# 查看所有unit
systemctl list-units --all
systemctl list-units --type=service
systemctl list-units --type=socket
systemctl list-units --type=target

# 查看failed的unit
systemctl --failed
```

## 4.4 Target管理

```bash
# 查看target
systemctl list-units --type=target --all

# 查看当前target
systemctl get-default

# 设置默认target
sudo systemctl set-default multi-user.target
sudo systemctl set-default graphical.target

# 切换到target (不修改默认)
sudo systemctl isolate multi-user.target
sudo systemctl isolate graphical.target

# 查看target的依赖
systemctl list-dependencies multi-user.target
```

## 4.5 journal日志

```bash
# systemd-journald 日志管理

# 查看日志
journalctl                           # 所有日志
journalctl -u nginx                  # 指定服务日志
journalctl -u nginx -f              # 实时跟踪
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-01" --until "2024-01-02"
journalctl -p err                    # 错误级别
journalctl --disk-usage              # 日志磁盘使用

# 日志清理
journalctl --vacuum-size=500M       # 限制日志大小
journalctl --vacuum-time=7d         # 保留7天
journalctl --vacuum-files=10       # 保留文件数

# 内核日志
journalctl -k                       # 等价于 dmesg
journalctl -b                       # 本次启动日志
journalctl -b -1                    # 上次启动日志

# 查看日志优先级
# 0: emerg (系统不可用)
# 1: alert (需要立即处理)
# 2: crit (严重)
# 3: err (错误)
# 4: warning (警告)
# 5: notice (普通通知)
# 6: info (信息)
# 7: debug (调试)
```

---

# 5. SysVinit与systemd对比

## 5.1 启动流程对比

```
┌─────────────────────────────────────────────────────────────────┐
│                    SysVinit vs systemd                          │
└─────────────────────────────────────────────────────────────────┘

┌───────────────────────┬────────────────────────────────────────┐
│      SysVinit         │           systemd                        │
├───────────────────────┼────────────────────────────────────────┤
│                       │                                        │
│  BIOS/UEFI           │  BIOS/UEFI                             │
│       │              │       │                                 │
│  GRUB                │  GRUB                                  │
│       │              │       │                                 │
│  Kernel + initrd     │  Kernel + initrd                        │
│       │              │       │                                 │
│  /sbin/init (PID 1) │  /lib/systemd/systemd (PID 1)           │
│       │              │       │                                 │
│  init.d scripts      │  systemd units                          │
│       │              │       │                                 │
│  Runlevels           │  Targets                               │
│  (0-6)              │  (multi-user, graphical, etc)           │
│                       │                                        │
└───────────────────────┴────────────────────────────────────────┘

# Runlevels vs Targets:
# 0  -> poweroff.target      (关闭系统)
# 1  -> rescue.target         (单用户/救援模式)
# 2  -> multi-user.target     (多用户,无网络)
# 3  -> multi-user.target     (多用户,命令行)
# 4  -> multi-user.target     (多用户,自定义)
# 5  -> graphical.target      (图形界面)
# 6  -> reboot.target         (重启)
```

## 5.2 命令对比

```bash
# 服务管理命令对比

┌─────────────────────────────────────────────────────────────────┐
│       SysVinit         │            systemd                      │
├────────────────────────┼────────────────────────────────────────┤
│  service nginx start   │  systemctl start nginx                 │
│  service nginx stop    │  systemctl stop nginx                  │
│  service nginx restart  │  systemctl restart nginx               │
│  service nginx reload   │  systemctl reload nginx                │
│  service nginx status   │  systemctl status nginx                │
│  service nginx condrestart│  systemctl condrestart nginx          │
├────────────────────────┼────────────────────────────────────────┤
│  chkconfig --level 3 nginx on │  systemctl enable nginx         │
│  chkconfig --level 3 nginx off│  systemctl disable nginx         │
│  chkconfig --list nginx       │  systemctl is-enabled nginx      │
├────────────────────────┼────────────────────────────────────────┤
│  /etc/init.d/nginx     │  /lib/systemd/system/nginx.service     │
│    start|stop|reload   │    (systemd自动处理)                  │
└────────────────────────┴────────────────────────────────────────┘

# 常用命令
systemctl daemon-reload           # 重载unit文件
systemctl reset-failed            # 重置failed状态
systemctl poweroff                # 关机
systemctl reboot                  # 重启
systemctl emergency               # 进入emergency模式
```

---

# 6. 服务配置实战

## 6.1 创建自定义服务

```bash
# 创建自定义服务单元

cat > /etc/systemd/system/myservice.service << 'EOF'
[Unit]
Description=My Custom Service
Documentation=https://example.com/docs
After=network.target

[Service]
Type=simple
User=myuser
Group=myuser
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/myapp --config /opt/myapp/config.yaml
ExecStop=/bin/kill -TERM $MAINPID
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myservice

# 安全加固
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/myapp/data /var/log/myapp
PrivateTmp=true

# 资源限制
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# 重载并启用
sudo systemctl daemon-reload
sudo systemctl enable myservice
sudo systemctl start myservice
sudo systemctl status myservice
```

## 6.2 Socket激活服务

```bash
# 创建socket激活服务

cat > /etc/systemd/system/mysocket.socket << 'EOF'
[Unit]
Description=My Service Socket
PartOf=myservice.service

[Socket]
ListenStream=/run/myservice.sock
SocketMode=0660
SocketUser=myuser
SocketGroup=mygroup

[Install]
WantedBy=sockets.target
EOF

cat > /etc/systemd/system/myservice.service << 'EOF'
[Unit]
Description=My Service
After=mysocket.socket

[Service]
Type=notify
ExecStart=/opt/myapp/bin/myapp --socket /run/myservice.sock
SocketActivation=accept

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mysocket.socket
sudo systemctl start mysocket.socket
```

## 6.3 Timer定时服务

```bash
# 创建定时任务

cat > /etc/systemd/system/mytask.timer << 'EOF'
[Unit]
Description=My Scheduled Task
Requires=mytask.service

[Timer]
OnCalendar=*-*-* *:*:00      # 每分钟
# OnCalendar=*-*-01 00:00:00  # 每月1号凌晨
# OnCalendar=daily            # 每天
# OnCalendar=hourly           # 每小时
Persistent=true              # 如果错过则立即运行

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/mytask.service << 'EOF'
[Unit]
Description=My Scheduled Task

[Service]
Type=oneshot
ExecStart=/opt/myapp/scripts/mytask.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mytask.timer
sudo systemctl list-timers
```

---

# 7. 软件安装其他方式

## 7.1 源码编译安装

```bash
# 从源码编译安装

# 1. 安装编译工具
sudo apt install build-essential   # Debian/Ubuntu
sudo yum groupinstall "Development Tools"  # RHEL/CentOS

# 2. 下载源码
wget https://example.com/package.tar.gz
tar -xzf package.tar.gz
cd package

# 3. 查看INSTALL/README
less INSTALL
less README

# 4. 配置
./configure --prefix=/opt/package --enable-feature

# 5. 编译
make -j$(nproc)

# 6. 安装
sudo make install

# 7. 清理
make clean
make distclean

# 8. 卸载 (如果没有make uninstall)
sudo rm -rf /opt/package
sudo rm -f /usr/local/bin/package
```

## 7.2 Snap和Flatpak

```bash
# Snap (Canonical开发)
# 安装
sudo snap install vlc

# 列出
snap list
snap list --all

# 更新
sudo snap refresh
sudo snap refresh vlc

# 删除
sudo snap remove vlc

# 经典模式 (需要--classic)
sudo snap install --classic code

# Flatpak (通用)
# 安装
flatpak install flathub org.videolan.VLC

# 列出
flatpak list

# 更新
flatpak update

# 删除
flatpak uninstall org.videolan.VLC
```

## 7.3 AppImage

```bash
# AppImage - 无需安装的便携式应用

# 下载
wget https://example.com/App.AppImage

# 添加执行权限
chmod +x App.AppImage

# 运行
./App.AppImage

# 可选: 创建桌面图标
./App.AppImage --install-desktop
```

---

## 本章小结

- **APT/YUM/DNF**包管理器自动处理依赖关系,简化软件安装
- **dpkg/RPM**是底层包管理器,直接操作.deb/.rpm包
- **systemd**通过Unit文件管理系统服务,支持复杂的依赖关系
- **Unit类型**包括service、socket、target、mount、timer等
- **systemctl**是systemd的主要管理工具,替代了service和chkconfig
- **journalctl**提供集中化的日志管理,支持实时跟踪和过滤
- **源码编译**提供最大灵活性,但需要手动管理依赖

**关键命令回顾:**

```bash
# APT (Debian/Ubuntu)
apt update, apt install, apt remove, apt-cache search

# YUM/DNF (RHEL/CentOS/Fedora)
dnf install, dnf remove, dnf search, dnf repolist

# RPM
rpm -ivh, rpm -e, rpm -qa

# systemd
systemctl start/stop/restart, systemctl enable/disable
systemctl status, systemctl list-units, systemctl daemon-reload
journalctl -u, journalctl -f
```