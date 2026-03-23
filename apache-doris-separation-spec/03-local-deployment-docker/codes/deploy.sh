#!/bin/bash

echo "=========================================="
echo "Doris 存算分离 - 一键部署脚本 (Docker)"
echo "=========================================="

set -e

# 配置
NETWORK_NAME="doris-net"
SUBNET="172.20.0.0/16"
MINIO_DATA_DIR="./minio-data"
FE_DATA_DIR="./fe-data"
COMPUTE_CACHE_DIR="./compute-cache"

echo "1. 创建Docker网络..."
docker network create $NETWORK_NAME --driver bridge --subnet=$SUBNET 2>/dev/null || echo "网络已存在"

echo "2. 创建数据目录..."
mkdir -p $MINIO_DATA_DIR $FE_DATA_DIR $COMPUTE_CACHE_DIR

echo "3. 启动MinIO..."
docker run -d \
    --name doris-minio \
    --hostname minio \
    --network $NETWORK_NAME \
    -p 9000:9000 \
    -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    -v $(pwd)/minio-data:/data \
    minio/minio server /data --console-address ":9001"

echo "等待MinIO启动..."
sleep 10

echo "4. 配置MinIO存储桶..."
docker run --rm -it --network $NETWORK_NAME \
    minio/mc:latest bash -c "\
    mc alias set myminio http://minio:9000 minioadmin minioadmin; \
    mc mb myminio/doris-data --ignore-existing; \
    mc anonymous set download myminio/doris-data"

echo "5. 启动FE节点..."
for i in 1 2 3; do
    PORT_F=$((8030+i-1))
    PORT_Q=$((9030+i-1))
    docker run -d \
        --name doris-fe$i \
        --hostname fe$i \
        --network $NETWORK_NAME \
        -p $PORT_F:8030 \
        -p $PORT_Q:9030 \
        -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
        -e FE_ID=$i \
        -e PRIORITY_NETWORKS="172.20.0.0/16" \
        -v $(pwd)/fe-data/fe$i:/opt/apache-doris/fe/meta \
        -v $(pwd)/fe-data/fe$i-log:/opt/apache-doris/fe/log \
        apache/doris:2.1.0 \
        bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon
done

echo "等待FE启动..."
sleep 30

echo "6. 启动计算节点..."
for i in 1 2 3; do
    PORT_W=$((8040+i-1))
    PORT_B=$((9050+i-1))
    PORT_R=$((9060+i-1))
    docker run -d \
        --name doris-compute$i \
        --hostname compute$i \
        --network $NETWORK_NAME \
        -p $PORT_W:8040 \
        -p $PORT_B:9050 \
        -p $PORT_R:9060 \
        -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
        -e BE_ADDRS="compute1:9050,compute2:9050,compute3:9050" \
        -e PRIORITY_NETWORKS="172.20.0.0/16" \
        -e OBJECT_STORAGE_ENDPOINT="minio:9000" \
        -e OBJECT_STORAGE_REGION="us-east-1" \
        -e OBJECT_STORAGE_BUCKET="doris-data" \
        -e OBJECT_STORAGE_ACCESS_KEY="minioadmin" \
        -e OBJECT_STORAGE_SECRET_KEY="minioadmin" \
        -e OBJECT_STORAGE_USE_HTTPS="false" \
        -e STORAGE_ROOT_PATH="/mnt/disk1/doris_cloud_cache" \
        -e CACHE_FILE_SIZE="20" \
        -e CACHE_TTL_SECONDS="86400" \
        -v $(pwd)/compute-cache/compute$i:/mnt/disk1/doris_cloud_cache \
        -v $(pwd)/compute-cache/compute$i-log:/opt/apache-doris/be/log \
        apache/doris:2.1.0 \
        bash /opt/apache-doris/be/bin/start_be.sh --daemon
done

echo "等待计算节点启动..."
sleep 30

echo "7. 注册计算节点到FE..."
mysql -h 127.0.0.1 -P 9030 -uroot -p'' -e "ALTER SYSTEM ADD BACKEND 'compute1:9050';"
mysql -h 127.0.0.1 -P 9030 -uroot -p'' -e "ALTER SYSTEM ADD BACKEND 'compute2:9050';"
mysql -h 127.0.0.1 -P 9030 -uroot -p'' -e "ALTER SYSTEM ADD BACKEND 'compute3:9050';"

echo ""
echo "=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "服务地址："
echo "  - FE1: 127.0.0.1:9030"
echo "  - FE2: 127.0.0.1:9031"
echo "  - FE3: 127.0.0.1:9032"
echo "  - MinIO Console: http://127.0.0.1:9001"
echo ""
echo "连接命令："
echo "  mysql -h 127.0.0.1 -P 9030 -uroot -p''"
echo ""
echo "查看状态："
echo "  docker-compose ps"
echo "  docker logs doris-fe1"
echo "  docker logs doris-compute1"
