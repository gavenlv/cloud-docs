# 1. 查找大文件
du -sh /* 2>/dev/null | sort -rh | head -10
du -sh /var/* 2>/dev/null | sort -rh

# 2. 查找大目录
find / -type f -size +100M -exec ls -lh {} \;

# 3. 日志文件
journalctl --disk-usage
journalctl --vacuum-size=100M
du -sh /var/log

# 4. 清理旧内核 (Ubuntu)
apt autoremove --purge
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r)"/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'

# 5. 清理缓存
apt clean
yum clean all