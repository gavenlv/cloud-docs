# 方法1：使用terraform init -migrate-state
terraform init \
  -migrate-state \
  -backend-config="bucket=my-terraform-state" \
  -backend-config="prefix=prod"

# 输出：
# Initializing the backend...
# Do you want to copy existing state to the new backend?
#   Pre-existing state was found at "terraform.tfstate" while migrating
#   to "gcs". No existing state was found at "gcs".
#   Do you want to copy the state from "terraform.tfstate" to the new backend?
#   Enter a value: yes
#
# Successfully configured the backend "gcs"! Terraform will automatically
# use this backend unless you change configuration or run `terraform init` again.

# 方法2：手动迁移
# 1. 备份本地状态
cp terraform.tfstate terraform.tfstate.backup

# 2. 上传状态到GCS
gsutil cp terraform.tfstate gs://my-terraform-state/prod/terraform.tfstate

# 3. 删除本地状态
rm terraform.tfstate

# 4. 初始化远程后端
terraform init

# 5. 验证状态
terraform state list