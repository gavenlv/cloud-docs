# 列出对象
gsutil ls gs://my-bucket/

# 列出带详情的对象
gsutil ls -l gs://my-bucket/

# 重命名对象
gsutil mv gs://my-bucket/old.txt gs://my-bucket/new.txt

# 复制对象
gsutil cp gs://my-bucket/file1.txt gs://my-bucket/backup/file1.txt

# 删除对象
gsutil rm gs://my-bucket/file.txt

# 删除所有对象
gsutil rm gs://my-bucket/**

# 同步文件夹
gsutil rsync -r ./local-folder gs://my-bucket/