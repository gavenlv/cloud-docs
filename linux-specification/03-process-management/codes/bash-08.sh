# 消息队列 - 发送包含类型的数据块

# 创建消息队列
ipcmk -q
# or
# msgget()

# 查看消息队列
ipcs -q
# ------ Message Queues --------
# key        msqid      owner      perms      used-bytes   messages
# 0x00000000 0          root       644        0            0

# 发送消息
cat > msg_send.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/msg.h>

struct msgbuf {
    long mtype;
    char mtext[100];
};

int main() {
    key_t key = ftok("/tmp", 'M');
    int msgid = msgget(key, IPC_CREAT | 0666);
    
    struct msgbuf msg;
    msg.mtype = 1;
    sprintf(msg.mtext, "Hello message queue!");
    
    msgsnd(msgid, &msg, sizeof(msg.mtext), 0);
    
    return 0;
}
EOF

cat > msg_recv.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/msg.h>

struct msgbuf {
    long mtype;
    char mtext[100];
};

int main() {
    key_t key = ftok("/tmp", 'M');
    int msgid = msgget(key, IPC_CREAT | 0666);
    
    struct msgbuf msg;
    msgrcv(msgid, &msg, sizeof(msg.mtext), 1, 0);
    
    printf("Received: %s\n", msg.mtext);
    
    // 删除消息队列
    msgctl(msgid, IPC_RMID, NULL);
    
    return 0;
}
EOF

gcc msg_send.c -o msg_send
gcc msg_recv.c -o msg_recv
./msg_send &
./msg_recv