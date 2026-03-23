# crontab - 定时任务

# 格式: 分 时 日 月 周 命令
# * * * * * command
# │ │ │ │ │
# │ │ │ │ └─── 星期 (0-7, 0和7是周日)
# │ │ │ └───── 月份 (1-12)
# │ │ └─────── 日期 (1-31)
# │ └───────── 小时 (0-23)
# └─────────── 分钟 (0-59)

# 示例
# 每分钟执行
* * * * * /path/to/command

# 每小时执行
0 * * * * /path/to/command

# 每天凌晨3点执行
0 3 * * * /path/to/command

# 每周一执行
0 0 * * 1 /path/to/command

# 每月1号执行
0 0 1 * * /path/to/command

# 每5分钟执行
*/5 * * * * /path/to/command

# 上午9点到下午5点每30分钟执行
*/30 9-17 * * * /path/to/command

# crontab命令
crontab -l              # 列出当前crontab
crontab -e              # 编辑crontab
crontab -r              # 删除crontab
crontab -i              # 删除前确认

# 系统级crontab
# /etc/crontab
# /etc/cron.d/
# /etc/cron.daily/
# /etc/cron.hourly/
# /etc/cron.monthly/
# /etc/cron.weekly/