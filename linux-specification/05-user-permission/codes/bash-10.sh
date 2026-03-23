# 完整权限示例

# SUID + owner(rwx) + SGID + group(rx) + Sticky + other(rx)
chmod 5755 file       # SUID设置
ls -l file
# -rwsr-xr-x ...  <- SUID (s), others的x是执行

# SGID + group(rwx) + Sticky + other(rx)
chmod 3755 file       # SGID设置
ls -l file
# -rwxr-sr-x ...  <- SGID (s)

# SUID + SGID + Sticky
chmod 7755 file
ls -l file
# -rwsr-sr-t ...  <- SUID (s), SGID (s), Sticky (t)

# 查看特殊权限
stat file | grep Access
# Access: (4755/-rwsr-xr-x)