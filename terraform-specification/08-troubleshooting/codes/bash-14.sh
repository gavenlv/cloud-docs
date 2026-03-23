# 1. 使用IDE插件
# VS Code插件：hashicorp.terraform
# 语法高亮
# 自动补全
# 错误提示

# 2. 使用pre-commit钩子
# 在提交前验证
#!/bin/bash
terraform fmt -check
terraform validate

# 3. 使用CI/CD验证
# 在PR中验证
name: Terraform Validate
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check
      - run: terraform validate

# 4. 使用版本约束
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}