# AlloyDB 服务集成

## 本章概述

本章介绍AlloyDB与GKE、Cloud Functions、Cloud Run等GCP服务的集成方案，以及在不同场景下的最佳实践。

## 学习目标

- 掌握AlloyDB与GKE的集成配置
- 学会在Cloud Functions中使用AlloyDB
- 了解连接池和配置管理
- 理解安全连接最佳实践

---

## 1. AlloyDB与GKE集成

### 1.1 架构概述

```
AlloyDB + GKE 集成架构

┌─────────────────────────────────────────────────────────────────────────┐
│                        GKE集群内部访问AlloyDB                           │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      GKE Cluster                                  │   │
│  │                                                                  │   │
│  │   ┌─────────────────┐  ┌─────────────────┐                      │   │
│  │   │   Pod           │  │   Pod           │                      │   │
│  │   │  (Application)  │  │  (Application)  │                      │   │
│  │   └────────┬────────┘  └────────┬────────┘                      │   │
│  │            │                    │                               │   │
│  │            └──────────┬──────────┘                               │   │
│  │                       │                                          │   │
│  │            ┌──────────▼──────────┐                               │   │
│  │            │   AlloyDB Auth Proxy                              │   │
│  │            │   (Sidecar Container)                              │   │
│  │            └──────────┬──────────┘                               │   │
│  └───────────────────────┼─────────────────────────────────────────┘   │
│                          │                                              │
│                          ▼                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      AlloyDB Cluster                             │   │
│  │   Primary Node + Read Pool                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 GKE部署配置

```yaml
# alloydb-gke-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alloydb-app
  labels:
    app: alloydb-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alloydb-app
  template:
    metadata:
      labels:
        app: alloydb-app
    spec:
      containers:
      - name: app
        image: gcr.io/my-project/my-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: ALLOYDB_INSTANCE_URI
          value: "projects/my-project/locations/us-central1/clusters/my-cluster/instances/my-instance"
        - name: DB_NAME
          value: "mydb"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: alloydb-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: alloydb-credentials
              key: password
        volumeMounts:
        - name: alloydb-creds
          mountPath: /opt/alloydb
          readOnly: true
      volumes:
      - name: alloydb-creds
        secret:
          secretName: alloydb-sa-key
      - name: cloud-sql-creds
        secret:
          secretName: cloud-sql-proxy-credentials
```

### 1.3 AlloyDB Auth Proxy配置

```yaml
# alloydb-auth-proxy-sidecar.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alloydb-app-with-proxy
  labels:
    app: alloydb-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alloydb-app
  template:
    metadata:
      labels:
        app: alloydb-app
    spec:
      containers:
      # 应用容器
      - name: app
        image: gcr.io/my-project/my-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          value: "localhost"
        - name: DB_PORT
          value: "5432"
        # 使用环境变量传递连接信息
        - name: ALLOYDB_INSTANCE_URI
          value: "projects/my-project/locations/us-central1/clusters/my-cluster/instances/my-instance"

      # AlloyDB Auth Proxy Sidecar
      - name: alloydb-auth-proxy
        image: gcr.io/cloud-sql-conect-proxy/linux-amd64:latest
        args:
        - "--port=5432"
        - "--verbose"
        - "$(ALLOYDB_INSTANCE_URI)"
        env:
        - name: ALLOYDB_INSTANCE_URI
          valueFrom:
            secretKeyRef:
              name: alloydb-instance-name
              key: instance-uri
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
        securityContext:
          runAsUser: 2
          runAsGroup: 2
```

### 1.4 服务账号配置

```powershell
# 创建GKE服务账号
gcloud iam service-accounts create alloydb-app-sa `
    --display-name="AlloyDB App Service Account"

# 授予AlloyDB访问权限
gcloud projects add-iam-policy-binding $PROJECT_ID `
    --member="serviceAccount:alloydb-app-sa@$PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/alloydb.client"

# 创建密钥文件
gcloud iam service-accounts keys create key.json `
    --iam-account=alloydb-app-sa@$PROJECT_ID.iam.gserviceaccount.com

# 创建Kubernetes Secret
kubectl create secret generic alloydb-sa-key `
    --from-file=credentials.json=key.json
```

---

## 2. Cloud Functions集成

### 2.1 Cloud Functions环境配置

```bash
# 2.1.1 部署Cloud Functions

gcloud functions deploy alloydb-function `
    --runtime=python310 `
    --trigger-http `
    --allow-unauthenticated `
    --region=us-central1 `
    --set-env-vars="ALLOYDB_INSTANCE_URI=projects/my-project/locations/us-central1/clusters/my-cluster/instances/my-instance" `
    --service-account=alloydb-function-sa@my-project.iam.gserviceaccount.com
```

### 2.2 Python函数示例

```python
# main.py - Cloud Functions
import os
import psycopg2
from psycopg2 import pool
from flask import jsonify

# 连接池管理
connection_pool = None

