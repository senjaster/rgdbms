export YDB_PASSWORD='PASSw0rd!!!'

ydb-bench \
    --endpoint grpcs://entrypoint.ydb-cluster.com:2135 \
    --database /Root/database \
    --ca-file ~/ca.crt \
    --user root \
    --prefix-path bench \
    --scale 1000 \
    run \
    --jobs 10 \
    --file tpcc_like.sql