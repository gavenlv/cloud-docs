#!/bin/bash

# Doris扩缩容脚本

# 扩容BE节点
scale_out_be() {
    local be_host=$1
    local be_port=${2:-9050}

    echo "Adding BE node: $be_host:$be_port"

    mysql -h $FE_HOST -P 9030 -uroot -p'' <<EOF
ALTER SYSTEM ADD BACKEND '${be_host}:${be_port}';
EOF

    echo "Starting BE on $be_host..."
    ssh $be_host "cd /opt/apache-doris/be && sh bin/start_be.sh --daemon"

    echo "Verifying BE status..."
    sleep 10
    mysql -h $FE_HOST -P 9030 -uroot -p'' -e "SHOW BACKENDS;" | grep $be_host
}

# 缩容BE节点
scale_in_be() {
    local be_host=$1
    local be_port=${2:-9050}

    echo "Decommissioning BE node: $be_host:$be_port"

    mysql -h $FE_HOST -P 9030 -uroot -p'' <<EOF
ALTER SYSTEM DECOMMISSION BACKEND '${be_host}:${be_port}';
EOF

    echo "Waiting for data migration..."
    while true; do
        status=$(mysql -h $FE_HOST -P 9030 -uroot -p'' -e "SHOW BACKENDS\G" | grep -A1 "${be_host}" | grep 'TabletNum' | awk '{print $2}')
        if [ "$status" == "0" ]; then
            echo "Data migration completed. Stopping BE..."
            ssh $be_host "cd /opt/apache-doris/be && sh bin/stop_be.sh"

            mysql -h $FE_HOST -P 9030 -uroot -p'' <<EOF
ALTER SYSTEM DROP BACKEND '${be_host}:${be_port}';
EOF
            break
        fi
        echo "Waiting... Current TabletNum: $status"
        sleep 30
    done
}

FE_HOST=${FE_HOST:-127.0.0.1}

case "$1" in
    scale_out)
        scale_out_be $2 $3
        ;;
    scale_in)
        scale_in_be $2 $3
        ;;
    *)
        echo "Usage: $0 {scale_out|scale_in} <host> [port]"
        ;;
esac
