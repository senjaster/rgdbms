#!/bin/sh

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
rm -rf ./backup_demo

echo "=== БЛОК 1: Создание таблиц в папке /Root/database/folder1/subfolder2 ==="
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

echo "=== БЛОК 4: Создание резервной копии папки (полная выгрузка) ==="
set -x
ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo
set +x
echo "Содержимое директории backup_demo:"
ls -lR ./backup_demo
pause

echo "=== БЛОК 5: Создание резервной копии только схемы (без данных) ==="
set -x
ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo_schema --scheme-only
set +x
echo "Содержимое директории backup_demo_schema:"
ls -lR ./backup_demo_schema
pause

echo "=== БЛОК 6: Создание резервной копии с уровнем консистентности 'table' ==="
set -x
ydb -p default tools dump -p /Root/database/folder1/subfolder2 -o ./backup_demo_table_consistency --consistency-level table
set +x
pause

echo "=== БЛОК 7: Удаление таблиц для демонстрации восстановления ==="
set -x
ydb -p default sql -s 'DROP TABLE `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'DROP TABLE `/Root/database/folder1/subfolder2/orders`'
set +x
echo "Проверка, что таблицы удалены (должна быть ошибка):"
set -x
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`' || echo "Таблица customers не найдена (ожидаемо)"
set +x
pause

echo "=== БЛОК 8: Восстановление из резервной копии ==="
set -x
ydb -p default tools restore -p /Root/database/folder1/subfolder2 -i ./backup_demo
set +x
pause

echo "=== БЛОК 9: Проверка восстановленных данных ==="
set -x
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/orders`'
set +x
pause

echo "=== ОЧИСТКА: Удаление таблиц и резервных копий ==="
set -x
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/customers`'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/orders`'
rm -rf ./backup_demo
rm -rf ./backup_demo_schema
rm -rf ./backup_demo_table_consistency
set +x
echo ""
echo "=== Демонстрация завершена ==="

