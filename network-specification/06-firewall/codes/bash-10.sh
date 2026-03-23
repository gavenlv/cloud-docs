# firewalld是CentOS/RHEL 7+的默认防火墙管理工具
# 基于zone概念

# 查看状态
systemctl status firewalld
firewall-cmd --state

# 查看默认zone
firewall-cmd --get-default-zone

# 查看活动zone
firewall-cmd --get-active-zones

# 列出规则
firewall-cmd --list-all
firewall-cmd --list-all --zone=public

# 添加服务
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent

# 添加端口
firewall-cmd --add-port=8080/tcp --permanent

# 重载配置
firewall-cmd --reload

# 常用zone:
# drop: 丢弃所有
# block: 拒绝所有
# public: 公共网络
# external: 外部网络 (NAT)
# dmz: 非军事区
# work: 工作网络
# home: 家庭网络
# internal: 内部网络
# trusted: 信任所有