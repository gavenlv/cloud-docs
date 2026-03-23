import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    # 1. 连接复用 - 在handler外初始化客户端
    
    # 2. 环境变量存储配置
    config_value = os.environ.get('CONFIG_VALUE')
    
    # 3. 适当的日志级别
    print(f"Processing event: {json.dumps(event)}")
    
    # 4. 错误处理
    try:
        response = table.get_item(
            Key={'id': event['id']}
        )
        return response['Item']
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e

# 5. 冷启动优化 - 使用更小的部署包
# 6. 使用Lambda Layers共享代码
# 7. 合理设置内存和超时