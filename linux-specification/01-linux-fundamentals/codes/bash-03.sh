# 查看内核版本
uname -r
# 5.4. x-generic

# 查看内核启动参数
cat /proc/cmdline
# BOOT_IMAGE=/boot/vmlinuz-5.4.0 root=UUID=xxx ro quiet splash

# 查看内核日志 (dmesg)
dmesg | head -50
dmesg | grep -i error