# 创建密钥
gcloud iam service-accounts keys create key.json `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com

# 列出密钥
gcloud iam service-accounts keys list `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com

# 删除密钥
gcloud iam service-accounts keys delete KEY_ID `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com