// LDAP配置
// Manage Jenkins → Security → Security Realm
// 选择: LDAP

// LDAP服务器配置:
Server: ldap://ldap.example.com
Port: 389 (或636 for SSL)
Root DN: dc=example,dc=com

// 用户搜索:
User search base: ou=people
User search filter: (uid={0})

// 组搜索:
Group search base: ou=groups
Group search filter: (member={0})

// 高级配置:
// Display Name LDAP attribute: displayName
// Email LDAP attribute: mail
// Manager DN: cn=admin,dc=example,dc=com
// Manager Password: ********

// 测试连接
// Test LDAP settings