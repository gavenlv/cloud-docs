# 列出路由
gcloud compute routes list

# 创建路由
gcloud compute routes create my-route `
    --network=my-vpc `
    --destination-range=192.168.0.0/24 `
    --next-hop-gateway=default-internet-gateway

# 删除路由
gcloud compute routes delete my-route