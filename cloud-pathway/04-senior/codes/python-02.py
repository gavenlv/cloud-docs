import boto3
from datetime import datetime, timedelta

ce = boto3.client('ce')

def generate_cost_report():
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
    
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.strftime('%Y-%m-%d'),
            'End': end_date.strftime('%Y-%m-%d')
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {'Type': 'DIMENSION', 'Key': 'SERVICE'}
        ]
    )
    
    recommendations = []
    
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            
            if service == 'Amazon EC2' and cost > 1000:
                recommendations.append({
                    'service': service,
                    'recommendation': 'Consider Reserved Instances or Savings Plans',
                    'potential_savings': cost * 0.3
                })
                
    return recommendations