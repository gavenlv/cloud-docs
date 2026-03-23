# 列出防火墙规则
gcloud compute firewall-rules list

# 按网络筛选
gcloud compute firewall-rules list --filter="network:my-vpc"

# 查看规则详情
gcloud compute firewall-rules describe allow-ssh

# 创建规则
gcloud compute firewall-rules create allow-ssh `
    --network=my-vpc `
    --allow=tcp:22 `
    --source-ranges=0.0.0.0/0

# 创建允许内部流量的规则
gcloud compute firewall-rules create allow-internal `
    --network=my-vpc `
    --allow=tcp:0-65535,udp:0-65535,icmp `
    --source-ranges=10.0.0.0/8

# 更新规则
gcloud compute firewall-rules update allow-ssh --disabled=false

# 删除规则
gcloud compute firewall-rules delete allow-ssh