# 生成签名URL（1小时有效）
gsutil signurl -d 1h key.json gs://my-bucket/file.txt

# 生成带自定义方法的签名URL
gsutil signurl -d 1h -m GET key.json gs://my-bucket/file.txt