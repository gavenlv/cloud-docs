# iperf3: 带宽测试工具

# 服务器端
iperf3 -s
iperf3 -s -D                    # 后台运行
iperf3 -s -i 1                  # 每秒输出

# 客户端
iperf3 -c server_ip
iperf3 -c server_ip -t 30      # 测试30秒
iperf3 -c server_ip -P 4        # 4个并行连接
iperf3 -c server_ip -R          # 下载测试(服务端发送)

# 结果
# [  4]   0.00-30.00  sec  3.45 GBytes    987 Mbits/sec

# speedtest-cli: 测试到互联网的带宽
speedtest-cli
speedtest-cli --simple           # 简单输出
speedtest-cli --list            # 服务器列表