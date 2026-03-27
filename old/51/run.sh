#!/bin/sh

# ============================================
# Конфигурация S3
# ============================================
S3_ENDPOINT="http://10.40.13.20:9000"
S3_BUCKET="ydb-backup"
S3_ACCESS_KEY="root"
S3_SECRET_KEY="PASSw0rd!!!"
S3_EXPORT_PREFIX="ydb_export_demo"

# Функция паузы
pause() {
    echo ""
    echo "Нажмите Enter для продолжения..."
    read -r
    echo ""
}

# Очистка
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/orders`'

echo "=== БЛОК 1: Создание двух таблиц ==="
set -x
ydb -p default sql -s 'CREATE TABLE `/Root/database/folder1/subfolder2/customers`(
    customer_id Uint64 NOT NULL,
    name Utf8,
    email Utf8,
    PRIMARY KEY (customer_id)
)'

ydb -p default sql -s 'CREATE TABLE `/Root/database/folder1/subfolder2/orders`(
    order_id Uint64 NOT NULL,
    customer_id Uint64,
    amount Double,
    order_date Date,
    PRIMARY KEY (order_id)
)'
set +x
pause

echo "=== БЛОК 2: Заполнение таблиц данными ==="
set -x
ydb -p default sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/customers` (customer_id, name, email) VALUES
    (1, "Иван Иванов", "ivan@example.com"),
    (2, "Мария Петрова", "maria@example.com"),
    (3, "Алексей Сидоров", "alexey@example.com")'

ydb -p default sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/orders` (order_id, customer_id, amount, order_date) VALUES
    (101, 1, 1500.50, Date("2024-01-15")),
    (102, 1, 2300.00, Date("2024-02-20")),
    (103, 2, 750.25, Date("2024-01-18")),
    (104, 3, 3200.00, Date("2024-03-10")),
    (105, 2, 1100.75, Date("2024-03-15"))'
set +x
pause

echo "=== БЛОК 3: Проверка данных в таблицах ==="
set -x
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/orders`'
set +x
pause

echo "=== БЛОК 4: Выгрузка обеих таблиц ==="
echo "Export Path: $S3_EXPORT_PREFIX/both_tables"
set -x
ydb -p default export s3 \
  --s3-endpoint "$S3_ENDPOINT" \
  --bucket "$S3_BUCKET" \
  --access-key "$S3_ACCESS_KEY" \
  --secret-key "$S3_SECRET_KEY" \
  --item src=/Root/database/folder1/subfolder2/customers,dst="$S3_EXPORT_PREFIX/both_tables/customers" \
  --item src=/Root/database/folder1/subfolder2/orders,dst="$S3_EXPORT_PREFIX/both_tables/orders" \
  --description "Выгрузка обеих таблиц"
set +x
pause

echo "=== БЛОК 5: Получение списка операций экспорта ==="
set -x
ydb -p default operation list export/s3
set +x
pause

echo "=== БЛОК 6: Удаление таблиц для демонстрации восстановления ==="
set -x
ydb -p default sql -s 'DROP TABLE `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'DROP TABLE `/Root/database/folder1/subfolder2/orders`'
set +x
echo "Проверка, что таблицы удалены (должна быть ошибка):"
set -x
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`' || echo "Таблица customers не найдена (ожидаемо)"
set +x
pause

echo "=== БЛОК 7: Восстановление обеих таблиц из S3 ==="
echo "Import Path: $S3_EXPORT_PREFIX/both_tables"
set -x
ydb -p default import s3 \
  --s3-endpoint "$S3_ENDPOINT" \
  --bucket "$S3_BUCKET" \
  --access-key "$S3_ACCESS_KEY" \
  --secret-key "$S3_SECRET_KEY" \
  --item src="$S3_EXPORT_PREFIX/both_tables/customers",dst=/Root/database/folder1/subfolder2/customers \
  --item src="$S3_EXPORT_PREFIX/both_tables/orders",dst=/Root/database/folder1/subfolder2/orders \
  --description "Восстановление обеих таблиц"
set +x
pause

echo "=== БЛОК 8: Получение списка операций импорта ==="
set -x
ydb -p default operation list import/s3
set +x
pause

echo "=== БЛОК 9: Проверка восстановленных данных ==="
set -x
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/orders`'
set +x
pause

echo "=== ОЧИСТКА: Удаление таблиц ==="
set -x
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/orders`'
set +x
echo ""
echo "=== Демонстрация завершена ==="
ydb -p default operation list export/s3 --format proto-json-base64 | jq -r ".operations[].id" | while read line; do ydb -p default operation forget "$line"; done
ydb -p default operation list import/s3 --format proto-json-base64 | jq -r ".operations[].id" | while read line; do ydb -p default operation forget "$line"; done


