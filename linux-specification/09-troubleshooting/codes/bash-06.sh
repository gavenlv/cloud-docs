# 查看inode使用
df -i

# 查找inode占用
for dir in /*; do
    echo "$dir: $(find $dir -type f | wc -l)"
done

# 找出大量小文件的目录
find / -type d -exec sh -c 'echo "$(find {} -type f | wc -l) $dir"' _ {} \;