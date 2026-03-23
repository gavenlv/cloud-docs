#!/bin/bash
# scripts/apply.sh

set -e

# 设置环境变量
export TF_VAR_project_id="${TF_VAR_project_id:-my-project-id}"
export TF_VAR_region="${TF_VAR_region:-us-central1}"

# 初始化
terraform init

# 格式化代码
terraform fmt -check

# 验证配置
terraform validate

# 查看执行计划
terraform plan -out=tfplan

# 应用配置
terraform apply tfplan

# 输出结果
terraform output -json > outputs.json

echo "Terraform apply completed successfully"