# 查看实例详情
gcloud compute instances describe instance-name --zone=us-central1-a

# 获取内网IP
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(networkInterfaces[0].networkIP)"

# 获取外网IP
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(networkInterfaces[0].accessConfigs[0].natIP)"

# 获取实例状态
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(status)"

# 获取机器类型
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(machineType)" | cut -d'/' -f5

# 获取启动脚本输出
gcloud compute instances get-serial-port-output instance-name --zone=us-central1-a