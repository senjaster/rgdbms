#!/bin/sh

# Функция паузы
pause() {
    echo ""
    echo "Нажмите Enter для продолжения..."
    read -r
    echo ""
}

echo "=== БЛОК 1: Запрос распределения нагрузки по узлам (до запуска workload) ==="
echo "Проверяем текущее распределение активных сессий по узлам кластера:"
set -x
ydb -p default sql -s 'SELECT NodeId, count(*) 
FROM `.sys/query_sessions` 
WHERE ClientAddress LIKE "%10.40.13.20%"
GROUP BY NodeId'
set +x
pause

echo "=== БЛОК 2: Запуск TPCC workload в фоновом режиме ==="
echo "Команда для запуска workload:"
echo "ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com workload tpcc run -w 10 --no-tui"
echo ""
echo "Запускаем workload в фоне..."
set -x
ydb -p default -e grpcs://yandex-ydb-1.ydb-cluster.com workload tpcc run -w 10 --no-tui &
WORKLOAD_PID=$!
set +x
echo "Workload запущен с PID: $WORKLOAD_PID"
echo "Ожидаем 5 секунд для стабилизации нагрузки..."
sleep 5
pause

echo "=== БЛОК 3: Запрос распределения нагрузки по узлам (во время работы workload) ==="
echo "Проверяем распределение активных сессий по узлам во время нагрузки:"
set -x
ydb -p default sql -s 'SELECT NodeId, count(*) 
FROM `.sys/query_sessions` 
WHERE ClientAddress LIKE "%10.40.13.20%"
GROUP BY NodeId'
set +x
pause

echo "=== БЛОК 4: Остановка фонового процесса workload ==="
echo "Останавливаем workload с PID: $WORKLOAD_PID"
set -x
kill $WORKLOAD_PID 2>/dev/null || echo "Процесс уже завершен"
wait $WORKLOAD_PID 2>/dev/null
set +x
echo ""
echo "=== Демонстрация завершена ==="


