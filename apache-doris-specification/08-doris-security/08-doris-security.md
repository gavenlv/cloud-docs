# Doris安全配置

## 概述

本文档介绍Doris的安全配置和管理，包括用户权限管理、认证配置、SSL配置和审计日志。

## 用户管理

### 创建用户

```sql
-- 创建普通用户
CREATE USER 'username'@'%' IDENTIFIED BY 'password';

-- 创建限制资源用户
CREATE USER 'username'@'%' IDENTIFIED BY 'password'
PROPERTIES (
    'max_query_timeout' = '3600',
    'max_connections_per_hour' = '100',
    'max_user_connections' = '50'
);

-- 创建禁止登录用户（用于程序访问）
CREATE USER 'app_user'@'%' IDENTIFIED BY 'password';
```

### 修改用户密码

```sql
-- 修改自己密码
SET PASSWORD = PASSWORD('new_password');

-- 修改其他用户密码
SET PASSWORD FOR 'username'@'%' = PASSWORD('new_password');

-- 使用ALTER修改
ALTER USER 'username'@'%' IDENTIFIED BY 'new_password';
```

### 删除用户

```sql
DROP USER 'username'@'%';
```

### 查看用户

```sql
-- 查看所有用户
SELECT * FROM mysql.user;

-- 查看用户权限
SHOW GRANTS FOR 'username'@'%';
```

## 权限管理

### 授予权限

```sql
-- 授予数据库所有权限
GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'%';

-- 授予表权限
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.table_name TO 'username'@'%';

-- 授予只读权限
GRANT SELECT ON database_name.* TO 'readonly_user'@'%';

-- 授予资源使用权限
GRANT USAGE ON RESOURCE * TO 'username'@'%';
```

### 撤销权限

```sql
-- 撤销所有权限
REVOKE ALL PRIVILEGES ON database_name.* FROM 'username'@'%';

-- 撤销特定权限
REVOKE INSERT, UPDATE, DELETE ON database_name.table_name FROM 'username'@'%';
```

### 角色管理

```sql
-- 创建角色
CREATE ROLE analyst;

-- 授予角色权限
GRANT SELECT ON database_name.* TO ROLE analyst;

-- 授予角色给用户
GRANT analyst TO 'username'@'%';

-- 查看角色权限
SHOW GRANTS FOR ROLE analyst;

-- 删除角色
DROP ROLE analyst;
```

### 权限说明

| 权限 | 说明 |
|------|------|
| SELECT | 查询数据 |
| INSERT | 插入数据 |
| UPDATE | 更新数据 |
| DELETE | 删除数据 |
| CREATE | 创建数据库/表 |
| DROP | 删除数据库/表 |
| ALTER | 修改表结构 |
| LOAD | 导入数据 |
| CREATE VIEW | 创建视图 |
| CREATE ROUTINE | 创建存储过程 |
| USAGE | 使用资源 |
| ADMIN | 集群管理 |

## 认证配置

### 外部认证

```sql
-- 启用LDAP认证
ADMIN SET FRONTEND CONFIG ("enable_authentication" = "true");
ADMIN SET FRONTEND CONFIG ("authentication_ldap" = "true");
ADMIN SET FRONTEND CONFIG ("ldap_server" = "ldap://ldap_server:389");
ADMIN SET FRONTEND CONFIG ("ldap_user_basedn" = "dc=example,dc=com");
ADMIN SET FRONTEND CONFIG ("ldap_user_filter" = "(uid=%s)");
```

### 密码策略

```sql
-- 设置密码复杂度
ADMIN SET FRONTEND CONFIG ("password_min_length" = "8");
ADMIN SET FRONTEND CONFIG ("password_min_special_char" = "1");
ADMIN SET FRONTEND CONFIG ("password_min_digit" = "1");
ADMIN SET FRONTEND CONFIG ("password_min_uppercase" = "1");
ADMIN SET FRONTEND CONFIG ("password_min_lowercase" = "1");

-- 密码过期策略
ADMIN SET FRONTEND CONFIG ("password_expire_policy" = "TRUE");
ADMIN SET FRONTEND CONFIG ("password_min_lifetime" = "86400");  -- 24小时

-- 禁止重用密码
ADMIN SET FRONTEND CONFIG ("password_history" = "5");
```

