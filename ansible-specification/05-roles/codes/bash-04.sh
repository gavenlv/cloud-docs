# 配置角色处理器

# 创建处理器
cat > roles/nginx/handlers/main.yml << 'EOF'
---
- name: 重新加载Nginx服务
  service:
    name: nginx
    state: reloaded
  become: true

- name: 重启Nginx服务
  service:
    name: nginx
    state: restarted
  become: true
EOF