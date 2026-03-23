# 创建快照
gcloud compute snapshots create my-snapshot `
    --source-disk=my-disk `
    --source-zone=us-central1-a

# 列出快照
gcloud compute snapshots list

# 查看快照详情
gcloud compute snapshots describe my-snapshot

# 删除快照
gcloud compute snapshots delete my-snapshot

# 从快照创建磁盘
gcloud compute disks create my-new-disk `
    --zone=us-central1-a `
    --source-snapshot=my-snapshot