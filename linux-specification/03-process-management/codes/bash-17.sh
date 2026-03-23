# jobs - 查看后台作业
jobs

# Ctrl+Z - 暂停当前作业
# bg - 后台继续运行
# fg - 前台继续运行

# 示例
sleep 100 &
# [1] 12345
jobs
# [1]+  Running                 sleep 100 &

# 把作业切到后台
bg %1

# 把作业切到前台
fg %1

# 杀死作业
kill %1

# nohup - 忽略挂断信号
nohup ./long_running_script.sh &