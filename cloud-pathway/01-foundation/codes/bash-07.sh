groupadd    创建组
groupadd developers

groupdel    删除组
groupdel developers

groupmod    修改组
groupmod -n newname oldname

groups      查看用户所属组
groups username

gpasswd     组管理员命令
gpasswd -a user group    添加用户到组
gpasswd -d user group    从组删除用户