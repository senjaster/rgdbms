#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 28: Наличие встроенного механизма парольных политик для управления требованиями к сложности паролей
# ============================================

header "КРИТЕРИЙ 28: Наличие встроенного механизма парольных политик для управления требованиями к сложности паролей"

comment "YDB поддерживает настройку парольных политик для управления сложностью паролей:"
comment "- минимальная длина пароля"
comment "- требование к наличию букв, цифр, спецсимволов"
comment "- запрет имени пользователя в пароле"
link "https://ydb.tech/docs/ru/security/authentication?version=v25.2#password-complexity"

pause

comment "Просмотрим конфигурационный файл с настройками парольной политики:"
less -p password_complexity: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

pause

# Очистка (без вывода)
ydb -p default --user root sql -s "DROP USER IF EXISTS testuser" 2>/dev/null

comment "Попробуем создать пользователя с разными паролями:"
comment "Парольная политика требует: минимум 8 символов, буквы разного регистра, цифры и спецсимволы"

pause

comment "Попытка 1: Пароль 'aaa' - слишком короткий"
run "ydb -p default --user root sql -s \"CREATE USER testuser PASSWORD 'aaa'\" || true"

pause

comment "Попытка 2: Пароль 'aaaaaaaaa' - нет заглавных букв, цифр и спецсимволов"
run "ydb -p default --user root sql -s \"CREATE USER testuser PASSWORD 'aaaaaaaaa'\" || true"

pause

comment "Попытка 3: Пароль 'AaAaAaAa' - нет цифр и спецсимволов"
run "ydb -p default --user root sql -s \"CREATE USER testuser PASSWORD 'AaAaAaAa'\" || true"

pause

comment "Попытка 4: Пароль 'AaAa1234' - нет спецсимволов"
run "ydb -p default --user root sql -s \"CREATE USER testuser PASSWORD 'AaAa1234'\" || true"

pause

comment "Попытка 5: Пароль 'AaAa1234%' - соответствует всем требованиям!"
run "ydb -p default --user root sql -s \"CREATE USER testuser PASSWORD 'AaAa1234%'\""

pause

# Очистка (без вывода)
ydb -p default --user root sql -s "DROP USER IF EXISTS testuser" 2>/dev/null

# ============================================
# КРИТЕРИЙ 29: Наличие встроенного механизма парольных политик для управления жизненным циклом паролей
# ============================================

header "КРИТЕРИЙ 29: Наличие встроенного механизма парольных политик для управления жизненным циклом паролей"

comment "YDB контролирует количество неудачных попыток входа и блокирует учетные записи."
link "https://ydb.tech/docs/ru/security/authentication?version=v25.2#zashita-ot-perebora-parolya"
pause

comment "Просмотрим конфигурационный файл с настройками блокировки учетных записей:"
less -p account_lockout: ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

pause

# Очистка (без вывода)
ydb -p default --user root sql -s "DROP USER IF EXISTS test2" 2>/dev/null

comment "Создадим тестового пользователя:"
run "ydb -p default --user root sql -s \"CREATE USER test2 PASSWORD 'PASSw0rd!!!'\""
run "ydb -p default --user root sql -s \"ALTER GROUP ADMINS ADD USER test2\""

pause

comment "Теперь попробуем войти с неправильным паролем несколько раз подряд"
comment "После нескольких неудачных попыток учетная запись будет заблокирована"
link "https://10.40.13.21:8765/monitoring/cluster/tenants"

pause

# Очистка (без вывода)
ydb -p default --user root sql -s "DROP USER IF EXISTS test2" 2>/dev/null
