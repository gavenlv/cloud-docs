# 创建角色目录结构

# 创建角色目录
mkdir -p roles/nginx/{defaults,files,handlers,meta,tasks,templates,tests,vars}

# 创建角色文件
touch roles/nginx/defaults/main.yml
touch roles/nginx/vars/main.yml
touch roles/nginx/tasks/main.yml
touch roles/nginx/handlers/main.yml
touch roles/nginx/meta/main.yml
touch roles/nginx/templates/nginx.conf.j2
touch roles/nginx/templates/default-site.conf.j2
touch roles/nginx/README.md

# 验证角色目录结构
tree roles/nginx

# 预期输出：
# roles/nginx/
# ├── defaults/
# │   └── main.yml
# ├── files/
# ├── handlers/
# │   └── main.yml
# ├── meta/
# │   └── main.yml
# ├── tasks/
# │   └── main.yml
# ├── templates/
# │   ├── default-site.conf.j2
# │   └── nginx.conf.j2
# ├── tests/
# ├── vars/
# │   └── main.yml
# └── README.md