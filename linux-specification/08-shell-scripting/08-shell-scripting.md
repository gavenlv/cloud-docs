# Shell脚本编程

## 本章导学

**学完本章后，你将能够：**

- 理解Bash的**工作原理**和执行环境
- 掌握Shell变量、参数传递和 expansions
- 熟练使用条件判断和循环结构
- 理解函数和数组的使用
- 从**Shell解释器角度**理解脚本是如何被解析和执行的

**学习方法：**

```
Shell基础 → 变量和参数 → 条件判断 → 循环结构 → 函数 → 实战脚本
```

---

# 1. Shell基础

## 1.1 Shell执行原理

```bash
# Shell是命令解释器
# 流程: 读取命令 → 解析 → 执行 → 返回结果

# Shell类型
echo $SHELL              # 当前shell
cat /etc/shells          # 可用shell列表
# /bin/bash, /bin/sh, /bin/zsh, /bin/fish

# Bash执行流程
cat > debug.sh << 'EOF'
#!/bin/bash
set -x                  # 开启调试
echo "Hello"
set +x                  # 关闭调试
EOF

chmod +x debug.sh
./debug.sh
```

## 1.2 Shell选项

```bash
# 常用set选项
set -e                  # 遇错退出
set -u                  # 使用未定义变量报错
set -n                  # 检查语法不执行
set -v                  # 显示输入行
set -x                  # 显示命令和参数

# 使用shopt设置
shopt -s extglob        # 开启扩展通配符
shopt -u extglob        # 关闭扩展通配符
shopt | head            # 查看所有选项
```

---

# 2. 变量和参数

## 2.1 变量基础

```bash
# 变量定义
name="John"
age=30

# 变量引用
echo $name
echo ${name}

# 只读变量
readonly PI=3.14159
# PI=3.14  # 报错

# 删除变量
unset name
```

## 2.2 特殊变量

```bash
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
```

## 2.3 变量展开

```bash
# 默认值
${var:-default}         # var为空时使用default
${var:=default}         # var为空时赋值default

# 字符串操作
${#var}                 # 字符串长度
${var:offset}          # 切片
${var:offset:length}   # 切片指定长度
${var#pattern}          # 最短匹配删除
${var##pattern}         # 最长匹配删除
${var%pattern}          # 从结尾最短匹配删除
${var%%pattern}         # 从结尾最长匹配删除
${var/pattern/string}   # 替换第一个
${var//pattern/string}  # 替换所有
```

---

# 3. 条件判断

## 3.1 test命令

```bash
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
```

## 3.2 常用测试

```bash
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
```

## 3.3 if语句

```bash
if [ condition ]; then
    commands
elif [ condition ]; then
    commands
else
    commands
fi
```

---

# 4. 循环结构

## 4.1 for循环

```bash
# C风格
for ((i=0; i<10; i++)); do
    echo $i
done

# 列表
for item in apple banana cherry; do
    echo $item
done

# 遍历文件
for f in *.txt; do
    echo "Processing $f"
done
```

## 4.2 while循环

```bash
# 读取行
while read line; do
    echo "$line"
done < file.txt

# 条件循环
count=0
while [ $count -lt 5 ]; do
    echo $count
    ((count++))
done
```

---

# 5. 函数

## 5.1 函数定义和调用

```bash
# 定义
function hello() {
    echo "Hello, $1"
}

hello World

# 返回值
function get_sum() {
    local sum=$(( $1 + $2 ))
    echo $sum
}

result=$(get_sum 3 5)
echo $result
```

## 5.2 函数参数

```bash
function process() {
    echo "Args: $@"
    echo "Count: $#"
    for arg in "$@"; do
        echo "Arg: $arg"
    done
}
```

---

# 6. 数组

## 6.1 数组基础

```bash
# 定义
arr=(one two three)
arr[0]=one
arr[1]=two

# 访问
echo ${arr[0]}
echo ${arr[@]}          # 所有元素
echo ${#arr[@]}         # 长度
echo ${!arr[@]}         # 索引

# 添加
arr+=(four five)
```

## 6.2 关联数组

```bash
declare -A person
person[name]="John"
person[age]=30
echo ${person[name]}
```

---

# 7. 常用命令

## 7.1 文本处理

```bash
# grep - 搜索
grep pattern file
grep -r pattern dir
grep -i pattern file

# sed - 替换
sed 's/old/new/g' file
sed -i 's/old/new/g' file

# awk - 文本处理
awk '{print $1}' file
awk -F: '{print $1}' /etc/passwd
```

## 7.2 脚本示例

```bash
cat > backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/backup"
SOURCE_DIR="/data"
DATE=$(date +%Y%m%d)

tar czf "$BACKUP_DIR/backup-$DATE.tar.gz" "$SOURCE_DIR"
echo "Backup completed: backup-$DATE.tar.gz"
EOF

chmod +x backup.sh
```

---

## 本章小结

- Shell是命令解释器,Bash是最常用的Shell
- 变量用于存储数据,特殊变量($@, $#, $?)处理参数
- 条件判断使用test/[ ]/[[ ]]
- 循环结构包括for、while、until
- 函数封装代码,数组存储多个值

**关键命令回顾:**

```bash
echo, read, test, [, [[, for, while, until, case, function, set, shopt
```