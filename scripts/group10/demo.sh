#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций
# КРИТЕРИЙ 53: Встроенный отказоустойчивый кластер
# КРИТЕРИЙ 60: Возможность построения active-active кластера
# ============================================

header "КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций
КРИТЕРИЙ 53: Встроенный отказоустойчивый кластер
КРИТЕРИЙ 60: Возможность построения active-active кластера"

comment "YDB всегда представляет собой отказоустойчивый кластер."
comment "Все узлы кластера являются активными (active-active), что обеспечивает высокую доступность и производительность."
comment ""
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
comment "Отключать второй узел уже нельзя - мы выйдем за модель отказа"
pause

comment "Запустим узел обратно:"
run "ssh yandex-ydb-2 sudo systemctl start ydbd-storage"
run "ssh yandex-ydb-2 sudo systemctl start ydbd-database-a"

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


comment "Давайте посмотрим, как это выглядит на практике:"
comment "Запустим тест tpc-c, встроеный в YDB"
pause

ydb -p default -e grpcs://entrypoint.ydb-cluster.com workload tpcc run -w 100

comment "Запустим обратно остановленный узел"

pause

run "ssh yandex-ydb-1 sudo systemctl start ydbd-storage"
run "ssh yandex-ydb-1 sudo systemctl start ydbd-database-a"