def get_connection_pool():
    """获取或创建连接池"""
    global connection_pool
    
    if connection_pool is None:
        instance_uri = os.environ.get('ALLOYDB_INSTANCE_URI')
        
        # 使用Unix socket连接 (生产环境推荐)
        unix_socket = f"/cloudsql/{instance_uri}"
        
        connection_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=1,
            maxconn=10,
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASSWORD'),
            database=os.environ.get('DB_NAME', 'postgres'),
            host=unix_socket,
            port=5432
        )
    
    return connection_pool


def http_handler(request):
    """HTTP触发器处理函数"""
    try:
        pool = get_connection_pool()
        conn = pool.getconn()
        
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT NOW()")
                result = cur.fetchone()
                
                return jsonify({
                    'status': 'success',
                    'timestamp': str(result[0]),
                    'message': 'Connected to AlloyDB successfully'
                }), 200
        finally:
            pool.putconn(conn)
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


def background_processor(event):
    """后台触发器处理函数"""
    try:
        pool = get_connection_pool()
        conn = pool.getconn()
        
        data = event.data
        
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO events (event_type, data) VALUES (%s, %s)",
                    (data.get('type'), data.get('payload'))
                )
                conn.commit()
                
            return jsonify({'status': 'processed'}), 200
            
        finally:
            pool.putconn(conn)
            
    except Exception as e:
        print(f'Error processing event: {e}')
        return jsonify({'status': 'error'}), 500
```

---

## 3. Cloud Run集成

### 3.1 Cloud Run部署

```bash
# 3.1.1 构建并推送镜像

gcloud builds submit --tag gcr.io/my-project/alloydb-cloudrun:v1

# 3.1.2 部署Cloud Run服务

gcloud run deploy alloydb-cloudrun `
    --image=gcr.io/my-project/alloydb-cloudrun:v1 `
    --platform=managed `
    --region=us-central1 `
    --allow-unauthenticated `
    --set-env-vars="ALLOYDB_INSTANCE_URI=projects/my-project/locations/us-central1/clusters/my-cluster/instances/my-instance,DB_NAME=mydb" `
    --service-account=alloydb-run-sa@my-project.iam.gserviceaccount.com
```

### 3.2 Cloud Run应用示例

```python
# app.py - Cloud Run
import os
from flask import Flask, jsonify
import psycopg2
from psycopg2 import pool

app = Flask(__name__)

# 连接池
ThreadedConnectionPool = psycopg2.pool.ThreadedConnectionPool

def create_connection_pool():
    """创建连接池 - Cloud Run"""
    instance_uri = os.environ.get('ALLOYDB_INSTANCE_URI')
    
    # Cloud Run使用Cloud SQL Auth Proxy连接
    # 通过 /cloudsql/ 实例URI 访问
    unix_socket = f"/cloudsql/{instance_uri}"
    
    return ThreadedConnectionPool(
        minconn=1,
        maxconn=5,
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD'),
        database=os.environ.get('DB_NAME', 'postgres'),
        host=unix_socket
    )

# 全局连接池
db_pool = None

@app.before_first_request
def initialize_pool():
    """初始化连接池"""
    global db_pool
    if db_pool is None:
        db_pool = create_connection_pool()

@app.route('/health')
def health():
    """健康检查"""
    return jsonify({'status': 'healthy'})

@app.route('/users/<user_id>')
def get_user(user_id):
    """获取用户信息"""
    if db_pool is None:
        return jsonify({'error': 'Database not initialized'}), 500
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT user_id, username, email, created_at FROM users WHERE user_id = %s",
                (user_id,)
            )
            row = cur.fetchone()
            
            if row:
                return jsonify({
                    'user_id': str(row[0]),
                    'username': row[1],
                    'email': row[2],
                    'created_at': str(row[3])
                })
            else:
                return jsonify({'error': 'User not found'}), 404
    finally:
        db_pool.putconn(conn)

@app.route('/users', methods=['POST'])
def create_user():
    """创建用户"""
    from flask import request
    
    data = request.get_json()
    
    if db_pool is None:
        return jsonify({'error': 'Database not initialized'}), 500
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """INSERT INTO users (user_id, username, email)
                   VALUES (gen_random_uuid(), %s, %s)
                   RETURNING user_id""",
                (data.get('username'), data.get('email'))
            )
            conn.commit()
            
            user_id = cur.fetchone()[0]
            
        return jsonify({
            'status': 'created',
            'user_id': str(user_id)
        }), 201
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 400
    finally:
        db_pool.putconn(conn)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
```

---

## 4. 连接池配置

### 4.1 PgBouncer连接池配置

```yaml
# pgbouncer.ini
[databases]
mydb = host=/cloudsql/project:region:instance port=5432 dbname=mydb

[pgbouncer]
listen_port = 5432
listen_addr = 0.0.0.0
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt

# 连接池模式
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
min_pool_size = 5

# 超时配置
query_timeout = 60
server_idle_timeout = 600

# 日志
log_connections = 1
log_disconnections = 1
log_errors = 1
```

### 4.2 应用程序连接池最佳实践

```python
# connection_pool.py
"""推荐连接池配置"""

from psycopg2 import pool
import contextlib
import logging

logger = logging.getLogger(__name__)


