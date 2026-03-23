# 查看当前I/O调度器
cat /sys/block/sda/queue/scheduler
# [mq-deadline] kyber bfq none

# mq-deadline: 适合数据库等延迟敏感应用
# bfq: 适合桌面和多媒体
# none: 不进行调度，适合SSD

# 修改I/O调度器 (临时)
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

# 永久修改 (通过内核参数)
# 添加:elevator=mq-deadline 到 GRUB_CMDLINE_LINUX