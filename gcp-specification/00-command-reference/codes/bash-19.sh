# 创建存储桶
gsutil mb -l us-central1 gs://my-bucket-name

# 创建存储桶（指定存储类型）
gsutil mb -c nearline -l us-central1 gs://my-bucket-name

# 删除空存储桶
gsutil rb gs://my-bucket-name

# 强制删除（含所有对象）
gsutil rm -r gs://my-bucket-name