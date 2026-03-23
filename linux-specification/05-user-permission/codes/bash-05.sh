# /etc/group - 组账户信息

cat /etc/group | head -5
# root:x:0:
# daemon:x:1:
# bin:x:2:
# sys:x:3:
# user:x:1000:user1,user2

# 字段说明:
# 组名:密码占位符:GID:成员列表(逗号分隔)

# 查看组
getent group
getent group groupname
groups username                     # 用户所属的组
groupmems -g groupname -l          # 组成员列表