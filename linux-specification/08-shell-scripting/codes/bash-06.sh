# test表达式
test -f file && echo "file exists"
test -d dir && echo "dir exists"
test -z "$var" && echo "var is empty"

# [] 语法
[ -f file ] && echo "file exists"
[ $a -eq $b ] && echo "equal"

# [[]] 扩展 (Bash)
[[ -f file ]] && echo "file exists"
[[ $name == "john" ]] && echo "matched"