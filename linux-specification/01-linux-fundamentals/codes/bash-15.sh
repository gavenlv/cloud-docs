# 使用Docker运行轻量级Linux环境

# 启动Ubuntu容器
docker run -it --name mylinux ubuntu:20.04 /bin/bash

# 启动Alpine Linux (更轻量)
docker run -it --name alpine alpine /bin/sh

# 启动CentOS
docker run -it --name centos centos:8 /bin/bash

# 在容器中体验不同的Linux发行版
docker exec -it mylinux /bin/bash