class AlloyDBConnectionPool:
    """AlloyDB专用连接池"""
    
    def __init__(
        self,
        min_connections: int = 2,
        max_connections: int = 20,
        **kwargs
    ):
        self.pool = pool.ThreadedConnectionPool(
            minconn=min_connections,
            maxconn=max_connections,
            **kwargs
        )
        self.stats = {
            'acquired': 0,
            'released': 0,
            'errors': 0
        }
    
    @contextlib.contextmanager
    def connection(self, timeout: int = 30):
        """
        获取连接的上下文管理器
        
        Args:
            timeout: 连接超时时间(秒)
        """
        conn = None
        try:
            conn = self.pool.getconn()
            conn.autocommit = False
            
            # 设置查询超时
            # 注意: PostgreSQL timeout需要在连接后设置
            # 通过执行: SET statement_timeout = '30s'
            
            self.stats['acquired'] += 1
            yield conn
            
        except Exception as e:
            self.stats['errors'] += 1
            logger.error(f"Connection error: {e}")
            if conn:
                conn.rollback()
            raise
            
        finally:
            if conn:
                conn.commit()  # 提交未提交的事务
                self.pool.putconn(conn)
                self.stats['released'] += 1
    
    def get_stats(self) -> dict:
        """获取连接池统计"""
        return {
            **self.stats,
            'available': len(self.pool._used),
            'idle': len(self.pool._idle)
        }
    
    def close_all(self):
        """关闭所有连接"""
        self.pool.closeall()


# 使用示例
def create_pool():
    """创建连接池"""
    return AlloyDBConnectionPool(
        min_connections=2,
        max_connections=20,
        user='app_user',
        password='password',
        database='mydb',
        host='/cloudsql/project:region:instance'
    )
```

---

## 5. 安全配置

### 5.1 VPC私有IP配置

```powershell
# 5.1.1 创建私有IP的AlloyDB集群

$CLUSTER_ID = "private-ip-cluster"

gcloud alloydb clusters create $CLUSTER_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --network=$VPC_NETWORK `
    --enable-private-ip `
    --storage-type=SSD `
    --storage-capacity=100GB

# 5.1.2 获取私有IP

$CLUSTER_IP = gcloud alloydb clusters describe $CLUSTER_ID `
    --project=$PROJECT_ID `
    --location=$REGION `
    --format="value(ipAddress)"
```

### 5.2 SSL/TLS配置

```python
# ssl_connection.py
"""SSL连接配置"""

import psycopg2
import os

def get_ssl_connection():
    """获取启用SSL的连接"""
    
    # 获取SSL证书 (从AlloyDB实例)
    # gcloud alloydb instances describe INSTANCE_ID --format="value(sslCert.cert)"
    
    ssl_mode = 'require'  # 生产环境使用 'verify-ca' 或 'verify-full'
    
    conn = psycopg2.connect(
        host=os.environ.get('ALLOYDB_HOST'),
        port=int(os.environ.get('ALLOYDB_PORT', 5432)),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASSWORD'),
        sslmode=ssl_mode,
        sslcert=os.environ.get('SSL_CERT_PATH'),
        sslkey=os.environ.get('SSL_KEY_PATH'),
        sslrootcert=os.environ.get('SSL_ROOT_CERT_PATH')
    )
    
    return conn


def verify_ssl_connection():
    """验证SSL连接"""
    conn = get_ssl_connection()
    
    with conn.cursor() as cur:
        cur.execute("SELECT ssl_is_used()")
        is_ssl = cur.fetchone()[0]
        
        cur.execute("SELECT ssl_cipher()")
        cipher = cur.fetchone()[0]
        
        print(f"SSL Enabled: {is_ssl}")
        print(f"Cipher: {cipher}")
    
    conn.close()
```

### 5.3 IAM认证

```bash
# 5.3.1 使用IAM数据库认证

# 为用户启用IAM认证
gcloud alloydb users set-iam-policy-binding my-user `
    --project=$PROJECT_ID `
    --cluster=$CLUSTER_ID `
    --instance=$INSTANCE_ID `
    --location=$REGION `
    --role=roles/alloydb.databaseUser
```

```python
# 5.3.2 IAM认证连接

import google.auth
from google.cloud.alloydb_v1 import AlloyDBAdminClient

def get_iam_auth_token():
    """获取IAM认证令牌"""
    credentials, project = google.auth.default(
        scopes=['https://www.googleapis.com/auth/cloud-platform']
    )
    
    # 获取访问令牌
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    
    return credentials.token


def connect_with_iam_auth():
    """使用IAM认证连接AlloyDB"""
    import pg8000  # 支持IAM认证的驱动
    
    credentials, project = google.auth.default(
        scopes=['https://www.googleapis.com/auth/cloud-platform']
    )
    
    conn = pg8000.connect(
        user=f"{project}@cloudsql.ggserviceaccount.com",
        password=credentials.token,
        host=os.environ.get('ALLOYDB_HOST'),
        port=5432,
        database=os.environ.get('DB_NAME')
    )
    
    return conn
```

---

[← 返回目录](../README.md#目录)
