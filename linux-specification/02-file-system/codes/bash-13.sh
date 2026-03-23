# 场景: /projects目录,需要不同团队有不同权限

# 1. 查看目录结构
ls -la /projects
# drwxr-x-x  3 root root 4096 Mar 21 19:11 .
# drwxr-xr-x  2 root root 4096 Mar 21 19:11 ..
# drwxrws---  2 alice  project-a 4096 Mar 21 19:11 project-a
# drwxrws---  2 alice  project-b 4096 Mar 21 19:11 project-b

# 2. 查看当前ACL
getfacl /projects/project-a
# # file: project-a
# # owner: alice
# # group: project-a
# user::rwx
# group::r-x
# other::---

# 3. 设置ACL - 允许dev团队读写project-a
sudo setfacl -m g:dev:rw /projects/project-a

# 4. 验证
getfacl /projects/project-a
# user::rwx
# group::r-x
# group::dev:rw-
# mask::rwx
# other::---

# 5. 测试权限
# 以dev组用户身份
touch /projects/project-a/test.txt      # 应该成功
touch /projects/project-b/test.txt       # 应该失败 (Permission denied)

# 6. 查看权限是否生效
ls -la /projects/
# drwxrws---+ 2 alice  project-a 4096 Mar 21 19:11 project-a
#                                          ^
#                                          | ACL标记