aws rds create-db-instance \
    --db-instance-identifier mydb \
    --db-instance-class db.t3.medium \
    --engine mysql \
    --master-username admin \
    --master-user-password password \
    --allocated-storage 100 \
    --multi-az \
    --backup-retention-period 7