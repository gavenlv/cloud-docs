# prlimit - 查看/设置特定进程的资源限制

# 查看进程限制
prlimit --pid PID

# 示例
prlimit --pid $$   # 当前shell
# RESOURCE DESCRIPTION              SOFT              HARD
# CPU        unlimited              unlimited         []
# FSIZE      unlimited              unlimited         []
# DATA       unlimited              unlimited         []
# STACK      8388608                unlimited         []
# CORE       0                      unlimited         []
# NPROC      7424                   unlimited         []
# NOFILE     1024                   1048576           []
# MEMLOCK    65536                  65536             []
# ...

# 修改进程限制
prlimit --pid PID --nproc 100:200
prlimit --pid PID --nofile 2048:4096

# 在进程启动时设置限制
cat > limit_demo.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>

int main() {
    struct rlimit lim;
    
    // 获取当前限制
    getrlimit(RLIMIT_NOFILE, &lim);
    printf("NOFILE soft=%ld hard=%ld\n", lim.rlim_cur, lim.rlim_max);
    
    // 设置新限制
    lim.rlim_cur = 2048;
    lim.rlim_max = 4096;
    setrlimit(RLIMIT_NOFILE, &lim);
    
    return 0;
}
EOF

gcc limit_demo.c -o limit_demo
./limit_demo