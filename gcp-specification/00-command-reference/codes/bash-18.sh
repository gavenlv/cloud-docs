# 列出所有存储桶
gsutil ls

# 列出特定前缀的存储桶
gsutil ls gs://my-bucket-*/

# 查看存储桶详情
gsutil ls -L gs://my-bucket

# 查看存储桶元数据
gsutil ls -s gs://my-bucket

# 获取存储桶URL
gsutil ls -b gs://my-bucket