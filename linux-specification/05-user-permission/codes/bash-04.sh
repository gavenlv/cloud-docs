# /etc/shadow - 用户密码信息

cat /etc/shadow | head -5
# root:$6$salthash$:17650:0:99999:7:::
# user:$6$salthash$:18150:0:99999:7:::
# daemon:*:17985:0:99999:7:::

# 字段说明:
# 用户名:加密密码:最后修改日期:最小天数:最大天数:警告期:宽限期:失效期:保留
#
# 密码字段特殊值:
# *        - 账户禁用
# !        - 账户锁定
# !!       - 从未设置密码
# 空       - 无密码登录

# 密码时效管理
# 设置密码有效期
passwd -x 90 username              # 密码90天后过期
passwd -n 7 username               # 密码至少使用7天
passwd -w 7 username               # 提前7天警告
passwd -i 30 username              # 过期30天后禁用

# 查看密码状态
passwd -S username
# username P 03/21/2026 0 90 7 30
# 状态: P=有密码, NP=无密码, L=锁定

# 强制用户修改密码
chage -d 0 username                # 下次登录强制修改
chage -E 2026-12-31 username      # 设置账户过期日期