#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 84: Расширенное управление очередями (Advanced Queueing)
# ============================================

header "КРИТЕРИЙ 84: Расширенное управление очередями (Advanced Queueing)"

comment "YDB поддерживает работу с топиками (topics) - распределенными очередями сообщений."
comment "Топики обеспечивают надежную доставку сообщений, поддержку множественных потребителей,"
comment "партиционирование для масштабирования и различные кодеки сжатия."

pause

# Очистка (без вывода)
ydb -p default topic drop demo-topic 2>/dev/null

comment "Создадим топик и добавим к нему консьюмера"
run "ydb -p default topic create --supported-codecs raw,gzip demo-topic"
run "ydb -p default topic consumer add --consumer demo-consumer demo-topic"

pause

comment "Проверим что получилось:"
run "ydb -p default scheme describe demo-topic"
comment "Топики можно посмотреть и в WebUI"
link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&diagnosticsTab=overview&database=%2FRoot%2Fdatabase&schema=%2FRoot%2Fdatabase%2Fdemo-topic"

pause

comment "Теперь с созданым топуком можно работать точно так же как если бы он был в kafka"
comment ""
comment "Вот команда для запуска обчыного kafka-console-producer:"
run "cat topic_producer.sh" 
comment ""
comment "А вот - для kafka-console-consumer:"
run "cat topic_consumer.sh" 
comment "Запустим их в отдельной сессии чтобы посмотреть как они работают"
pause

#####################
# Демо changefeed

header "Использование топиков для CHANGE DATA CAPTURE"

comment "YDB поддерживает Change Data Capture (CDC) через механизм changefeed."
comment "Changefeed автоматически создает топик, в который публикуются все изменения таблицы."
comment "Это позволяет отслеживать изменения данных в реальном времени."

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS cdc_demo_table' 2>/dev/null

comment "Создадим тестовую таблицу"
run "ydb -p default sql -s 'CREATE TABLE cdc_demo_table (
    id Uint64,
    name Utf8,
    value Int32,
    PRIMARY KEY (id)
)'"

pause

comment "Настроим на таблицу CHANGEFEED с режимом UPDATES и форматом JSON"
run "ydb -p default sql -s 'ALTER TABLE cdc_demo_table ADD CHANGEFEED cdc_demo_feed WITH (MODE=\"UPDATES\", FORMAT=\"JSON\")'"
run "ydb -p default topic consumer add --consumer demo-consumer cdc_demo_table/cdc_demo_feed"
pause

comment "Посмотрим описание таблицы с changefeed"
run "ydb -p default scheme describe cdc_demo_table"
link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&diagnosticsTab=overview&database=%2FRoot%2Fdatabase&schema=%2FRoot%2Fdatabase%2Fcdc_demo_table%2Fcdc_demo_feed&selectedPartition=0"

pause

comment "Вставим первую порцию данных в таблицу"
run "ydb -p default sql -s 'INSERT INTO cdc_demo_table (id, name, value) VALUES (1, \"Alice\", 100), (2, \"Bob\", 200)'"

pause

comment "Теперь можно запустить consumer для чтения изменений из changefeed"
comment "Будем использовать встроеный в ydb cli консьюмер"
run "cat changefeed_cons_ydb.sh"
comment ""
comment "Запустим его в отдельной сессии, чтобы увидеть изменения в реальном времени"

pause

comment "Вставим еще данные в таблицу"
run "ydb -p default sql -s 'INSERT INTO cdc_demo_table (id, name, value) VALUES (3, \"Charlie\", 300)'"

pause

comment "Обновим существующую запись"
run "ydb -p default sql -s 'UPDATE cdc_demo_table SET value = 150 WHERE id = 1'"

pause

comment "Удалим запись"
run "ydb -p default sql -s 'DELETE FROM cdc_demo_table WHERE id = 2'"

pause

comment "Все эти изменения будут видны в consumer, который читает changefeed"
comment "Посмотрим состояние changefeed в WebUI"
link "https://10.40.13.21:8765/"

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS cdc_demo_table' 2>/dev/null
ydb -p default topic consumer drop --consumer demo-consumer demo-topic 2>/dev/null
ydb -p default topic drop demo-topic 2>/dev/null