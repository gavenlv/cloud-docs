# 生成JSON格式的执行计划
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# 分析执行计划
cat plan.json | jq '.resource_changes[] | select(.change.actions[] == "create")'

# 查看资源变更
cat plan.json | jq '.resource_changes[] | {address: .address, actions: .change.actions}'