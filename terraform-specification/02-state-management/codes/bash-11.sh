# 手动备份
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 自动备份（使用terraform init）
terraform init -backend-config="backup=true"

# GCS自动备份
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
  }
}

# GCS会自动创建备份：
# gs://my-terraform-state/prod/terraform.tfstate
# gs://my-terraform-state/prod/terraform.tfstate.backup