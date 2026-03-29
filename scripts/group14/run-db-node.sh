export LD_LIBRARY_PATH=/opt/ydb/lib

/opt/ydb/bin/ydbd server \
    --yaml-config  /opt/ydb/cfg/ydbd-config-dynamic.yaml \
    --grpcs-port 2137 \
    --ic-port 19003 \
    --mon-port 8767 \
    --tenant /Root/database \
    --node-broker-use-tls true \
    --grpc-ca /opt/ydb/certs/ca.crt \
    --ca /opt/ydb/certs/ca.crt \
    --mon-cert /opt/ydb/certs/web.pem \
    --grpc-cert /opt/ydb/certs/node.crt \
    --grpc-key /opt/ydb/certs/node.key \
    --node-broker grpcs://yandex-ydb-1.ydb-cluster.com:2135 \
    --node-broker grpcs://yandex-ydb-2.ydb-cluster.com:2135 \
    --node-broker grpcs://yandex-ydb-3.ydb-cluster.com:2135
