# 查看远程状态
terraform show

# 查看状态文件位置
terraform output -json | jq '.outputs'

# 测试状态锁定
terraform apply -auto-approve
# 应该成功获取GCS锁

# 在另一个终端测试
terraform apply -auto-approve
# 应该报错：Error acquiring the state lock