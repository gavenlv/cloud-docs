# 添加项目级IAM策略
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# 添加服务账号角色
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=serviceAccount:sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/editor

# 移除IAM策略
gcloud projects remove-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# 为资源添加IAM
gcloud storage buckets add-iam-policy-binding gs://my-bucket `
    --member=user:email@example.com `
    --role=roles/storage.objectViewer