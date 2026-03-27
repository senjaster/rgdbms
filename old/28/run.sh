#!/bin/sh

less +158 ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

scriptreplay -t timingfile.tm -m 3 -d 1 session.log

