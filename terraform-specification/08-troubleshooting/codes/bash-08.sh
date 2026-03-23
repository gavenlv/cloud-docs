# 1. 使用最小权限原则
# 只授予必要的权限
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# 2. 使用条件IAM
# 限制访问范围
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin" \
  --condition="title='Only from specific IP',expression='request.ip in ['1.2.3.4/32']"

# 3. 监控配额使用
# 设置配额告警
gcloud alpha monitoring policies create \
  --policy-from-file=quota-policy.yaml

# 4. 使用预检查
# 在部署前检查权限和配额
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes[] | select(.change.actions[] == "create")'