# 列出VPC
gcloud compute networks list

# 查看VPC详情
gcloud compute networks describe my-vpc

# 列出子网
gcloud compute networks subnets list

# 列出特定VPC的子网
gcloud compute networks subnets list --network=my-vpc