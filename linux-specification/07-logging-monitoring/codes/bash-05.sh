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