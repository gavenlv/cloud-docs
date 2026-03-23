# 更新服务配置
gcloud run services update my-service `
    --region us-central1 `
    --min-instances=2 `
    --max-instances=100 `
    --concurrency=100

# 更新环境变量
gcloud run services update my-service `
    --region us-central1 `
    --set-env-vars NEW_VAR=value

# 移除环境变量
gcloud run services update my-service --region us-central1 --remove-env-vars OLD_VAR

# 流量控制
gcloud run services update-traffic my-service `
    --region us-central1 `
    --to-revisions=my-service-00002-xyz=80,my-service-00001-abc=20

# 删除服务
gcloud run services delete my-service --region us-central1