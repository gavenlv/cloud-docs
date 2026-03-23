# TLS 1.3 常用加密套件
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
TLS_AES_128_GCM_SHA256

# TLS 1.2 加密套件格式
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
#    │      │      │       │
#    │      │      │       └─ 摘要算法 (SHA256)
#    │      │      └─ 加密算法 (AES-128-GCM)
#    │      └─ 密钥交换 (ECDHE)
#    └─ 认证算法 (RSA)

# 查看支持的加密套件
openssl ciphers -v 'ALL:!NULL:!EXPORT'

# 测试网站TLS配置
testssl.sh example.com