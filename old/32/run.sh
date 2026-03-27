#!/bin/sh

less +233 ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

ydb -p default --user root sql -s "DROP USER IF EXISTS testaudit"
ydb -p default --user root sql -s "CREATE USER testaudit PASSWORD 'PASSw0rd!!!'"
ydb -p default --user root sql -s "ALTER GROUP ADMINS ADD USER testaudit"
ydb -p default --user root sql -s "DROP USER testaudit"

ssh user@yandex-ydb-1 sudo grep testaudit /var/log/ydb/ydb-audit-storage.log

