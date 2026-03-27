#!/bin/bash
# Secret Manager基本操作示例

# 创建密钥
gcloud secrets create my-api-key --data-file=./api-key.txt

# 从标准输入创建密钥
echo -n "my-secret-value" | gcloud secrets create my-secret --data-file=-

# 列出所有密钥
gcloud secrets list

# 查看密钥详情
gcloud secrets describe my-secret

# 访问密钥值
gcloud secrets versions access latest --secret=my-secret

# 添加新版本
gcloud secrets versions add my-secret --data-file=./new-value.txt

# 查看所有版本
gcloud secrets versions list my-secret

# 禁用版本
gcloud secrets versions disable 1 --secret=my-secret

# 启用版本
gcloud secrets versions enable 1 --secret=my-secret

# 删除密钥
gcloud secrets delete my-secret --quiet
