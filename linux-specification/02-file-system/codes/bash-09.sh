# 创建硬链接
ln /path/to/source /path/to/hardlink

# 创建软链接
ln -s /path/to/source /path/to/symlink

# 示例
touch original.txt
ln original.txt hardlink.txt
ln -s original.txt symlink.txt

# 查看
ls -li original.txt hardlink.txt symlink.txt
# 1310813 -rw-r--r-- 2 user group  0 Mar 21 19:11 original.txt
# 1310813 -rw-r--r-- 1 user group  0 Mar 21 19:11 hardlink.txt    # 同一inode
# 1310814 lrwxrwxrwx 1 user group 11 Mar 21 19:11 symlink.txt -> original.txt  # 软链接

# 查看链接指向
readlink symlink.txt
readlink -f symlink.txt                # 解析最终目标

# 删除原文件测试
rm original.txt
cat hardlink.txt                       # 仍可访问
cat symlink.txt                        # 报错: No such file or directory

# 目录链接计数
mkdir /tmp/testdir
ls -ld /tmp/testdir
# 目录的链接数 = 2 + 子目录数 (每个子目录包含 .. 指向父目录)