#!/bin/sh

less +155 ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

ydb -p default --user root sql -s "DROP USER IF EXISTS test2"
ydb -p default --user root sql -s "CREATE USER test2 PASSWORD 'PASSw0rd!!!'"
ydb -p default --user root sql -s "ALTER GROUP ADMINS ADD USER test2"

# scriptreplay -t timingfile.tm -m 3 -d 1 session.log

