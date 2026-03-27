from google.cloud import alloydb_v1
from google.cloud.alloydb_v1 import GapicVersion
import pandas as pd
from datetime import datetime

PROJECT_ID = "your-project-id"
REGION = "us-central1"
CLUSTER_ID = "my-alloydb-cluster"
INSTANCE_ID = "my-alloydb-instance"


def create_cluster():
    print("\n" + "="*50)
    print("Create AlloyDB Cluster")
    print("="*50)

    client = alloydb_v1.AlloyDBAdminClient()
    parent = f"projects/{PROJECT_ID}/locations/{REGION}"

    cluster = {
        "network": f"projects/{PROJECT_ID}/global/networks/default",
        "recovery_window_days": 7,
        "storage_type": alloydb_v1.StorageType.SSD,
        "storage_capacity": 100,
    }

    operation = client.create_cluster(
        request={
            "parent": parent,
            "cluster_id": CLUSTER_ID,
            "cluster": cluster,
        }
    )

    result = operation.result()
    print(f"Cluster {CLUSTER_ID} created successfully")
    print(f"Storage type: {result.storage_type}")
    print(f"Storage capacity: {result.storage_capacity}GB")


def create_instance():
    print("\n" + "="*50)
    print("Create AlloyDB Instance")
    print("="*50)

    client = alloydb_v1.AlloyDBAdminClient()
    parent = f"projects/{PROJECT_ID}/locations/{REGION}/clusters/{CLUSTER_ID}"

    instance = {
        "cpu_count": 2,
        "memory_size_gb": 16,
    }

    operation = client.create_instance(
        request={
            "parent": parent,
            "instance_id": INSTANCE_ID,
            "instance": instance,
        }
    )

    result = operation.result()
    print(f"Instance {INSTANCE_ID} created successfully")
    print(f"CPU: {result.cpu_count}")
    print(f"Memory: {result.memory_size_gb}GB")


def list_resources():
    print("\n" + "="*50)
    print("List Resources")
    print("="*50)

    client = alloydb_v1.AlloyDBAdminClient()
    parent = f"projects/{PROJECT_ID}/locations/{REGION}"

    clusters = client.list_clusters(request={"parent": parent})

    print("\nCluster list:")
    for cluster in clusters:
        print(f"  - {cluster.cluster_id}: {cluster.state}")

    instances = client.list_instances(
        request={"parent": f"{parent}/clusters/{CLUSTER_ID}"}
    )

    print("\nInstance list:")
    for instance in instances:
        print(f"  - {instance.instance_id}: CPU={instance.cpu_count}, Memory={instance.memory_size_gb}GB")


def update_instance():
    print("\n" + "="*50)
    print("Update Instance Specs")
    print("="*50)

    client = alloydb_v1.AlloyDBAdminClient()
    name = f"projects/{PROJECT_ID}/locations/{REGION}/clusters/{CLUSTER_ID}/instances/{INSTANCE_ID}"

    update_mask = {"paths": ["cpu_count", "memory_size_gb"]}

    instance = {
        "name": name,
        "cpu_count": 4,
        "memory_size_gb": 32,
    }

    operation = client.update_instance(
        request={
            "instance": instance,
            "update_mask": update_mask,
        }
    )

    result = operation.result()
    print(f"Instance updated successfully")
    print(f"New CPU: {result.cpu_count}")
    print(f"New Memory: {result.memory_size_gb}GB")


def create_backup():
    print("\n" + "="*50)
    print("Create Backup")
    print("="*50)

    client = alloydb_v1.AlloyDBAdminClient()
    parent = f"projects/{PROJECT_ID}/locations/{REGION}/clusters/{CLUSTER_ID}"
    backup_id = f"backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

    backup = {
        "cluster": parent,
        "description": f"Manual backup at {datetime.now().isoformat()}",
    }

    operation = client.create_backup(
        request={
            "parent": parent,
            "backup_id": backup_id,
            "backup": backup,
        }
    )

    result = operation.result()
    print(f"Backup {backup_id} created successfully")
    print(f"Size: {result.size_bytes / (1024**3):.2f}GB")
    print(f"Create time: {result.create_time}")


if __name__ == "__main__":
    print("AlloyDB Python SDK Demo")
    print("="*50)

    print("\nNote: Set up authentication first:")
    print("  gcloud auth application-default login")
    print("\nThen update the PROJECT_ID, REGION, CLUSTER_ID, INSTANCE_ID variables")
    print("Run the functions below as needed:")
    print("  - create_cluster()")
    print("  - create_instance()")
    print("  - list_resources()")
    print("  - update_instance()")
    print("  - create_backup()")
