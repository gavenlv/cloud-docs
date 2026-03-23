# 创建组变量文件

# 创建group_vars目录
mkdir -p group_vars

# 创建webservers组变量文件
cat > group_vars/webservers.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# Web服务器配置
http_port: 80
https_port: 443
document_root: /var/www/html

# Nginx配置
nginx:
  worker_processes: auto
  worker_connections: 1024
  keepalive_timeout: 65
  client_max_body_size: 100M
  server_tokens: off

# 应用配置
app:
  name: webapp
  version: 1.0.0
  port: 8080
  environment: production
  debug: false

# 监控配置
monitoring:
  enabled: true
  metrics_port: 9090
  alerting_enabled: true
  alerting_rules:
    - name: high_cpu
      condition: cpu_usage > 80
      duration: 5m
      severity: warning
    - name: high_memory
      condition: memory_usage > 80
      duration: 5m
      severity: warning

# 日志配置
logging:
  enabled: true
  log_dir: /var/log/webapp
  log_level: info
  log_rotation: true
  log_retention_days: 30
EOF

# 创建dbservers组变量文件
cat > group_vars/dbservers.yml << 'EOF'
---
ansible_user: ansible
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_python_interpreter: /usr/bin/python3

# 数据库配置
mysql_port: 3306
mysql_root_password: secret
mysql_database: appdb
mysql_user: appuser
mysql_password: apppass

# MySQL配置
mysql:
  max_connections: 200
  innodb_buffer_pool_size: 1G
  innodb_log_file_size: 256M
  query_cache_size: 64M
  slow_query_log: true
  slow_query_log_file: /var/log/mysql/slow.log
  long_query_time: 2

# 备份配置
backup:
  enabled: true
  backup_dir: /backup/mysql
  backup_schedule: "0 2 * * *"
  backup_retention_days: 7

# 监控配置
monitoring:
  enabled: true
  metrics_port: 9104
  alerting_enabled: true
  alerting_rules:
    - name: high_connections
      condition: connections > 150
      duration: 5m
      severity: warning
    - name: replication_lag
      condition: replication_lag > 60
      duration: 5m
      severity: critical
EOF

# 验证组变量
ansible webservers -m debug -a "var=groups"

# 预期输出：
# localhost | SUCCESS => {
#     "groups": {
#         "all": [
#             "localhost"
#         ],
#         "dbservers": [
#             "localhost"
#         ],
#         "ungrouped": [],
#         "webservers": [
#             "localhost"
#         ]
#     }
# }