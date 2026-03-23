# 延迟测试
ping -c 100 8.8.8.8 | tail -1

# 抖动测试
ping -c 100 8.8.8.8
# 分析time列的标准差

# 丢包测试
ping -c 1000 -s 1400 8.8.8.8
# 查看packet loss

# 网络质量综合测试
# 使用iperf3测试TCP带宽
# 使用ping测试延迟和抖动
# 使用traceroute测试路由跳数