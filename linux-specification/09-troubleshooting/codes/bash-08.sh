# 1. 查看内存使用
free -h
cat /proc/meminfo

# 2. OOM问题
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# 3. 查看OOM分数
cat /proc/PID/oom_score

# 4. 调整OOM偏好
echo 1000 > /proc/PID/oom_score_adj