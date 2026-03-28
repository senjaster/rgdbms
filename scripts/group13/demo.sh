#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 55: Наличие механизма балансировки читающей нагрузки
# ============================================

header "КРИТЕРИЙ 55: Наличие механизма балансировки читающей нагрузки"

comment "YDB автоматически распределяет клиентские подключения между узлами кластера."
comment "Как частный случай это приводит к балансировке читающей нагрузки."

comment "Используем утилиту ydb-bench для генерации данных и запуска параллельных запросов."
comment "Создадим таблицы и заполним их данными."
pause

run "ydb-bench --endpoint grpcs://entrypoint.ydb-cluster.com:2135 --database /Root/database --prefix-path pgbench init --scale 100"

comment "Проверим текущее распределение активных сессий по узлам кластера:"

run "ydb -p default sql -s 'SELECT NodeId, count(*) 
FROM \`.sys/query_sessions\` 
WHERE ClientAddress LIKE \"%10.40.13.20%\"
GROUP BY NodeId'"

pause

comment "Запустим 30 параллельных читающих запросов в фоновом режиме:"
comment "Используем встроенный workload tpcb-like с 30 jobs"

run "ydb-bench --endpoint grpcs://entrypoint.ydb-cluster.com:2135 --database /Root/database --prefix-path pgbench run --jobs 30 --transactions 1000 &"
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

comment "Остановим фоновый процесс workload:"

run "kill $WORKLOAD_PID 2>/dev/null || echo \"Процесс уже завершен\""
wait $WORKLOAD_PID 2>/dev/null

pause
