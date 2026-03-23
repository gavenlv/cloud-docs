# 共享内存 - 最高效的IPC方式,直接共享内存地址

# System V 共享内存

# 创建共享内存
ipcmk -M 1024
# or
# ipcs -m | grep shm

# 查看共享内存
ipcs -m
# ------ Shared Memory Segments --------
# key        shmid      owner      perms      bytes      nattch     status
# 0x00000000 0          root       600        1024       0

# 附加共享内存
shmid=$(ipcs -m | awk '/my_seg/ {print $2}')
shmat $shmid, NULL, 0

# 分离共享内存
shmdt $shmid

# 删除共享内存
ipcrm -m $shmid

# POSIX共享内存 (更现代的方式)
cat > shm_posix.c << 'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    const char *shm_name = "/my_shm";
    int shm_fd;
    void *ptr;
    
    // 创建共享内存对象
    shm_fd = shm_open(shm_name, O_CREAT | O_RDWR, 0666);
    ftruncate(shm_fd, 1024);
    
    // 映射到进程地址空间
    ptr = mmap(NULL, 1024, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    
    // 写入数据
    sprintf(ptr, "Hello from shared memory!");
    
    // 读取数据
    printf("Read from shared memory: %s\n", (char*)ptr);
    
    // 清理
    munmap(ptr, 1024);
    shm_unlink(shm_name);
    
    return 0;
}
EOF

gcc shm_posix.c -lrt -o shm_posix
./shm_posix