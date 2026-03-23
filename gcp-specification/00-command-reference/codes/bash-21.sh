# 上传单个文件
gsutil cp file.txt gs://my-bucket/

# 上传文件夹
gsutil cp -r ./folder gs://my-bucket/

# 上传带元数据
gsutil cp -h "Content-Type:text/html" file.txt gs://my-bucket/

# 下载文件
gsutil cp gs://my-bucket/file.txt ./

# 下载整个桶
gsutil cp -r gs://my-bucket/ ./

# 并行上传（提高速度）
gsutil -m cp -r ./large-folder gs://my-bucket/