## SSL配置

### 生成证书

```bash
# 生成CA证书
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem > ca-cert.pem

# 生成服务器证书
openssl req -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem > server-req.pem
openssl x509 -req -in server-req.pem -days 3650 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 > server-cert.pem
```

### 配置SSL

```bash
# 修改FE配置
cat > fe/conf/fe.conf << EOF
# SSL配置
ssl_trust_cert_chain_path = /path/to/ca-cert.pem
ssl_keystore_password = keystore_password
ssl_keystore = /path/to/keystore
EOF
```

### 使用SSL连接

```bash
# MySQL客户端SSL连接
mysql -h fe_host -P 9030 -u username -p --ssl-ca=/path/to/ca-cert.pem

# 验证SSL连接
mysql -h fe_host -P 9030 -u username -p
SHOW VARIABLES LIKE '%ssl%';
```

## 审计日志

### 开启审计日志

```sql
-- 开启审计日志
ADMIN SET FRONTEND CONFIG ("audit_log_enable" = "true");
ADMIN SET FRONTEND CONFIG ("audit_log_dir" = "/path/to/audit");
ADMIN SET FRONTEND CONFIG ("audit_log_total_capacity_mb" = "1024");
ADMIN SET FRONTEND CONFIG ("audit_log_capacity_mb" = "512");
```

### 查看审计日志

```sql
-- FE审计日志位置
-- $DORIS_FE_HOME/log/fe.audit.log

-- 查询审计日志（通过FE日志）
SHOW AUDIT LAST 100;
```

### 审计日志格式

```
2024-01-01 10:00:00 | query_id | user:username | fe:127.0.0.1 |
    SELECT * FROM table WHERE condition | scan_rows:1000000 | scan_bytes:50000000 | 
    duration:5.5ms
```

## 集群安全配置

### FE安全配置

```bash
# fe.conf 安全配置
# 禁止非root用户运行FE
run_as_root = false

# FE端口安全
query_port = 9030
rpc_port = 9020
http_port = 8030
```

### BE安全配置

```bash
# be.conf 安全配置
# 禁止非root用户运行BE
run_as_root = false

# BE端口安全
be_port = 9050
webserver_port = 8040
heartbeat_service_port = 9050
brpc_port = 9060
```

### 网络隔离

```sql
-- 限制FE访问IP
ADMIN SET FRONTEND CONFIG ("query_port" = "9030");
ADMIN SET FRONTEND CONFIG ("http_port" = "8030");

-- 使用whitelist
CREATE USER 'username'@'192.168.1.%' IDENTIFIED BY 'password';
```

## 最佳实践

### 最小权限原则

```sql
-- 应用用户
CREATE USER 'app_readonly'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON app_database.* TO 'app_readonly'@'%';

-- ETL用户
CREATE USER 'etl_user'@'%' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON etl_database.* TO 'etl_user'@'%';

-- 管理员用户
CREATE USER 'admin'@'%' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
```

### 定期安全审计

```sql
-- 检查异常用户
SELECT user, host FROM mysql.user WHERE password_expired = 'Y';

-- 检查权限过大用户
SELECT * FROM mysql.user WHERE User NOT IN ('root') AND Super_priv = 'Y';

-- 检查空密码用户
SELECT * FROM mysql.user WHERE Password = '';
```

### 敏感数据保护

```sql
-- 创建脱敏视图
CREATE VIEW user_info_masked AS
SELECT
    user_id,
    username,
    CONCAT(LEFT(email, 3), '***', RIGHT(email, 4)) as email_masked,
    CONCAT(LEFT(phone, 3), '****', RIGHT(phone, 4)) as phone_masked
FROM user_table;

-- 授予视图权限
GRANT SELECT ON database.user_info_masked TO 'analyst'@'%';
```
