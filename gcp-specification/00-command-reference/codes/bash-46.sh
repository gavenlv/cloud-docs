# 测试连通性
gcloud compute ssh instance-name --zone=us-central1-a -- command="ping -c 4 8.8.8.8"

# 查看防火墙规则
gcloud compute firewall-rules list --filter="network:my-vpc AND disabled=false"

# 查看实例网络接口
gcloud compute instances describe instance-name --zone=us-central1-a --format="yaml(networkInterfaces)"

# 测试VPC peering
gcloud compute networks peerings list --network=my-vpc