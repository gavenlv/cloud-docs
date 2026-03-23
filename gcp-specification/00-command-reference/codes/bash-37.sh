# 创建VPC网络 peering
gcloud compute networks peerings create my-peering `
    --network=my-vpc `
    --peer-network=other-vpc

# 列出peering
gcloud compute networks peerings list --network=my-vpc

# 启用peering流量
gcloud compute networks peerings update my-peering `
    --network=my-vpc `
    --export-custom-routes `
    --import-custom-routes