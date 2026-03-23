# 创建数据集
bq mk my_dataset

# 创建带位置的数据集
bq mk --location=us-central1 my_dataset

# 创建带访问控制的数据集
bq mk --dataset_id=my_dataset --description="My dataset" PROJECT

# 删除数据集
bq rm -r my_dataset

# 删除空数据集
bq rm my_dataset