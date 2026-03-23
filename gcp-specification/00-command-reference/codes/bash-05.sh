# 编辑实例（元数据、标签等）
gcloud compute instances update my-instance `
    --zone=us-central1-a `
    --metadata=ENV=prod `
    --tags=new-tag

# 添加标签
gcloud compute instances add-labels my-instance --zone=us-central1-a --labels=env=prod

# 修改机器类型（需要先停止）
gcloud compute instances set-machine-type my-instance --zone=us-central1-a --machine-type=n2-standard-8

# 修改服务账号
gcloud compute instances set-service-account my-instance --zone=us-central1-a --service-account=new-sa@PROJECT_ID.iam.gserviceaccount.com

# 设置.metadata文件
gcloud compute instances add-metadata my-instance --zone=us-central1-a --metadata-from-file=startup-script=startup.sh