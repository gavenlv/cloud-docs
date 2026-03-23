# 创建基础集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4

# 创建高可用集群
gcloud container clusters create my-cluster `
    --region=us-central1 `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10 `
    --enable-autorepair `
    --enable-autoupgrade `
    --workload-pool=PROJECT_ID.svc.id.goog

# 创建私有集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --enable-private-nodes `
    --master-ipv4-cidr=172.16.0.0/28 `
    --enable-ip-alias

# 创建GPU集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=2 `
    --machine-type=n1-standard-4 `
    --accelerator=type=nvidia-tesla-t4,count=1 `
    --image-type=UBUNTU `
    --boot-disk-size=100GB