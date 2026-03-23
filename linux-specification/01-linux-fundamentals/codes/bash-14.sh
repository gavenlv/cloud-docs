# 使用QEMU/KVM创建虚拟机

# 1. 安装QEMU
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system

# 2. 创建虚拟机
virt-install \
    --name ubuntu20.04 \
    --ram 2048 \
    --disk path=/var/lib/libvirt/images/ubuntu20.04.qcow2,size=20 \
    --vcpus 2 \
    --os-variant ubuntu20.04 \
    --network network=default \
    --graphics vnc \
    --cdrom /path/to/ubuntu20.04.iso

# 3. 查看虚拟机
virsh list --all
virsh start ubuntu20.04
virsh console ubuntu20.04