# 1. 检查文件权限
ls -la /path/to/file

# 2. 检查SELinux
getenforce
sestatus
ls -Z /path/to/file

# 3. 检查ACL
getfacl /path/to/file