# 1. 分析状态文件大小
terraform show -json | jq 'length'

# 2. 查找大资源
terraform state list | while read resource; do
  size=$(terraform state show "$resource" | wc -c)
  echo "$resource: $size bytes"
done | sort -k2 -n

# 3. 考虑拆分状态
# 将大型资源拆分到独立的状态文件

# 4. 使用state replace-provider
terraform state replace-provider \
  -auto-approve \
  hashicorp/google \
  hashicorp/google