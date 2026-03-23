# 基础部署
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# 部署带环境变量
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --set-env-vars ENV=prod,VERSION=1.0.0 `
    --allow-unauthenticated

# 部署带内存和超时配置
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --memory=512Mi `
    --timeout=300 `
    --concurrency=80 `
    --max-instances=100 `
    --min-instances=2

# 部署带VPC连接
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --vpc-connector=my-connector `
    --vpc-egress=all-traffic

# 从源部署（Cloud Build）
gcloud run deploy my-service `
    --source . `
    --region us-central1 `
    --platform managed