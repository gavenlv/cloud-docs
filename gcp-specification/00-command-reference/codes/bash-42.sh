# 创建服务账号
gcloud iam service-accounts create my-sa `
    --display-name="My Service Account" `
    --description="Service account for my application"

# 列出服务账号
gcloud iam service-accounts list

# 查看服务账号详情
gcloud iam service-accounts describe sa@PROJECT_ID.iam.gserviceaccount.com

# 更新服务账号
gcloud iam service-accounts update sa@PROJECT_ID.iam.gserviceaccount.com `
    --display-name="New Name"

# 删除服务账号
gcloud iam service-accounts delete sa@PROJECT_ID.iam.gserviceaccount.com