import boto3

cloudwatch = boto3.client('cloudwatch')

def put_custom_metric():
    cloudwatch.put_metric_data(
        Namespace='MyApplication',
        MetricData=[
            {
                'MetricName': 'RequestCount',
                'Dimensions': [
                    {
                        'Name': 'Service',
                        'Value': 'API'
                    }
                ],
                'Value': 1,
                'Unit': 'Count'
            }
        ]
    )