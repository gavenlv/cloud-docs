# exec - 替换进程映像
# 用新程序替换当前进程的代码和数据

cat > exec_example.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("原程序: PID=%d\n", getpid());
    
    char *args[] = {"ls", "-la", NULL};
    execvp("ls", args);  // 替换当前进程映像
    
    // 如果execvp返回，说明执行失败
    perror("execvp failed");
    return 1;
}
EOF

gcc exec_example.c -o exec_example
./exec_example