# BIOS (Basic Input/Output System)
# - 存储在主板ROM芯片中
# - legacy启动模式
# - MBR分区表 (512字节)

# UEFI (Unified Extensible Firmware Interface)
# - 现代化固件接口
# - GPT分区表 (支持 >2TB磁盘)
# - 支持安全启动 (Secure Boot)

# 查看固件类型 (Linux)
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"