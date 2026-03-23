# 创建自动模式VPC
gcloud compute networks create auto-vpc --subnet-mode=auto

# 创建自定义模式VPC
gcloud compute networks create custom-vpc --subnet-mode=custom

# 创建子网
gcloud compute networks subnets create my-subnet `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24

# 创建带私有IP的子网
gcloud compute networks subnets create my-subnet `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24 `
    --enable-private-ip-google-access