# /proc - 进程和内核信息
ls /proc/
# 1/      1234/    cpuinfo    meminfo     mounts      net/

cat /proc/cpuinfo | head -10
cat /proc/meminfo | head -10
cat /proc/uptime
cat /proc/loadavg

# /sys - sysfs, 内核对象信息
ls /sys/
# block/  bus/  class/  dev/  devices/  firmware/  fs/  kernel/  module/

# /dev - 设备文件
ls /dev/
# null  zero  random  urandom  tty  sda  sda1  ...

# /tmp - 临时文件 (通常tmpfs)
mount | grep /tmp
# tmpfs on /tmp type tmpfs (rw,nosuid,nodev)

# /run - 运行数据 (tmpfs)
ls /run/
# systemd/  lock/  log/