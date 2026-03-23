# TTL (Time To Live)
# 缓存时间,单位秒

# 查看记录的TTL
dig www.example.com
# www.example.com.     300     IN      A       93.184.216.34
# 300秒=5分钟

# TTL设置建议:
# - 频繁变更: 300-3600秒 (5分钟-1小时)
# - 稳定记录: 86400秒 (1天)
# - 迁移时: 先调小TTL, 迁移完成后再调大

# DNS轮询 (Round Robin)
# 多个A记录, 每次返回不同顺序
www.example.com.    IN A     93.184.216.34
www.example.com.    IN A     93.184.216.35
www.example.com.    IN A     93.184.216.36