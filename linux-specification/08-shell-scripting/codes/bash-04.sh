# $0 - 脚本名
# $1-$9 - 位置参数
# $# - 参数个数
# $@ - 所有参数
# $* - 所有参数(作为字符串)
# $$ - 当前进程ID
# $? - 上个命令退出状态

cat > args.sh << 'EOF'
#!/bin/bash
echo "Script: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "Arg count: $#"
echo "PID: $$"
EOF

chmod +x args.sh
./args.sh hello world