import boto3

cloudwatch = boto3.client('cloudwatch')

def analyze_instance_utilization(instance_id, period=7):
    metrics = {
        'CPU': get_metric_statistics(
            namespace='AWS/EC2',
            metric_name='CPUUtilization',
            dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
            period=86400,
            statistics=['Average', 'Maximum']
        ),
        'Network': get_metric_statistics(
            namespace='AWS/EC2',
            metric_name='NetworkIn',
            dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
            period=86400,
            statistics=['Average', 'Maximum']
        )
    }
    
    recommendations = []
    
    if metrics['CPU']['Average'] < 10:
        recommendations.append('Instance is underutilized, consider downsizing')
    elif metrics['CPU']['Average'] > 80:
        recommendations.append('Instance is overutilized, consider upsizing')
        
    return recommendations