aws s3api put-bucket-versioning \
    --bucket my-bucket \
    --versioning-configuration Status=Enabled

aws s3api list-object-versions \
    --bucket my-bucket \
    --prefix file.txt