# Cloud Function：智能开关机
import functions_framework
from google.cloud import compute_v1
from datetime import datetime
import pytz

@functions_framework.cloud_event
def manage_dev_vms(cloud_event):
    """根据规则管理开发环境VM"""
    compute_client = compute_v1.InstancesClient()
    project = "my-project"
    zone = "us-central1-a"

    tz = pytz.timezone('Asia/Shanghai')
    now = datetime.now(tz)
    hour = now.hour
    day = now.weekday()

    should_run = (0 <= day <= 4) and (9 <= hour < 18)

    filter_expr = 'labels.env=dev'
    instances = compute_client.list(project=project, zone=zone, filter=filter_expr)

    for instance in instances.items:
        current_status = instance.status

        if should_run and current_status != 'RUNNING':
            compute_client.start(project=project, zone=zone, instance=instance.name)
        elif not should_run and current_status == 'RUNNING':
            compute_client.stop(project=project, zone=zone, instance=instance.name)