if [ condition ]; then
    commands
elif [ condition ]; then
    commands
else
    commands
fi

条件测试：
[ -f file ]        文件存在且是普通文件
[ -d dir ]         目录存在
[ -r file ]        文件可读
[ -w file ]        文件可写
[ -x file ]        文件可执行
[ -z string ]      字符串为空
[ -n string ]      字符串非空
[ $a -eq $b ]      整数相等
[ $a -ne $b ]      整数不等
[ $a -gt $b ]      大于
[ $a -lt $b ]      小于