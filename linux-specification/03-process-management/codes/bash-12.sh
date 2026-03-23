# ulimit - shell级别的资源限制

# 查看当前限制
ulimit -a
# core file size          (blocks, -c)  0
# data seg size           (kbytes, -d)  unlimited
# file size               (blocks, -f)  unlimited
# pending signals                  (-i)  7424
# max locked memory       (kbytes, -l)  65536
# max memory size         (kbytes, -m)  unlimited
# open files                      (-n)  1024
# pipe size            (512 bytes, -p)  8
# POSIX message queues     (bytes, -q)  819200
# stack size              (kbytes, -s)  8192
# cpu time               (seconds, -t)  unlimited
# max user processes              (-u)  7424
# virtual memory          (kbytes, -v)  unlimited
# file locks                      (-x)  unlimited

# 设置限制
ulimit -n 2048         # 修改最大文件描述符
ulimit -u 100          # 修改最大用户进程数
ulimit -s 16384        # 修改栈大小

# 永久设置 (在/etc/security/limits.conf)
# username  soft   nofile  2048
# username  hard   nofile  4096