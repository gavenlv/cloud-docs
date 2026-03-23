# 查看项目IAM策略
gcloud projects get-iam-policy PROJECT_ID --format=json

# 查看服务账号IAM策略
gcloud iam service-accounts get-iam-policy sa@PROJECT_ID.iam.gserviceaccount.com

# 查看资源IAM策略
gcloud pubsub topics get-iam-policy my-topic
gcloud storage buckets get-iam-policy gs://my-bucket