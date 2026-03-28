#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 76: Поддержка глобальных индексов для секционированных таблиц
# ============================================

header "КРИТЕРИЙ 76: Поддержка глобальных индексов для секционированных таблиц"

comment "СУБД позволяет создавать и использовать индексы , которые содержат данные,"
comment "относящиеся к индексированным столбцам для всех секций, что позволяет выполнять"
comment "сканирование индекса без перебора всех секций"

comment "Все индексы в YDB "глобальные" - индекс представляет собой отдельную скрытую таблицу."
comment "Точно так же как и таблицы индексы могут секционироваться, но это полностью независтмый процесс:"
comment "секция может быть всего одна, а если их несколько то границы не будут совпадать"

pause

comment "Добавим индекс на столбец I_NAME"
run "ALTER TABLE item ADD INDEX idx_item_name GLOBAL ON (I_NAME)"

pause

comment "Посмотрим что получилось"
run "SELECT Path, count(*) as part_count, sum(RowCount) as total_rows FROM \`.sys/partition_stats\` WHERE Path LIKE '%item%' GROUP BY Path ORDER BY Path"

pause

comment "Удалим индекс"
run "ALTER TABLE item DROP INDEX idx_item_name"

pause

# ============================================
# КРИТЕРИЙ 77: Автосекционирование (автоматическое создание секций)
# ============================================

header "КРИТЕРИЙ 77: Автосекционирование (автоматическое создание секций)"

comment "В подавляющем большинстве случаев YDB автоматически управляет разбиением таблицы на секции"
comment "Есть два основных критерия, по которым секции разбиваются и объединяются"
comment " - Размер"
comment " - Нагрузка"
link "https://ydb.tech/docs/ru/concepts/architecture?version=v25.2#razdelenie-po-nagruzke"

pause

comment "Создадим таблицу с автоматическим разбиением по размеру"
comment "Разбиение будет происходить при достижении 10МБ"
run "CREATE TABLE auto_partition_demo (
    id Uint64,
    payload String,
    PRIMARY KEY (id)
)
WITH (
    AUTO_PARTITIONING_BY_SIZE = ENABLED,
    AUTO_PARTITIONING_PARTITION_SIZE_MB = 10
)"

pause

comment "Добавим 10 строк с длинным payload (примерно 100KB каждая)"
run "INSERT INTO auto_partition_demo (id, payload)
VALUES
    (1, 'AAAAAAAAAA'),
    (2, 'AAAAAAAAAA'),
    (3, 'AAAAAAAAAA'),
    (4, 'AAAAAAAAAA'),
    (5, 'AAAAAAAAAA'),
    (6, 'AAAAAAAAAA'),
    (7, 'AAAAAAAAAA'),
    (8, 'AAAAAAAAAA'),
    (9, 'AAAAAAAAAA'),
    (10, 'AAAAAAAAAA')"

pause

comment "Проверим начальное состояние - размер и количество партиций"
run "SELECT Path, count(*) as part_count, sum(RowCount) as total_rows, sum(DataSize) as total_size_bytes FROM \`.sys/partition_stats\` WHERE Path LIKE '%auto_partition_demo%' GROUP BY Path ORDER BY Path"

pause

comment "Размножим строки с помощью CROSS JOIN (10 * 10 = 100 строк)"
run "INSERT INTO auto_partition_demo (id, payload)
SELECT t1.id * 100 + t2.id as id, t1.payload || t2.payload as payload
FROM auto_partition_demo AS t1
CROSS JOIN (SELECT id FROM auto_partition_demo WHERE id <= 10) AS t2"

pause

comment "Проверим состояние после первого размножения"
run "SELECT Path, count(*) as part_count, sum(RowCount) as total_rows, sum(DataSize) as total_size_bytes FROM \`.sys/partition_stats\` WHERE Path LIKE '%auto_partition_demo%' GROUP BY Path ORDER BY Path"

pause

comment "Удалим тестовую таблицу"
$YDB_CLI table drop auto_partition_demo

pause
