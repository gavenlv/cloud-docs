# rsyslog配置文件
/etc/rsyslog.conf          # 主配置
/etc/rsyslog.d/*.conf      # 片段配置

# 格式: facility.priority   action
# auth.info          /var/log/auth.log     # auth.info及以上
# mail.warn          /var/log/mail.warn    # mail.warn及以上
# *.debug           @remote-host          # 转发到远程