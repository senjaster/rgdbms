#!/bin/sh

# Функция паузы
pause() {
    echo ""
    echo "Нажмите Enter для продолжения..."
    read -r
    echo ""
}

ydb -p default sql -s 'DROP USER IF EXISTS testuser'
ydb -p default sql -s 'DROP USER IF EXISTS testuser2'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`'

echo "=== БЛОК 1: Создание пользователя и таблицы, вставка данных ==="
set -x
ydb -p default sql -s "CREATE USER testuser PASSWORD 'PASSw0rd!!!'"
ydb -p default sql -s 'CREATE TABLE `/Root/database/folder1/subfolder2/test_table`(id string not null, primary key (id))'
ydb -p default sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("some_key")'
set +x
pause

echo "=== БЛОК 2: Проверка доступа без прав (должно завершиться ошибкой) ==="
set -x
ydb -p default --user testuser sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 3: Выдача прав SELECT и проверка доступа (должно выполниться успешно) ==="
set -x
ydb -p default sql -s 'GRANT SELECT ON `/Root/database/folder1/subfolder2/test_table` to testuser'
ydb -p default --user testuser sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 4: Отзыв прав SELECT и проверка доступа (должно завершиться ошибкой) ==="
set -x
ydb -p default sql -s 'REVOKE SELECT ON `/Root/database/folder1/subfolder2/test_table` FROM testuser'
ydb -p default --user testuser sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 5: Выдача прав на папку с опцией GRANT OPTION ==="
set -x
ydb -p default sql -s 'GRANT SELECT, INSERT ON `/Root/database/folder1` to testuser WITH GRANT OPTION'
ydb -p default --user testuser sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 6: Создание второго пользователя и делегирование прав ==="
(set +x; echo ---------------------------------------------------------------------------------------------------------------)
set -x
ydb -p default sql -s "CREATE USER testuser2 PASSWORD 'PASSw0rd!!!'"
ydb -p default --user testuser sql -s 'GRANT SELECT, INSERT ON `/Root/database/folder1` to testuser2'
ydb -p default --user testuser2 sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("other_key")'
ydb -p default --user testuser2 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1` FROM testuser'
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1` FROM testuser2'
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM testuser'
ydb -p default sql -s 'DROP USER IF EXISTS testuser'
ydb -p default sql -s 'DROP USER IF EXISTS testuser2'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`'
echo ""
echo "=== Демонстрация завершена ==="

