# 列出磁盘
gcloud compute disks list

# 按区域筛选
gcloud compute disks list --filter="zone:us-central1-a"

# 查看磁盘详情
gcloud compute disks describe my-disk --zone=us-central1-a

# 创建磁盘
gcloud compute disks create my-disk `
    --zone=us-central1-a `
    --size=50GB `
    --type=pd-ssd

# 从快照创建磁盘
gcloud compute disks create new-disk `
    --zone=us-central1-a `
    --source-snapshot=my-snapshot `
    --type=pd-ssd

# 调整磁盘大小
gcloud compute disks resize my-disk --zone=us-central1-a --size=100GB

# 删除磁盘
gcloud compute disks delete my-disk --zone=us-central1-a