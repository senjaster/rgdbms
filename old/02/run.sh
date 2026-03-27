#!/bin/sh

ansible-galaxy collection list

echo ""

set -x

ls -1 /home/user/.ansible/collections/ansible_collections/ydb_platform/ydb/roles/packages/vars/distributions/
