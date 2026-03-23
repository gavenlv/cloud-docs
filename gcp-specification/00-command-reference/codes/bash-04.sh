# 创建基础实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud

# 创建带自定义配置实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=50GB `
    --boot-disk-type=pd-ssd `
    --subnet=my-subnet `
    --network-tier=PREMIUM `
    --tags=http-server,https-server `
    --metadata=startup-script='#!/bin/bash echo "Hello" > /var/www/html/index.html'

# 创建带服务账号实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --service-account=my-sa@PROJECT_ID.iam.gserviceaccount.com `
    --scopes=cloud-platform

# 创建带GPU实例
gcloud compute instances create gpu-instance `
    --zone=us-central1-a `
    --accelerator=type=nvidia-tesla-t4,count=1 `
    --machine-type=n1-standard-4 `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=100GB `
    --boot-disk-type=pd-ssd

# 从模板创建实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --source-instance-template=my-template

# 试运行（不实际创建）
gcloud compute instances create my-instance --zone=us-central1-a --dry-run