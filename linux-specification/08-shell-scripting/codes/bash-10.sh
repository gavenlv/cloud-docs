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