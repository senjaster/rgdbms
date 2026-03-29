#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

export YDB_PASSWORD=PASSw0rd!!!


# ============================================
# КРИТЕРИЙ 61: Поддержка многоузловых транзакций
# ============================================

header "КРИТЕРИЙ 61: Поддержка многоузловых транзакций"

comment "YDB поддерживает распределенные транзакции, которые могут изменять данные в разных партициях,"
comment "которые размещены на разных узлах."
link "https://ydb.tech/docs/ru/contributor/datashard-distributed-txs?version=v25.2"
comment "Создадим таблицу с двумя партициями и продемонстрируем транзакцию, изменяющую данные в обеих."
comment ""
comment "Создадим таблицу с ключом типа Uint32 и полем value типа Int32:"
comment "Партиции будут разделены по ключу 20 (PARTITION_AT_KEYS)"

pause

ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/distributed_txn/test`'

run "ydb -p default sql -s 'CREATE TABLE \`/Root/database/distributed_txn/test\` (
    id Uint32 NOT NULL,
    value Int32,
    PRIMARY KEY (id)
)
WITH (
    PARTITION_AT_KEYS = (20),
    AUTO_PARTITIONING_BY_LOAD = DISABLED,
    AUTO_PARTITIONING_BY_SIZE = DISABLED
)'"

pause

comment "Добавим две строки: одну в первую партицию (id=10), другую во вторую (id=30):"

run "ydb -p default sql -s 'INSERT INTO \`/Root/database/distributed_txn/test\` (id, value) VALUES (10, 0), (30, 0)'"

pause

comment "Проверим начальное состояние:"

run "ydb -p default sql -s 'SELECT id, value FROM \`/Root/database/distributed_txn/test\` ORDER BY id'"
run "ydb -p default sql -s 'SELECT SUM(value) AS total FROM \`/Root/database/distributed_txn/test\`'"

pause

comment "Запустим в фоне многоузловые транзакции с помощью ydb-bench:"
comment "Каждая транзакция будет увеличивать значение в строке 10 на 1 и уменьшать в строке 30 на 1"
comment "Сумма должна оставаться неизменной (200), что подтверждает атомарность транзакций"

run "ydb-bench \
  --endpoint grpcs://yandex-ydb-1.ydb-cluster.com:2135 \
  --database /Root/database \
  --ca-file ~/ca.crt \
  --user root \
  --scale 1 \
  --prefix-path distributed_txn \
  run \
  --jobs 1 -P 10 -T 30 \
  --no-validate-scale \
  --file multi_partition_txn.sql &"

WORKLOAD_PID=$!

comment "Workload запущен с PID: $WORKLOAD_PID"
comment "Ожидаем 2 секунды..."
sleep 2

pause

comment "Во время выполнения транзакций проверим сумму значений:"
comment "Она должна оставаться равной 0, несмотря на параллельные изменения"

run "ydb -p default sql -s 'SELECT SUM(value), MAX(value) AS total FROM \`/Root/database/distributed_txn/test\`'"
pause

run "ydb -p default sql -s 'SELECT SUM(value), MAX(value) AS total FROM \`/Root/database/distributed_txn/test\`'"
pause

run "ydb -p default sql -s 'SELECT SUM(value), MAX(value) AS total FROM \`/Root/database/distributed_txn/test\`'"
pause

comment "Подождем завершения workload"

wait $WORKLOAD_PID 2>/dev/null

ydb -p default sql -s 'DROP TABLE `/Root/database/distributed_txn/test`' 2>/dev/null

pause

# ============================================
# КРИТЕРИЙ 55: Наличие механизма балансировки читающей нагрузки
# ============================================

header "КРИТЕРИЙ 55: Наличие механизма балансировки читающей нагрузки"

comment "YDB автоматически распределяет клиентские подключения между узлами кластера."
comment "Как частный случай это приводит к балансировке читающей нагрузки."

comment "Используем утилиту ydb-bench для генерации данных и запуска параллельных запросов."
comment "Создадим таблицы и заполним их данными."
pause

run "ydb-bench --endpoint grpcs://entrypoint.ydb-cluster.com:2135 --database /Root/database --ca-file ~/ca.crt --user root --password \"\$YDB_PASSWORD\" --prefix-path bench --scale 30 init"

comment "Проверим текущее распределение активных сессий по узлам кластера:"

run "ydb -p default sql -s 'SELECT NodeId, count(*) 
FROM \`.sys/query_sessions\` 
WHERE ClientAddress LIKE \"%10.40.13.20%\"
GROUP BY NodeId'"

pause

comment "Запустим 30 параллельных читающих запросов в фоновом режиме:"
comment "Используем встроенный workload tpcb-like с 30 jobs"

run "ydb-bench --endpoint grpcs://entrypoint.ydb-cluster.com:2135 --database /Root/database --ca-file ~/ca.crt --user root --prefix-path bench --scale 30 run --jobs 30 --transactions 1000 &"
WORKLOAD_PID=$!

comment "Workload запущен с PID: $WORKLOAD_PID"
comment "Ожидаем 5 секунд для стабилизации нагрузки..."
sleep 5

pause

comment "Проверим распределение активных сессий по узлам во время нагрузки:"
comment "Видно, что сессии распределены между несколькими узлами кластера"

run "ydb -p default sql -s 'SELECT NodeId, count(*) 
FROM \`.sys/query_sessions\` 
WHERE ClientAddress LIKE \"%10.40.13.20%\"
GROUP BY NodeId'"

pause

comment "Остановим фоновый процесс workload"

kill $WORKLOAD_PID 2>/dev/null || echo "Процесс уже завершился сам"
wait $WORKLOAD_PID 2>/dev/null


# ============================================
# КРИТЕРИЙ 57: Поддержка конфигурации кластера с несколькими мастерами
# ============================================

header "КРИТЕРИЙ 57: Поддержка конфигурации кластера с несколькими мастерами"

comment "TODO: Критерий не реализован"

pause


# ============================================
# КРИТЕРИЙ 64: Наличие механизма автоматического распределения данных по узлам
# ============================================

header "КРИТЕРИЙ 64: Наличие механизма автоматического распределения данных по узлам"

comment "TODO: Критерий не реализован"

pause