# 安装Terraform
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows (使用Chocolatey)
choco install terraform

# 验证安装
terraform version
# Terraform v1.5.0

# 配置GCP认证
export GOOGLE_CREDENTIALS=$(cat ~/path/to/service-account-key.json)
# 或使用 Application Default Credentials
gcloud auth application-default login