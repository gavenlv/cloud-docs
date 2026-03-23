# 日志和监控

## 本章导学

**学完本章后，你将能够：**

- 理解Linux日志系统的**底层原理**（rsyslog、journald、syslog）
- 掌握日志配置和日志轮转
- 熟练使用日志分析工具
- 理解系统监控的核心指标
- 从**内核角度**理解日志是如何被收集和存储的

**学习方法：**

```
日志系统 → rsyslog → journald → 日志分析 → 系统监控 → 实战操作
```

---

# 1. Linux日志系统架构

## 1.1 日志系统概述

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux日志系统架构                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      应用层                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ nginx    │  │  mysql   │  │   ssh    │  │  kernel  │     │
│  │  syslog  │  │  syslog  │  │  syslog  │  │  kmsg    │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
└───────┼──────────────┼──────────────┼──────────────┼──────────────┘
        │              │              │              │
        └──────────────┴──────────────┼──────────────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                    ┌─────────▼────────┐ ┌──────▼────────┐
                    │    rsyslogd     │ │  systemd-journald│
                    │   (传统日志)     │ │   (现代日志)    │
                    └─────────┬────────┘ └──────┬────────┘
                              │                 │
                    ┌─────────┴────────┐ ┌──────┴────────┐
                    │   /var/log     │ │  /run/log   │
                    │   文本文件      │ │  journal    │
                    └─────────────────┘ │  (二进制)    │
                                         └─────────────┘
```

## 1.2 日志优先级

```bash
# 日志级别 (从高到低):
# 0: emerg  - 系统不可用
# 1: alert  - 需要立即处理
# 2: crit   - 严重
# 3: err    - 错误
# 4: warning - 警告
# 5: notice - 普通通知
# 6: info   - 信息
# 7: debug  - 调试

# facilities (设施):
# auth      - 认证 (login, su, sudo)
# authpriv  - 私有认证
# cron      - 定时任务
# daemon    - 系统守护进程
# ftp       - FTP服务
# kern      - 内核
# local0-7  - 本地使用
# mail      - 邮件
# news      - 新闻组
# syslog    - syslog内部
# user      - 用户进程
# uucp      - UUCP
```

---

# 2. rsyslog配置

## 2.1 rsyslog架构

```bash
# rsyslog配置文件
/etc/rsyslog.conf          # 主配置
/etc/rsyslog.d/*.conf      # 片段配置

# 格式: facility.priority   action
# auth.info          /var/log/auth.log     # auth.info及以上
# mail.warn          /var/log/mail.warn    # mail.warn及以上
# *.debug           @remote-host          # 转发到远程
```

## 2.2 rsyslog配置示例

```bash
# /etc/rsyslog.conf 示例

# 模板定义
$template RemoteHost,"/var/log/remote/%HOSTNAME%/%$YEAR%/%$MONTH%/%$DAY%/%PROGRAMNAME%.log"

# 规则
*.info;mail.none;authpriv.none;cron.none   /var/log/messages
authpriv.*                                 /var/log/secure
mail.*                                     -/var/log/maillog
cron.*                                     /var/log/cron
*.emerg                                    *
uucp,news.crit                            /var/log/spooler
local7.*                                   /var/log/boot.log

# 转发规则
*.* @@remote-syslog.example.com:514       # TCP转发
*.* @remote-syslog.example.com:514        # UDP转发

# 过滤规则
if $programname == 'nginx' then {
    action(type="omfile" file="/var/log/nginx.log")
    stop
}
```

---

# 3. journald日志

## 3.1 journald配置

```bash
# /etc/systemd/journald.conf

[Journal]
Storage=persistent          # persistent, volatile, auto, none
SystemMaxUse=500M          # 最大日志空间
SystemMaxFileSize=50M       # 单个日志文件最大
MaxRetentionSec=30day      # 保留时间
RateLimitInterval=30s      # 速率限制间隔
RateLimitBurst=1000        # 速率限制突发量
```

## 3.2 journalctl高级用法

```bash
# 基本查询
journalctl -b                 # 本次启动日志
journalctl -b -1              # 上次启动
journalctl -k                 # 内核日志
journalctl -u nginx           # 特定服务
journalctl -u nginx -u mysql  # 多个服务

# 时间和范围
journalctl --since "2024-01-01 00:00:00"
journalctl --since "1 hour ago"
journalctl --since today
journalctl --until "2024-01-01 12:00:00"
journalctl --since "2024-01-01" --until "2024-01-02"

# 过滤
journalctl -p err             # 错误级别
journalctl -p warning -p err  # 多个级别
journalctl -n 100             # 最近100行
journalctl -f                 # 实时跟踪

# 显示字段
journalctl -o json           # JSON格式
journalctl -o verbose         # 详细字段
journalctl -o short          # 简短格式

# 内核消息
journalctl -k -b              # 内核启动日志
journalctl -k --dmesg        # 等价于dmesg
```

---

# 4. 日志文件管理

## 4.1 日志轮转 logrotate

```bash
# /etc/logrotate.conf 主配置
# /etc/logrotate.d/* 子配置

cat /etc/logrotate.conf
# weekly              # 每周轮转
# rotate 4            # 保留4份
# create              # 创建新日志
# dateext             # 使用日期作为扩展名
# compress            # 压缩旧日志
# include /etc/logrotate.d

/var/log/wtmp {
    monthly
    create 0664 root utmp
    rotate 1
}

/var/log/btmp {
    monthly
    create 0664 root utmp
    rotate 1
}
```

## 4.2 自定义logrotate配置

```bash
# /etc/logrotate.d/nginx

/var/log/nginx/*.log {
    daily                 # 每日轮转
    missingok             # 忽略不存在
    rotate 14            # 保留14份
    compress             # gzip压缩
    delaycompress         # 延迟压缩(保留最近的不压缩)
    notifempty           # 空文件不轮转
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

---

# 5. 系统监控

## 5.1 基础监控命令

```bash
# uptime - 系统运行时间
uptime
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08

# w - 当前登录用户和负载
w
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08
# USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
# user     pts/0    192.168.1.100    19:11    0.00s  0.00s  0.00s w

# top - 实时监控
top
# 按M按内存排序,按P按CPU排序,按1显示所有核心

# vmstat - 虚拟内存统计
vmstat 1 5
vmstat -a                     # 活跃/非活跃内存
vmstat -s                     # 详细统计

# mpstat - 多处理器统计
mpstat -P ALL 1 5

# iostat - I/O统计
iostat -xz 1 5
iostat -d /dev/sda 1 3
```

## 5.2 性能监控脚本

```bash
cat > /root/monitor.sh << 'EOF'
#!/bin/bash
# 系统监控脚本

while true; do
    clear
    echo "===== $(date) ====="
    echo ""
    echo "=== 系统负载 ==="
    uptime
    echo ""
    echo "=== 内存使用 ==="
    free -h
    echo ""
    echo "=== 磁盘使用 ==="
    df -h | grep -v tmpfs
    echo ""
    echo "=== Top 5 CPU进程 ==="
    ps aux --sort=-%cpu | head -6
    echo ""
    echo "=== Top 5 内存进程 ==="
    ps aux --sort=-%mem | head -6
    sleep 5
done
EOF
chmod +x /root/monitor.sh
```

---

## 本章小结

- Linux日志系统主要由rsyslog和systemd-journald组成
- journalctl提供强大的日志查询和过滤能力
- logrotate自动管理日志文件轮转
- 系统监控需要关注CPU、内存、磁盘、网络等指标

**关键命令回顾:**

```bash
journalctl, rsyslogd, logrotate, uptime, vmstat, iostat, free, df
```