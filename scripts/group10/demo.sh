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
comment "Существует возможность создать "одноузловой кластер без отказоустойчивости", но это опция "
comment "ТОЛЬКО для разработки и проведения тестов, например в докер-контейнерах."

comment "Давайте посмотрим документацию по поддерживаемым топологиям кластера"
link "https://ydb.tech/docs/ru/concepts/topology?version=v25.2"
pause

comment "Посмотрим как настроен наш тестовый кластер"
pause
less -p hosts:  ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml
less -p  mirror-3-dc  ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml

comment "Для примера посмотрим, как узлы кластера видят друг друга"
link "https://10.40.13.21:8765/actors/interconnect/overview"

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

run "netstat -antp | grep 2137"
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

comment "Давайте посмотрим, как это выгляди на практике:"
comment "Запустим тест tpc-c, встроеный в YDB"
pause

ydb -p default -e grpcs://entrypoint.ydb-cluster.com workload tpcc run -w 100

comment "Запустим обратно остановленный узел"

pause

run "ssh yandex-ydb-1 sudo systemctl start ydbd-storage"
run "ssh yandex-ydb-1 sudo systemctl start ydbd-database-a"
