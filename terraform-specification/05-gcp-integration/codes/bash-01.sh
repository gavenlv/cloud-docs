# 1. 创建服务账号
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform"

# 输出：
# Created service account [terraform@my-project-id.iam.gserviceaccount.com].

# 2. 分配角色
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/editor"

# 或使用更细粒度的角色
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# 3. 创建密钥
gcloud iam service-accounts keys create terraform@my-project-id.iam.gserviceaccount.com \
  --key-file-type=json \
  --key-file=terraform-key.json

# 输出：
# created key [abcd1234] of type [json] as [terraform-key.json] for
# [terraform@my-project-id.iam.gserviceaccount.com].

# 4. 保护密钥文件
chmod 600 terraform-key.json
echo "terraform-key.json" >> .gitignore