# 创建环境特定的变量文件
cat > terraform-dev.tfvars << 'EOF'
project_id      = "dev-project-id"
instance_count = 1
instance_type  = "e2-small"
environment    = "dev"
EOF

cat > terraform-staging.tfvars << 'EOF'
project_id      = "staging-project-id"
instance_count = 2
instance_type  = "e2-medium"
environment    = "staging"
EOF

cat > terraform-prod.tfvars << 'EOF'
project_id      = "prod-project-id"
instance_count = 3
instance_type  = "e2-highcpu-4"
environment    = "prod"
EOF

# 使用变量文件
terraform apply -var-file="terraform-dev.tfvars"
terraform apply -var-file="terraform-staging.tfvars"
terraform apply -var-file="terraform-prod.tfvars"