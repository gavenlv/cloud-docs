# 创建堆栈
aws cloudformation create-stack \
    --stack-name my-stack \
    --template-body file://template.yaml \
    --parameters ParameterKey=Environment,ParameterValue=prod

# 更新堆栈
aws cloudformation update-stack \
    --stack-name my-stack \
    --template-body file://template.yaml

# 删除堆栈
aws cloudformation delete-stack \
    --stack-name my-stack

# 查看堆栈状态
aws cloudformation describe-stacks \
    --stack-name my-stack

# 查看堆栈事件
aws cloudformation describe-stack-events \
    --stack-name my-stack