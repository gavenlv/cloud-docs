# 目录结构
environments/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars

# dev/terraform.tfvars
project_id      = "dev-project-id"
instance_count = 1
instance_type  = "e2-small"

# staging/terraform.tfvars
project_id      = "staging-project-id"
instance_count = 2
instance_type  = "e2-medium"

# prod/terraform.tfvars
project_id      = "prod-project-id"
instance_count = 3
instance_type  = "e2-highcpu-4"

# 使用
cd environments/dev
terraform apply -var-file="terraform.tfvars"

cd environments/staging
terraform apply -var-file="terraform.tfvars"

cd environments/prod
terraform apply -var-file="terraform.tfvars"