# 特殊设备:
# /dev/null   - 丢弃所有写入的数据
# /dev/zero   - 提供无限零字节
# /dev/random - 提供加密安全的随机数
# /dev/urandom - 提供非阻塞随机数
# /dev/full   - 总是报告磁盘满
# /dev/null   - 黑洞设备

# 使用示例
cat /dev/zero | head -c 100 > /dev/null   # 丢弃
dd if=/dev/zero of=testfile bs=1M count=100  # 创建100MB零文件
cat /dev/random | tr -dc 'a-zA-Z0-9' | head -c 32  # 生成随机字符串

# 创建loop设备
sudo losetup -f                           # 查找空闲loop设备
sudo losetup /dev/loop0 /path/to/image   # 关联文件到loop设备
sudo losetup -d /dev/loop0               # 解除关联