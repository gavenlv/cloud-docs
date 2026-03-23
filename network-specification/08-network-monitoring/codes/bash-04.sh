# netstat是经典的网络统计工具

# 基本用法
netstat -tuln                # 监听端口
netstat -an                  # 所有连接
netstat -r                   # 路由表
netstat -i                   # 接口统计
netstat -s                   # 各协议统计

# 过滤
netstat -an | grep ESTABLISHED
netstat -an | grep :80

# 配合grep分析
netstat -an | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head