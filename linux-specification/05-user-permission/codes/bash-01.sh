# 进程的用户身份

# 查看当前进程的用户信息
id
# uid=1000(user) gid=1000(user) groups=1000(user),4(adm),27(sudo)

# 查看进程的有效/实际用户
cat /proc/self/status | grep -E "^(Uid|Gid)"
# Uid:    1000    1000    1000    1000   (实际/有效/保存 set/文件系统)
# Gid:    1000    1000    1000    1000

# 有效用户 vs 实际用户
# 实际用户 (ruid): 登录时的用户
# 有效用户 (euid): 当前使用的用户身份 (用于权限检查)
# 保存的用户 (suid): 保存的用户ID (用于切换回原用户)
# 文件系统用户 (fsuid): 用于文件系统操作

# 示例: sudo
cat > check_ids.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("UID:  real=%d, effective=%d, saved=%d\n",
           getuid(), geteuid(), getuid());
    printf("GID:  real=%d, effective=%d, saved=%d\n",
           getgid(), getegid(), getgid());
    return 0;
}
EOF

gcc check_ids.c -o check_ids
./check_ids
sudo ./check_ids
# UID:  real=1000, effective=1000, saved=1000
# UID:  real=0, effective=0, saved=1000  <- sudo提升了euid