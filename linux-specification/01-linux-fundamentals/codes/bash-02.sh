# 常用GRUB命令
grub2-mkconfig -o /boot/grub2/grub.cfg   # 生成配置文件
grub2-install /dev/sda                    # 安装GRUB

# 进入GRUB命令行
# 按 'c' 键在启动时进入命令行模式

# 常用GRUB命令
ls                              # 列出设备
ls (hd0,msdos1)/               # 查看分区内容
set root=(hd0,msdos1)
linux /boot/vmlinuz root=/dev/sda1
initrd /boot/initramfs.img
boot