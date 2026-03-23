# 构建镜像
docker build -t my-node-app:1.0 .

# 查看镜像
docker images

# 输出：
# REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
# my-node-app     1.0       abc123def456   5 minutes ago   25MB

# 查看镜像历史
docker history my-node-app:1.0

# 输出：
# IMAGE          CREATED         CREATED BY                                      SIZE
# abc123def456   5 minutes ago   /bin/sh -c #(nop) ADD file:abc123def456 in /    0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) CMD [nginx -g daemon off;] 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) EXPOSE map[80/tcp:80/tcp] 0B
# abc123def456   5 minutes ago   |1 COPY /etc/nginx/nginx.conf /etc/nginx/nginx.conf  1.2kB
# abc123def456   5 minutes ago   |2 COPY /app/dist /usr/share/nginx/html  15MB
# abc123def456   5 minutes ago   /bin/sh -c #(nop) LABEL maintainer=... 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) HEALTHCHECK &{...} 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) FROM node:18-alpine  120MB