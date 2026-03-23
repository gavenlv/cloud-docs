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