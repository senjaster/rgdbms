#!/bin/sh

scriptreplay -t timingfile.tm -m 3 -d 1 session.log

ydb -p default --user root sql -s 'REVOKE SELECT ON `/Root/database/item` FROM `cn=ydb_role1,ou=groups,dc=ydb-cluster,dc=com@ldap`'
