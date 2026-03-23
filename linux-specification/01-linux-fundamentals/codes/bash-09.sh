# 查看OOM (Out of Memory) killer日志
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# 查看OOM分数
cat /proc/PID/oom_score

# 调整OOM偏好度 (值越高越容易被杀)
echo 1000 > /proc/PID/oom_score_adj