# 创建组
groupadd groupname                  # 创建组
groupadd -g 1500 groupname         # 指定GID

# 修改组
groupmod -n newname oldname        # 修改组名
groupmod -g 1500 groupname         # 修改GID

# 删除组
groupdel groupname

# 管理组成员
gpasswd -a user groupname          # 添加成员
gpasswd -d user groupname          # 删除成员
gpasswd -A user groupname          # 设置管理员
gpasswd -M user1,user2 groupname   # 设置所有成员(覆盖)

# groups命令
groups                              # 当前用户的组
groups username                     # 指定用户的组