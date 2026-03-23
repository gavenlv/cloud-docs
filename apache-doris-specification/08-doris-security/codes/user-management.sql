-- 用户管理示例

-- 创建用户
CREATE USER 'app_user'@'%' IDENTIFIED BY 'StrongPass123!';

-- 创建限制资源用户
CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'ReadOnly123!'
PROPERTIES (
    'max_query_timeout' = '300',
    'max_connections_per_hour' = '100',
    'max_user_connections' = '50'
);

-- 授予数据库权限
GRANT ALL PRIVILEGES ON example_db.* TO 'app_user'@'%';

-- 授予只读权限
GRANT SELECT ON example_db.* TO 'readonly_user'@'%';

-- 授予特定表权限
GRANT SELECT, INSERT ON example_db.order_table TO 'app_user'@'%';

-- 授予资源使用权限
GRANT USAGE ON RESOURCE * TO 'app_user'@'%';

-- 创建角色
CREATE ROLE analyst;

-- 授予角色权限
GRANT SELECT ON example_db.* TO ROLE analyst;
GRANT SELECT, INSERT ON example_db.order_table TO ROLE analyst;

-- 授予角色给用户
GRANT analyst TO 'readonly_user'@'%';

-- 查看用户权限
SHOW GRANTS FOR 'app_user'@'%';
SHOW GRANTS FOR 'readonly_user'@'%';
SHOW GRANTS FOR ROLE analyst;

-- 撤销权限
REVOKE INSERT ON example_db.order_table FROM 'app_user'@'%';
REVOKE analyst FROM 'readonly_user'@'%';

-- 修改用户密码
ALTER USER 'app_user'@'%' IDENTIFIED BY 'NewPass123!';

-- 设置用户资源限制
ALTER USER 'app_user'@'%'
PROPERTIES (
    'max_query_timeout' = '600',
    'max_connections_per_hour' = '200'
);

-- 删除用户
DROP USER 'app_user'@'%';

-- 密码策略配置（需要管理员执行）
-- ADMIN SET FRONTEND CONFIG ("password_min_length" = "8");
-- ADMIN SET FRONTEND CONFIG ("password_min_special_char" = "1");
