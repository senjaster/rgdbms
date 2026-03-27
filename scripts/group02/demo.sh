#!/bin/sh

# Загружаем библиотеку вспомогательных функций
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

header "КРИТЕРИЙ 6: Возможность сжатия данных на уровне хранения"

comment "YDB поддерживает сжатие данных на уровне хранения."
comment "Доступны алгоритмы сжатия lz4 и zstd."
comment ""

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_off`' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_lz4`' 2>/dev/null

# ============================================
# БЛОК 1: Создание таблицы без сжатия
# ============================================

header "БЛОК 1: Создание таблицы без сжатия"

comment "Создаем таблицу с параметром COMPRESSION = \"off\":"

run "ydb -p default sql -s 'CREATE TABLE \`compression/oorder_compression_off\` (
    O_W_ID Int32 NOT NULL,
    O_D_ID Int32 NOT NULL,
    O_ID Int32 NOT NULL,
    O_C_ID Int32,
    O_CARRIER_ID Int32,
    O_OL_CNT Int32,
    O_ALL_LOCAL Int32,
    O_ENTRY_D Timestamp,
    PRIMARY KEY (O_W_ID, O_D_ID, O_ID),
    FAMILY default (
        COMPRESSION = \"off\"
    )
)'"

comment "Заполняем таблицу данными (500000 строк):"

run "ydb -p default sql -s 'INSERT INTO \`compression/oorder_compression_off\`
(O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D)
SELECT O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D
FROM \`oorder\`
LIMIT 500000'"

pause

# ============================================
# БЛОК 2: Создание таблицы со сжатием LZ4
# ============================================

header "БЛОК 2: Создание таблицы со сжатием LZ4"

comment "Создаем таблицу с параметром COMPRESSION = \"lz4\":"

run "ydb -p default sql -s 'CREATE TABLE \`compression/oorder_compression_lz4\` (
    O_W_ID Int32 NOT NULL,
    O_D_ID Int32 NOT NULL,
    O_ID Int32 NOT NULL,
    O_C_ID Int32,
    O_CARRIER_ID Int32,
    O_OL_CNT Int32,
    O_ALL_LOCAL Int32,
    O_ENTRY_D Timestamp,
    PRIMARY KEY (O_W_ID, O_D_ID, O_ID),
    FAMILY default (
        COMPRESSION = \"lz4\"
    )
)'"

comment "Заполняем таблицу теми же данными:"

run "ydb -p default sql -s 'INSERT INTO \`compression/oorder_compression_lz4\`
(O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D)
SELECT O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D
FROM \`compression/oorder_compression_off\`'"

pause

# ============================================
# БЛОК 3: Проверка количества строк в таблицах
# ============================================

header "БЛОК 3: Проверка количества строк в таблицах"

comment "Убеждаемся, что в обеих таблицах одинаковое количество строк:"

run "ydb -p default sql -s 'SELECT \"oorder_compression_lz4\" as table_name, count(*) as row_count
FROM \`compression/oorder_compression_lz4\`
UNION ALL
SELECT \"oorder_compression_off\" as table_name, count(*) as row_count
FROM \`compression/oorder_compression_off\`'"

comment ""
comment "Документация по сжатию"
comment ""
link "https://ydb.tech/docs/ru/yql/reference/syntax/create_table/family?version=v25.2"
comment ""

pause

# ============================================
# БЛОК 4: Проверка размеров таблиц
# ============================================

header "БЛОК 4: Проверка размеров таблиц"

comment "Сравниваем размеры таблиц с разными типами сжатия:"
comment "Таблица со сжатием LZ4 должна занимать меньше места."

run "ydb -p default sql -s 'SELECT Path, DataSize
FROM \`.sys/partition_stats\`
WHERE
  Path LIKE \"%oorder_compression_off\"
  OR Path LIKE \"%oorder_compression_lz4\"'"

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_off`' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_lz4`' 2>/dev/null
