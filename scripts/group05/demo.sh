#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 25: Возможность использования внешнего провайдера аутентификации
# ============================================

# Подготовка
ydb -p default sql -s 'REVOKE SELECT ON `/Root/database/item` FROM `cn=ydb_role1,ou=groups,dc=ydb-cluster,dc=com@ldap`'


header "КРИТЕРИЙ 25: Возможность использования внешнего провайдера аутентификации"

comment "YDB поддерживает интеграцию c LDAP. Не предъявляется требований к конкретной реализации - "
comment "поддерживается любой сервер, реализующий стандартный протокол."
comment "Поддерживается протокол LDAPS и расширение StartTls."
comment ""
pause

link "https://ydb.tech/docs/ru/security/authentication?version=v25.2#ldap"

less -p ldap_authentication: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml
comment ""
comment "Выполним запрос от имени пользователя petrov@ldap:"
pause

run "ydb --endpoint grpcs://entrypoint.ydb-cluster.com:2135 -d /Root/database --ca-file ~/ca.crt --user petrov@ldap"

# ============================================
# КРИТЕРИЙ 18: Возможность интеграции графической консоли
# с внешней системой аутентификации
# ============================================

header "КРИТЕРИЙ 18: Возможность интеграции графической консоли с внешней системой аутентификации"

comment "Веб-интерфейс YDB использует для аутентификации те же механизмы что и при подключении через GRPC,"
comment "поэтому он автоматически поддерживает LDAP."
comment "Зайдем в WebUI от имени пользователя sidorov@ldap:"
comment ""
link "https://10.40.13.21:8765/monitoring/cluster/tenants?showHealthcheck=1"
pause

# ============================================
# КРИТЕРИЙ 27: Настройка ролевой модели доступа на основе групп,
# атрибутов пользователя с использованием внешнего провайдера (LDAP)
# ============================================

header "КРИТЕРИЙ 27: Настройка ролевой модели доступа на основе групп LDAP"

comment "YDB позволяет задавать права доступа группам в которые входит пользователь в LDAP."
pause

comment "Выполним запрос от имени пользователя ivanov@ldap:"
run "ydb -p default --user ivanov@ldap sql -s \"SELECT * FROM item LIMIT 10\""
pause


comment "Теперь выдадим права группе ydb_role1 в которую он входит"
run "ydb -p default --user root sql -s 'GRANT SELECT ON \`/Root/database/item\` TO \`cn=ydb_role1,ou=groups,dc=ydb-cluster,dc=com@ldap\`'"
pause

comment "Запустим запрос повторно:"
run "ydb -p default --user ivanov@ldap sql -s \"SELECT * FROM item LIMIT 10\""
pause

comment "По-умолчанию YDB использует группы, в которые пользователь входит непосредственно,"
comment "однако можно включить и рекурсивный поиск групп."
comment ""
link "https://ydb.tech/docs/ru/security/authentication?version=v25.2#poluchenie-grupp"
comment ""
pause

# Очистка (команда из old/27/run.sh)
ydb -p default --user root sql -s 'REVOKE SELECT ON `/Root/database/item` FROM `cn=ydb_role1,ou=groups,dc=ydb-cluster,dc=com@ldap`'
