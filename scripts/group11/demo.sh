#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 48: Наличие в поставке инструментов, позволяющих выполнять резервное копирование и восстановление
# ============================================

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/customers`' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/orders`' 2>/dev/null
rm -rf ./backup_demo 2>/dev/null
rm -rf ./backup_demo_schema 2>/dev/null
rm -rf ./backup_demo_table_consistency 2>/dev/null

header "КРИТЕРИЙ 48: Наличие в поставке инструментов, позволяющих выполнять резервное копирование и восстановление"

comment "Создадим таблицы в папке /Root/database/folder1/subfolder2:"

run "ydb -p default sql -s 'CREATE TABLE \`/Root/database/folder1/subfolder2/customers\`(
    customer_id Uint64 NOT NULL,
    name Utf8,
    email Utf8,
    PRIMARY KEY (customer_id)
)'"

run "ydb -p default sql -s 'CREATE TABLE \`/Root/database/folder1/subfolder2/orders\`(
    order_id Uint64 NOT NULL,
    customer_id Uint64,
    amount Double,
    order_date Date,
    PRIMARY KEY (order_id)
)'"

pause

comment "Заполним таблицы данными:"

run "ydb -p default sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/customers\` (customer_id, name, email) VALUES
    (1, \"Иван Иванов\", \"ivan@example.com\"),
    (2, \"Мария Петрова\", \"maria@example.com\"),
    (3, \"Алексей Сидоров\", \"alexey@example.com\")'"

run "ydb -p default sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/orders\` (order_id, customer_id, amount, order_date) VALUES
    (101, 1, 1500.50, Date(\"2024-01-15\")),
    (102, 1, 2300.00, Date(\"2024-02-20\")),
    (103, 2, 750.25, Date(\"2024-01-18\")),
    (104, 3, 3200.00, Date(\"2024-03-10\")),
    (105, 2, 1100.75, Date(\"2024-03-15\"))'"

pause

comment "Проверим данные в таблицах:"

run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/customers\`'"
run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/orders\`'"

pause

comment "Создадим резервную копию папки:"

run "ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo"

comment "Содержимое директории backup_demo:"
ls -lR ./backup_demo

pause

comment "Создадим резервную копию только схемы (без данных):"

run "ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo_schema --scheme-only"

comment "Содержимое директории backup_demo_schema:"
ls -lR ./backup_demo_schema

pause

comment "Создадим резервную копию с уровнем консистентности 'table':"

run "ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo_table_consistency --consistency-level table"

pause

comment "Удалим таблицы для демонстрации восстановления:"

run "ydb -p default sql -s 'DROP TABLE \`/Root/database/folder1/subfolder2/customers\`'"
run "ydb -p default sql -s 'DROP TABLE \`/Root/database/folder1/subfolder2/orders\`'"

comment "Проверим, что таблицы удалены (должна быть ошибка):"
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`' 2>&1 || echo "Таблица customers не найдена (ожидаемо)"

pause

comment "Восстановим из резервной копии:"

run "ydb -p default tools restore -p /Root/database/folder1/subfolder2 -i ./backup_demo"

pause

comment "Проверим восстановленные данные:"

run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/customers\`'"
run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/orders\`'"

pause

# ============================================
# КРИТЕРИЙ 51: Наличие в поставке инструментов, позволяющих выполнять резервное копирование и восстановление на S3
# ============================================

header "КРИТЕРИЙ 51: Наличие в поставке инструментов, позволяющих выполнять резервное копирование и восстановление на S3"

# Конфигурация S3
S3_ENDPOINT="http://10.40.13.20:9000"
S3_BUCKET="ydb-backup"
S3_ACCESS_KEY="root"
S3_SECRET_KEY="PASSw0rd!!!"
S3_EXPORT_PREFIX="ydb_export_demo"

comment "Выгрузим обе таблицы в S3:"
comment "Export Path: $S3_EXPORT_PREFIX/both_tables"

run "ydb -p default export s3 \
  --s3-endpoint \"$S3_ENDPOINT\" \
  --bucket \"$S3_BUCKET\" \
  --access-key \"$S3_ACCESS_KEY\" \
  --secret-key \"$S3_SECRET_KEY\" \
  --item src=/Root/database/folder1/subfolder2/customers,dst=\"$S3_EXPORT_PREFIX/both_tables/customers\" \
  --item src=/Root/database/folder1/subfolder2/orders,dst=\"$S3_EXPORT_PREFIX/both_tables/orders\" \
  --description \"Выгрузка обеих таблиц\""

pause

comment "Бэкап в S3 выполняется сервером без участия клиентского приложения, и может занимать много времени"
comment "поэтому в ydb есть понятие фоновых операций и способ посмотреть что там происходит."
comment ""
comment "Получим список операций экспорта:"

run "ydb -p default operation list export/s3"

pause

comment "Удалим таблицы для демонстрации восстановления:"

run "ydb -p default sql -s 'DROP TABLE \`/Root/database/folder1/subfolder2/customers\`'"
run "ydb -p default sql -s 'DROP TABLE \`/Root/database/folder1/subfolder2/orders\`'"

comment "Проверим, что таблицы удалены (должна быть ошибка):"
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`' 2>&1 || echo "Таблица customers не найдена (ожидаемо)"

pause

comment "Восстановим обе таблицы из S3:"
comment "Import Path: $S3_EXPORT_PREFIX/both_tables"

run "ydb -p default import s3 \
  --s3-endpoint \"$S3_ENDPOINT\" \
  --bucket \"$S3_BUCKET\" \
  --access-key \"$S3_ACCESS_KEY\" \
  --secret-key \"$S3_SECRET_KEY\" \
  --item src=\"$S3_EXPORT_PREFIX/both_tables/customers\",dst=/Root/database/folder1/subfolder2/customers \
  --item src=\"$S3_EXPORT_PREFIX/both_tables/orders\",dst=/Root/database/folder1/subfolder2/orders \
  --description \"Восстановление обеих таблиц\""

pause

comment "Получим список операций импорта:"

run "ydb -p default operation list import/s3"

pause

comment "Проверим восстановленные данные:"

run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/customers\`'"
run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/orders\`'"

pause

# ============================================
# КРИТЕРИЙ 52: Восстановление из резервной копии отдельной БД
# ============================================

header "КРИТЕРИЙ 52: Восстановление из резервной копии отдельной БД"

comment "Удалим только таблицу customers:"

run "ydb -p default sql -s 'DROP TABLE \`/Root/database/folder1/subfolder2/customers\`'"

pause

comment "Восстановим только таблицу customers из локальной резервной копии:"

run "ydb -p default tools restore -p /Root/database/folder1/subfolder2/customers -i ./backup_demo/customers"

pause

comment "Проверим восстановленные данные:"

run "ydb -p default sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/customers\`'"

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/customers`' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/orders`' 2>/dev/null
rm -rf ./backup_demo 2>/dev/null
rm -rf ./backup_demo_schema 2>/dev/null
rm -rf ./backup_demo_table_consistency 2>/dev/null
ydb -p default operation list export/s3 --format proto-json-base64 2>/dev/null | jq -r ".operations[].id" 2>/dev/null | while read line; do ydb -p default operation forget "$line" 2>/dev/null; done
ydb -p default operation list import/s3 --format proto-json-base64 2>/dev/null | jq -r ".operations[].id" 2>/dev/null | while read line; do ydb -p default operation forget "$line" 2>/dev/null; done
