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
run "ydb -p default sql -s 'ALTER TABLE item ADD INDEX idx_item_name GLOBAL ON (I_NAME)'"

pause

comment "Посмотрим что получилось"
run "ydb -p default sql -s 'SELECT Path, count(*) as part_count, sum(RowCount) as total_rows FROM \`.sys/partition_stats\` WHERE Path LIKE \"%item%\" GROUP BY Path ORDER BY Path'"

pause

comment "Удалим индекс"
run "ydb -p default sql -s 'ALTER TABLE item DROP INDEX idx_item_name'"

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

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS auto_partition_demo' 2>/dev/null

comment "Создадим таблицу с автоматическим разбиением по размеру"
comment "Разбиение будет происходить при достижении 10МБ"
run "ydb -p default sql -s 'CREATE TABLE auto_partition_demo (id Uint64, payload String, PRIMARY KEY (id)) WITH (AUTO_PARTITIONING_BY_SIZE = ENABLED, AUTO_PARTITIONING_PARTITION_SIZE_MB = 1)'"

pause

comment "Добавим 10 строк с длинным payload"
run "ydb -p default sql -s '\$maxid = SELECT max(id) FROM auto_partition_demo; INSERT INTO auto_partition_demo(id, payload) SELECT unwrap(ROW_NUMBER() OVER (ORDER BY I_ID) + \$maxid) as id, \"AAAAAAAAAA\" as payload FROM item'"

pause

comment "Проверим начальное состояние - размер и количество партиций"
run "ydb -p default sql -s 'SELECT Path, count(*) as part_count, sum(RowCount) as total_rows, sum(DataSize) as total_size_bytes FROM \`.sys/partition_stats\` WHERE Path LIKE \"%auto_partition_demo%\" GROUP BY Path ORDER BY Path'"

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS auto_partition_demo' 2>/dev/null
