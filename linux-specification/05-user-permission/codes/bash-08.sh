# 符号方式
chmod u+x file                # owner添加执行权限
chmod g-x file                # group移除执行权限
chmod o+r file                # others添加读取权限
chmod a+x file                # 所有用户添加执行权限
chmod +x file                 # 同a+x

# 组合
chmod u+rwx,g+rx,o+r file    # rwxr-xr--
chmod u=rw,g=r,o= file        # rw-r-----

# 移除所有权限
chmod a-rwx file
chmod = file                   # 清空所有权限

# 递归修改
chmod -R 755 /path/to/dir

# 参考另一个文件的权限
chmod --reference=file1 file2

# 权限组合示例
chmod 1777 /tmp                # 1777 = rwsrwxrwt (Sticky Bit)
chmod 2755 /path               # 2755 = rwxr-sr-x (SGID)
chmod 4755 /path               # 4755 = rwsr-xr-x (SUID)