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
ydb -p default --user root sql -s "DROP USER IF EXISTS testaudit" 2>/dev/null
ydb -p default --user root sql -s "DROP TABLE IF EXISTS testaudit_table" 2>/dev/null
ydb -p default --user root sql -s "DROP GROUP IF EXISTS testgroup" 2>/dev/null

run "ydb -p default --user root sql -s \"CREATE USER testaudit PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default --user root sql -s \"CREATE GROUP testgroup\""

run "ydb -p default --user root sql -s \"ALTER GROUP testgroup ADD USER testaudit\""

run "ydb -p default --user root sql -s \"CREATE TABLE testaudit_table (id Int32, name Utf8, PRIMARY KEY (id))\""

run "ydb -p default --user root sql -s \"DROP TABLE testaudit_table\""

run "ydb -p default --user root sql -s \"DROP GROUP testgroup\""

run "ydb -p default --user root sql -s \"DROP USER testaudit\""

comment "Попытка неуспешного подключения с неправильным именем пользователя:"

run "ydb -p default --user wronguser --no-password sql -s \"SELECT 1\" || true"

pause

# ============================================
# КРИТЕРИЙ 34: Возможность хранения журнала аудита в выделенном файле
# ============================================

header "КРИТЕРИЙ 34: Возможность хранения журнала аудита в выделенном файле"

comment "YDB сохраняет журнал аудита в выделенный файл."
comment "Проверим записи в журнале аудита о созданном пользователе testaudit:"
comment ""
run "ssh user@yandex-ydb-1 sudo ls -l /var/log/ydb/"
comment "Каждый из узлов содержит по два файла - для процесса хранения и для процесса БД"
comment ""
comment "Посмотрим что внутри:"
pause

run "for node in yandex-ydb-1 yandex-ydb-2 yandex-ydb-3; do
    ssh user@\$node sudo grep testaudit /var/log/ydb/ydb-audit-storage.log 2>/dev/null
    ssh user@\$node sudo grep testaudit /var/log/ydb/ydb-audit-db.log 2>/dev/null
done | sort"

pause


