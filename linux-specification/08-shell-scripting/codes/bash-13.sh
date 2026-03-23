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