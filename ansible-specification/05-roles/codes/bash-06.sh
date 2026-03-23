# 创建模板文件

# 创建Nginx配置模板
cat > roles/nginx/templates/nginx.conf.j2 << 'EOF'
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    {% if nginx_ssl_enabled %}
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    {% endif %}

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# 创建默认站点配置模板
cat > roles/nginx/templates/default-site.conf.j2 << 'EOF'
server {
    listen {{ nginx_port }};
    listen [::]:{{ nginx_port }};
    server_name {{ nginx_server_name }};
    root {{ nginx_document_root }};
    index index.html index.htm;

    {% if nginx_ssl_enabled %}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate {{ nginx_ssl_cert_path }};
    ssl_certificate_key {{ nginx_ssl_key_path }};
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF