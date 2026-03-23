# 创建实例模板
gcloud compute instance-templates create my-template `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB `
    --boot-disk-type=pd-ssd

# 创建带自定义网络的模板
gcloud compute instance-templates create my-template `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --network=my-vpc `
    --subnet=my-subnet

# 列出模板
gcloud compute instance-templates list

# 查看模板详情
gcloud compute instance-templates describe my-template

# 使用模板创建实例组
gcloud compute instance-groups managed create my-group `
    --zone=us-central1-a `
    --template=my-template `
    --size=3

# 更新实例组大小
gcloud compute instance-groups managed resize my-group --zone=us-central1-a --size=5

# 删除模板
gcloud compute instance-templates delete my-template