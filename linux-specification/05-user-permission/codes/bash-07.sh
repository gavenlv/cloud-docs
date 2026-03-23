# 权限表示: rwx (读写执行)

# 字符表示
# r = 4 (可读)
# w = 2 (可写)
# x = 1 (可执行)
# - = 0 (无权限)

# 数字表示
# 7 = rwx (4+2+1)
# 6 = rw- (4+2)
# 5 = r-x (4+1)
# 4 = r-- (4)
# 3 = -wx (2+1)
# 2 = -w- (2)
# 1 = --x (1)
# 0 = --- (0)

# 示例:
chmod 755 file        # rwxr-xr-x
chmod 644 file        # rw-r--r--
chmod 700 file        # rwx------
chmod 600 file        # rw-------
chmod 750 dir         # rwxr-x---