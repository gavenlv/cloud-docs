# 1. 验证状态文件位置
terraform output -json | jq '.backend'

# 2. 验证状态文件内容
terraform show -json | jq '.resources | length'

# 3. 验证资源依赖关系
terraform graph | dot -Tpng > graph.png

# 4. 验证状态锁定
# 在终端1
terraform apply -auto-approve

# 在终端2（应该失败）
terraform apply -auto-approve
# Error acquiring the state lock

# 5. 验证状态刷新
terraform refresh
terraform plan
# 应该显示：No changes. Infrastructure is up-to-date.

# 6. 验证状态备份
gsutil ls gs://my-terraform-state/prod/
# terraform.tfstate
# terraform.tfstate.backup