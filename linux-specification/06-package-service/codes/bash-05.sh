# DNF (Fedora, RHEL 8+)
# 基础操作
dnf install package              # 安装包
dnf remove package               # 删除包
dnf update                       # 升级所有包
dnf update package               # 升级特定包
dnf check-update                 # 检查更新

# 查询
dnf search keyword
dnf info package
dnf list --installed
dnf list --available
dnf provides /path/to/file      # 找出提供文件的包

# 组操作
dnf group install "Development Tools"
dnf group list
dnf group remove "Development Tools"

# 仓库操作
dnf repolist                    # 列出仓库
dnf repoinfo                    # 仓库详情
dnf config-manager --add-repo=http://example.com/repo.repo

# 清理
dnf clean all                   # 清理缓存
dnf history                     # 查看操作历史

# YUM (RHEL 7及之前)
yum install package
yum remove package
yum update
yum check-update
yum search keyword
yum repolist