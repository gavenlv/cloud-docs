# 列出节点池
gcloud container node-pools list --cluster=my-cluster --zone=us-central1-a

# 创建节点池
gcloud container node-pools create my-nodepool `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4

# 创建GPU节点池
gcloud container node-pools create gpu-nodepool `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --num-nodes=2 `
    --machine-type=n1-standard-4 `
    --accelerator=type=nvidia-tesla-t4,count=1

# 删除节点池
gcloud container node-pools delete my-nodepool --cluster=my-cluster --zone=us-central1-a