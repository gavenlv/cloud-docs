# 查看已加载模块
lsmod
# Module                  Size  Used by
# xfs                   12345  1
# virtio_net            23456  2
# ext4                  45678  1

# 查看模块详情
modinfo virtio_net
# filename:       /lib/modules/5.4.0/kernel/drivers/net/virtio_net.ko
# version:        2.6.0
# license:        GPL
# description:    Virtio network driver
# author:         Rusty Russell

# 查看模块依赖
cat /proc/modules