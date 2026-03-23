# 列出数据集
bq ls

# 列出特定项目的数据集
bq ls --project_id=PROJECT_ID

# 查看数据集详情
bq show PROJECT:my_dataset

# 查看数据集访问控制
bq show --format=prettyjson PROJECT:my_dataset | grep access