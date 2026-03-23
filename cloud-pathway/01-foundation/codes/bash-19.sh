systemctl           systemd服务管理
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx
systemctl status nginx
systemctl enable nginx    开机自启
systemctl disable nginx   禁用自启
systemctl list-units      列出所有单元
systemctl list-unit-files 列出所有服务文件

service             传统服务管理（兼容）
service nginx start
service nginx stop
service nginx status