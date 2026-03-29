#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций
# КРИТЕРИЙ 53: Встроенный отказоустойчивый кластер (без использования сторонних  компонентов)
# ============================================

header "КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций
КРИТЕРИЙ 53: Встроенный отказоустойчивый кластер (без использования сторонних  компонентов)"

comment "YDB всегда представляет собой отказоустойчивый кластер."
comment "Давайте посмотрим документацию по поддерживаемым топологиям кластера"
link "https://ydb.tech/docs/ru/concepts/topology?version=v25.2"
pause

comment "Посмотрим как настроен наш тестовый кластер"
pause
less -p hosts:  ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml
less -p  mirror-3-dc  ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

comment "Проверим что кластер является отказоустойчивым - выключим один из узлов"
comment "Сначала выполним простой запрос для проверки работоспособности:"
pause

run "ydb -p default sql -s 'SELECT count(*) FROM item'"
pause

comment "Теперь остановим один из узлов кластера:"
run "ssh yandex-ydb-2 sudo systemctl stop ydbd-storage"
run "ssh yandex-ydb-2 sudo systemctl stop ydbd-database-a"

sleep 2
comment "Посмотрим статус узлов кластера:"
run "ydb -p default -d /Root sql -s 'SELECT NodeId, Host FROM \`.sys/nodes\`'"
pause

comment "Проверим, что кластер продолжает работать несмотря на отключение узла:"
run "ydb -p default sql -s 'SELECT count(*) FROM item'"

pause

comment "Проверим, что кластер доступен и на запись - создадим таблицу и запишем данные:"

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS ha_test' 2>/dev/null

run "ydb -p default sql -s 'CREATE TABLE ha_test (
    id Uint64,
    message Utf8,
    PRIMARY KEY (id)
)'"

run "ydb -p default sql -s 'INSERT INTO ha_test (id, message) VALUES (1, \"Кластер работает!\"), (2, \"Запись успешна!\")'"

run "ydb -p default sql -s 'SELECT * FROM ha_test'"

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS ha_test' 2>/dev/null

comment "Отключать второй узел уже нельзя - мы выйдем за модель отказа"
pause

comment "Запустим узел обратно:"
run "ssh yandex-ydb-2 sudo systemctl start ydbd-storage"
run "ssh yandex-ydb-2 sudo systemctl start ydbd-database-a"

pause

# ============================================
# КРИТЕРИЙ 60: Возможность построения active-active кластера
# ============================================

header "КРИТЕРИЙ 60: Возможность построения active-active кластера"

comment "В YDB все узлы кластера являются активными (active-active)."
comment "Это означает, что любой узел может обрабатывать запросы на чтение и запись."
comment "Продемонстрируем это, создав таблицу и записав данные через разные узлы кластера."

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS active_active_test' 2>/dev/null

comment "Создадим таблицу через первый узел (yandex-ydb-1):"
run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2137 sql -s 'CREATE TABLE active_active_test (
    id Uint64,
    node_name Utf8,
    message Utf8,
    PRIMARY KEY (id)
)'"

pause

comment "Запишем первую строку через первый узел (yandex-ydb-1):"
run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2137 sql -s 'INSERT INTO active_active_test (id, node_name, message) VALUES (1, \"yandex-ydb-1\", \"Запись через узел 1\")'"

comment "Запишем вторую строку через второй узел (yandex-ydb-2):"
run "ydb -p default -e grpcs://yandex-ydb-2.ydb-cluster.com:2137 sql -s 'INSERT INTO active_active_test (id, node_name, message) VALUES (2, \"yandex-ydb-2\", \"Запись через узел 2\")'"

comment "Запишем третью строку через третий узел (yandex-ydb-3):"
run "ydb -p default -e grpcs://yandex-ydb-3.ydb-cluster.com:2137 sql -s 'INSERT INTO active_active_test (id, node_name, message) VALUES (3, \"yandex-ydb-3\", \"Запись через узел 3\")'"

pause

comment "Прочитаем все данные, чтобы убедиться, что все записи успешно сохранены:"
run "ydb -p default sql -s 'SELECT * FROM active_active_test ORDER BY id'"

comment "Как видно, все узлы активны и могут обрабатывать запросы на запись."

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS active_active_test' 2>/dev/null

pause

# ============================================
# КРИТЕРИЙ 56: Возможность проксирования запросов на активный узел
# ============================================

header "КРИТЕРИЙ 56: Проксирование запросов на активный узел"

comment "В YDB нет понятия \"активный узел\" - все узлы кластера всегда являются активными"
comment "Однако в большом коммунальном кластере как правило разные узлы обслуживают разные базы данных"
comment "Поэтому есть задача автоматически перенаправить соединение на нужный узел."
comment "Этот процесс называется discovery."
pause

run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2135 discovery list"
comment "Обратите внимание, что подключаемся мы к порту 2135 а discovery вернул нам 2137"
pause

comment "Остановим один из узлов обработки данных"
run "ssh yandex-ydb-1 sudo systemctl stop ydbd-database-a"
pause

comment "Выполним discovery еще раз"
run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2135 discovery list"
comment "Теперь хорошо видно, что обращаемся мы к одному хосту, а база данных обслуживается другими"
pause

comment "Запустим запрос в фоновом режиме, подключаясь к yandex-ydb-1:"
run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2135 sql -s \"SELECT count(*) FROM item i1 CROSS JOIN item i2\" &"

comment ""
comment "Проверим с помощью netstat, к какому хосту установлено соединение:"
pause

run "netstat -antp | grep 2137 | grep ESTABLISHED"
comment "Видно, что соединение установлено не к yandex-ydb-1"
pkill -f "SELECT count.*FROM item"
pause

# ============================================
# КРИТЕРИЙ 45: Автоматическое переключение на резервный узел
# ============================================

header "КРИТЕРИЙ 45: Автоматическое переключение на резервный узел"

comment "Сам по себе discovery не поможет если узел полностью выйдет из строя"
comment ""
comment "Остановим процесс хранения на первом узле"
pause
run "ssh yandex-ydb-1 sudo systemctl stop ydbd-storage"
run "ydb -p default -d /Root sql -s 'SELECT NodeId, Host FROM \`.sys/nodes\`'"

comment "Сейчас мы фактически сымитировали полную недоступность одного из узлов кластера"
comment ""
comment "Попробуем подключиться:"
pause

run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2135 discovery list"
comment "Процесс остановлен, поэтому подключиться не получается"
comment ""
comment "Есть два способа решить эту проблему:"
comment "  - Прокси. Поскольку используется обычный GRPC(S) подойдет любой, поддерживающий этот протокол"
comment "  - DNS имя с несколькими IP <<<<< Именно этот вариант мы сейчас посмотрим"
comment ""
comment "Выполним dig:"
pause

run "dig entrypoint.ydb-cluster.com"
comment ""
comment "Попробуем подключиться:"
pause

run "ydb -p default -e grpcs://entrypoint.ydb-cluster.com:2135 discovery list"
comment "SDK автоматически пробует все IP пока не найдет работающий"
comment ""
comment "Запустим обратно остановленный узел"

pause

run "ssh yandex-ydb-1 sudo systemctl start ydbd-storage"
run "ssh yandex-ydb-1 sudo systemctl start ydbd-database-a"
run "ydb -p default -d /Root sql -s 'SELECT NodeId, Host FROM \`.sys/nodes\`'"
