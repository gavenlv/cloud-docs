# /etc/systemd/journald.conf

[Journal]
Storage=persistent          # persistent, volatile, auto, none
SystemMaxUse=500M          # 最大日志空间
SystemMaxFileSize=50M       # 单个日志文件最大
MaxRetentionSec=30day      # 保留时间
RateLimitInterval=30s      # 速率限制间隔
RateLimitBurst=1000        # 速率限制突发量