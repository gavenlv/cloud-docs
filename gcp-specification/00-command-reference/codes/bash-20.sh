# 设置存储桶标签
gsutil label set label.json gs://my-bucket

# 获取存储桶标签
gsutil label get gs://my-bucket

# 设置生命周期
gsutil lifecycle set lifecycle.json gs://my-bucket

# 设置CORS配置
gsutil cors set cors.json gs://my-bucket

# 设置版本控制
gsutil versioning set on gs://my-bucket

# 设置访问权限（IAM）
gsutil iam ch allUsers:objectViewer gs://my-bucket