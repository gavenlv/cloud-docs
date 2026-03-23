# 加载模块
sudo modprobe virtio_net

# 卸载模块
sudo modprobe -r virtio_net

# 强制卸载 (谨慎使用)
sudo modprobe -r --force virtio_net

# 查看模块参数
cat /sys/module/virtio_net/parameters/