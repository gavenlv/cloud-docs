# SSH密钥登录
ssh-keygen -t ed25519 -C "comment"
ssh-copy-id user@host

# SSH配置优化
cat ~/.ssh/config
Host *
    StrictHostKeyChecking no
    ServerAliveInterval 60
    ServerAliveCountMax 3

# HTTPS配置 (nginx)
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Security "max-age=31536000" always;
}