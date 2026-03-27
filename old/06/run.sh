#!/bin/sh

# Функция паузы
pause() {
    echo ""
    echo "Нажмите Enter для продолжения..."
    read -r
    echo ""
}

# Цветной вывод для заголовков
print_header() {
    printf "\033[0;32m=== %s ===\033[0m\n" "$1"
}

# Очистка
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_off`'
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_lz4`'

print_header "КРИТЕРИЙ 6: Возможность сжатия данных на уровне хранения"
print_header "БЛОК 1: Создание таблицы без сжатия"
set -x
ydb -p default sql -s 'CREATE TABLE `compression/oorder_compression_off` (
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
        COMPRESSION = "off"
    )
)'

ydb -p default sql -s 'INSERT INTO `compression/oorder_compression_off`
(O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D)
SELECT O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D
FROM `oorder`
LIMIT 500000'
set +x
pause

print_header "БЛОК 2: Создание таблицы со сжатием LZ4"
set -x
ydb -p default sql -s 'CREATE TABLE `compression/oorder_compression_lz4` (
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
        COMPRESSION = "lz4"
    )
)'

ydb -p default sql -s 'INSERT INTO `compression/oorder_compression_lz4`
(O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D)
SELECT O_W_ID, O_D_ID, O_ID, O_C_ID, O_CARRIER_ID, O_OL_CNT, O_ALL_LOCAL, O_ENTRY_D
FROM `compression/oorder_compression_off`'
set +x
pause

print_header "БЛОК 5: Проверка количества строк в таблицах"
set -x
ydb -p default sql -s 'SELECT "oorder_compression_lz4" as table_name, count(*) as row_count
FROM `compression/oorder_compression_lz4`
UNION ALL
SELECT "oorder_compression_off" as table_name, count(*) as row_count
FROM `compression/oorder_compression_off`'
set +x
pause

print_header "БЛОК 5: Проверка размерв "
set -x
ydb -p default sql -s 'SELECT Path, DataSize
FROM `.sys/partition_stats`
WHERE
  Path LIKE "%oorder_compression_off"
  OR Path LIKE "%oorder_compression_lz4"'
set +x
pause
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_off`'
ydb -p default sql -s 'DROP TABLE IF EXISTS `compression/oorder_compression_lz4`'
set +x
echo ""
echo "=== Демонстрация завершена ==="

