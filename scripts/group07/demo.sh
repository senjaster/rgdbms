#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"


header "КРИТЕРИЙ 28: Наличие встроенного механизма парольных политик для управления требованиями к сложности паролей"

comment "YDB поддерживает настройку парольных политик для управления сложностью паролей:"
comment "- минимальная длина пароля"
comment "- требование к наличию букв, цифр, спецсимволов"
comment "- запрет словарных слов"
comment ""
comment "Просмотрим конфигурационный файл с настройками парольной политики:"
comment ""
pause
less -p  password_complexity: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml


comment "Попробуем создать пользователя:"
pause

scriptreplay -t "${SCRIPT_DIR}/criteria28_timingfile.tm" -m 3 -d 1 "${SCRIPT_DIR}/criteria28_session.log"

pause

header "КРИТЕРИЙ 29: Наличие встроенного механизма парольных политик для управления жизненным циклом паролей"

comment "YDB контролирует количество неудачных попыток входа и блокирует учетные записи."
link "https://ydb.tech/docs/ru/security/authentication?version=v25.2#password-policy"
comment "Просмотрим конфигурационный файл:"
pause

less -p account_lockout: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

comment "Создадим тестового пользователя:"
comment ""

# Очистка
ydb -p default --user root sql -s "DROP USER IF EXISTS test2" 2>/dev/null

run "ydb -p default --user root sql -s \"CREATE USER test2 PASSWORD 'PASSw0rd!!!'\""
run "ydb -p default --user root sql -s \"ALTER GROUP ADMINS ADD USER test2\""
comment "И теперь притворимся что забыли пароль:"
link "https://10.40.13.21:8765/monitoring/cluster/tenants"
pause

# Очистка
ydb -p default --user root sql -s "DROP USER IF EXISTS test2" 2>/dev/null
