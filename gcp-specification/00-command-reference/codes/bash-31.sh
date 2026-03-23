# 创建MySQL实例
gcloud sql instances create my-instance `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --storage-size=20GB `
    --storage-type=SSD `
    --availability-type=regional

# 创建PostgreSQL实例
gcloud sql instances create my-instance `
    --database-version=POSTGRES_14 `
    --tier=db-n1-standard-2 `
    --region=us-central1

# 创建高可用实例
gcloud sql instances create my-instance `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --availability-type=regional `
    --backup-start-time=02:00

# 创建只读副本
gcloud sql instances create my-replica `
    --master-instance-name=my-instance `
    --replica-type=READ `
    --region=us-east1