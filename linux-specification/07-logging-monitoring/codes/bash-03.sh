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