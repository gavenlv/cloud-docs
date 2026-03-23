# 查看文件ACL
getfacl /path/to/file

# 示例输出:
# # file: test.txt
# # owner: alice
# # group: alice
# user::rw-
# group::r--
# other::r--
# user:bob:rw-
# group:dev:r-x

# 设置ACL
setfacl -m u:bob:rw /path/to/file        # 设置用户bob读写权限
setfacl -m g:dev:r-x /path/to/file       # 设置组dev读执行权限
setfacl -m o::r /path/to/file            # 设置其他人只读权限
setfacl -m m::rwx /path/to/file          # 设置权限掩码

# 删除ACL条目
setfacl -x u:bob /path/to/file           # 删除用户bob的ACL
setfacl -x g:dev /path/to/file           # 删除组dev的ACL
setfacl -b /path/to/file                  # 删除所有扩展ACL

# 复制ACL
getfacl file1 | setfacl --set-file=- file2

# 目录默认ACL
setfacl -m d:u:bob:rw /path/to/dir       # 设置目录默认ACL
                                             # 该目录下新建文件自动继承

# 递归设置
setfacl -R -m u:bob:rw /path/to/dir      # 递归设置
setfacl -R -m d:u:bob:rw /path/to/dir   # 递归设置默认ACL