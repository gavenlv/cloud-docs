# 查询并保存到表
bq query --destination_table=my_dataset.result_table "SELECT * FROM my_dataset.my_table"

# 查询并写入存储桶
bq extract my_dataset.my_table gs://bucket/output.csv

# 估算查询费用
bq query --dry_run "SELECT COUNT(*) FROM my_dataset.my_table"

# 查看查询计划
bq query --explain=compute "SELECT * FROM my_dataset.my_table"