#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций
# КРИТЕРИЙ 53: Встроенный отказоустойчивый кластер
# ============================================

header "КРИТЕРИЙ 44: Наличие в поставке инструментов для построения отказоустойчивых конфигураций\nКРИТЕРИЙ 53: Встроенный отказоустойчивый кластер"
comment "YDB всегда представляет собой отказоустойчивый кластер"
comment "Существует возможность создать "одноузловой кластер без отказоустойчивости", но это опция исключительно для"
comment "разработки и проведения тестов, например в докер-контейнерах."

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
run "netstat -a | grep :2137"
comment "Видно, что соединение установлено не к yandex-ydb-1"
pkill -f "SELECT count.*FROM item"
pause

# ============================================

header "КРИТЕРИЙ 45: Автоматическое переключение на резервный узел"

comment "Сам по себе discovery не поможет если узел полностью выйдет из строя"
comment "Остановим процесс хранения на первом узле"
pause
run "ssh yandex-ydb-1 sudo systemctl stop ydbd-storage"
comment "Сейчас мы фактически сымитировали полную недоступность одного из узлов кластера"
comment ""
comment "Выполним discovery еще раз"
pause

run "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com:2135 discovery list"

run "ydb -p default -e grpcs://entrypoint.ydb-cluster.com:2135 discovery list"

ssh yandex-ydb-1 sudo systemctl start ydbd-storage
ssh yandex-ydb-1 sudo systemctl start ydbd-database-a