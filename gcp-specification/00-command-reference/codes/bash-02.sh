# 获取所有实例
gcloud compute instances list

# 获取特定项目的实例
gcloud compute instances list --project=PROJECT_ID

# 按区域筛选
gcloud compute instances list --filter="zone:us-central1-a"

# 按名称筛选
gcloud compute instances list --filter="name~my-instance*"

# 宽表输出（增加显示列）
gcloud compute instances list --format="table(name,status,machine_type,zone)"

# 只获取名称列表
gcloud compute instances list --format="value(name)"

# 统计实例数量
gcloud compute instances list --format="value(name)" | wc -l