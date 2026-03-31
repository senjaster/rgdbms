export YDB_PASSWORD='PASSw0rd!!!'

ydb-bench \
    --endpoint grpcs://entrypoint.ydb-cluster.com:2135 \
    --database /Root/database \
    --ca-file ~/ca.crt \
    --user root \
    --prefix-path bench \
    --scale 1000 \
    run -P 60 -T 300 \
    --jobs 5 \
    --processes 1 \
    --file accounts_200p.sql