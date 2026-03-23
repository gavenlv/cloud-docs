# 批量创建实例
gcloud compute instances create instance-{1,2,3} `
    --zone=us-central1-a `
    --machine-type=e2-medium

# 批量停止实例
gcloud compute instances stop instance-{1,2,3} --zone=us-central1-a

# 使用脚本批量操作
for i in {1..10}; do
    gcloud compute instances delete instance-$i --zone=us-central1-a --quiet
done