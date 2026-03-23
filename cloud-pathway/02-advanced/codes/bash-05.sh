aws rds create-db-instance-read-replica \
    --db-instance-identifier mydb-replica \
    --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:mydb