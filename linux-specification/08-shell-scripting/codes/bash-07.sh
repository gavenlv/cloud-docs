# 文件测试
[ -e file ]       # 存在
[ -f file ]       # 普通文件
[ -d dir ]         # 目录
[ -r file ]        # 可读
[ -w file ]        # 可写
[ -x file ]        # 可执行
[ -L file ]        # 符号链接

# 字符串测试
[ -z "$str" ]     # 为空
[ -n "$str" ]     # 非空
[ "$a" == "$b" ]  # 相等
[ "$a" != "$b" ]  # 不等

# 数值测试
[ $a -eq $b ]     # 相等
[ $a -ne $b ]     # 不等
[ $a -gt $b ]     # 大于
[ $a -ge $b ]     # 大于等于
[ $a -lt $b ]     # 小于
[ $a -le $b ]     # 小于等于