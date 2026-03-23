# 使用环境变量传递敏感数据
export TF_VAR_db_password="my-secret-password"
terraform apply

# 或使用变量文件（不提交到版本控制）
cat > terraform.tfvars << 'EOF'
db_password = "my-secret-password"
EOF

# 添加到.gitignore
echo "terraform.tfvars" >> .gitignore
echo "*.auto.tfvars" >> .gitignore