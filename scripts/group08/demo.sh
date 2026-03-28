#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 32: Наличие встроенного инструмента системного аудита
# действий пользователей, в том числе администраторов
# ============================================

header "КРИТЕРИЙ 32: Наличие встроенного инструмента системного аудита действий пользователей"

comment "YDB имеет встроенный механизм аудита действий пользователей и администраторов."
comment "Документация по аудиту:"
link "https://ydb.tech/docs/ru/security/audit-log?version=v25.2"
pause

comment "Просмотрим конфигурационный файл с настройками аудита:"
pause

less -p audit_config: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml


comment "Выполним несколько операций для демонстрации аудита:"
pause

# Очистка
ydb -p default --user root sql -s "DROP USER IF EXISTS audituser" 2>/dev/null
ydb -p default --user root sql -s "DROP TABLE IF EXISTS audittable" 2>/dev/null
ydb -p default --user root sql -s "DROP GROUP IF EXISTS auditgroup" 2>/dev/null

run "ydb -p default --user root sql -s \"CREATE USER audituser PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default --user root sql -s \"CREATE GROUP auditgroup\""

run "ydb -p default --user root sql -s \"ALTER GROUP auditgroup ADD USER audituser\""

run "ydb -p default --user root sql -s \"CREATE TABLE audittable (id Int32, name Utf8, PRIMARY KEY (id))\""

run "ydb -p default --user root sql -s \"GRANT SELECT ON \\\`\Root\\\\database\\\\audittable\\\` TO auditgroup\""

run "ydb -p default --user root sql -s \"REVOKE SELECT ON \\\`\Root\\\\database\\\\audittable\\\` FROM auditgroup\""

run "ydb -p default --user root sql -s \"DROP TABLE audittable\""

run "ydb -p default --user root sql -s \"DROP GROUP auditgroup\""

run "ydb -p default --user root sql -s \"DROP USER audituser\""

comment "Попытка неуспешного подключения с неправильным именем пользователя:"

run "ydb -p default --user wronguser --no-password sql -s \"SELECT 1\" || true"

pause

# ============================================
# КРИТЕРИЙ 34: Возможность хранения журнала аудита в выделенном файле
# ============================================

header "КРИТЕРИЙ 34: Возможность хранения журнала аудита в выделенном файле"

comment "YDB сохраняет журнал аудита в выделенный файл."
comment "Проверим записи в журнале аудита:"
comment ""
run "ssh user@yandex-ydb-1 sudo ls -l /var/log/ydb/"
comment "Каждый из узлов содержит по два файла - для процесса хранения и для процесса БД"
comment ""
comment "Посмотрим что внутри:"
pause

TMPFILE=$(mktemp /tmp/ydb-audit.XXXXXX)

comment "Собираем логи со всех узлов во временный файл..."

for node in yandex-ydb-1 yandex-ydb-2 yandex-ydb-3; do
    ssh user@$node sudo cat /var/log/ydb/ydb-audit-storage.log 2>/dev/null
    ssh user@$node sudo cat /var/log/ydb/ydb-audit-db.log 2>/dev/null
done | sort > "$TMPFILE"

less -p 'audit[a-z]*' +G "$TMPFILE"

rm -f "$TMPFILE"



