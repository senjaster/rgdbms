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
ydb -p default sql -s 'DROP USER IF EXISTS testuser3'
ydb -p default sql -s 'DROP GROUP IF EXISTS readers'
ydb -p default sql -s 'DROP GROUP IF EXISTS writers'
ydb -p default sql -s 'DROP GROUP IF EXISTS all_users'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`'

echo "=== БЛОК 1: Создание пользователей и таблицы ==="
set -x
ydb -p default sql -s "CREATE USER testuser PASSWORD 'PASSw0rd!!!'"
ydb -p default sql -s "CREATE USER testuser2 PASSWORD 'PASSw0rd!!!'"
ydb -p default sql -s "CREATE USER testuser3 PASSWORD 'PASSw0rd!!!'"
ydb -p default sql -s 'CREATE TABLE `/Root/database/folder1/subfolder2/test_table`(id string not null, primary key (id))'
ydb -p default sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("some_key")'
set +x
pause

echo "=== БЛОК 2: Создание групп (ролей) ==="
set -x
ydb -p default sql -s 'CREATE GROUP readers'
ydb -p default sql -s 'CREATE GROUP writers'
ydb -p default sql -s 'CREATE GROUP all_users'
set +x
pause

echo "=== БЛОК 3: Назначение прав группам ==="
set -x
ydb -p default sql -s 'GRANT SELECT ON `/Root/database/folder1/subfolder2/test_table` TO GROUP readers'
ydb -p default sql -s 'GRANT SELECT, INSERT, UPDATE ON `/Root/database/folder1/subfolder2/test_table` TO GROUP writers'
set +x
pause

echo "=== БЛОК 4: Добавление пользователей в группы ==="
set -x
ydb -p default sql -s 'ALTER GROUP readers ADD USER testuser'
ydb -p default sql -s 'ALTER GROUP writers ADD USER testuser2'
set +x
pause

echo "=== БЛОК 5: Проверка прав testuser (группа readers - только SELECT) ==="
set -x
ydb -p default --user testuser sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
echo "Попытка INSERT (должна завершиться ошибкой):"
set -x
ydb -p default --user testuser sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("reader_key")'
set +x
pause

echo "=== БЛОК 6: Проверка прав testuser2 (группа writers - SELECT, INSERT, UPDATE) ==="
set -x
ydb -p default --user testuser2 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
ydb -p default --user testuser2 sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("writer_key")'
ydb -p default --user testuser2 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 7: Удаление пользователя из группы ==="
set -x
ydb -p default sql -s 'ALTER GROUP writers DROP USER testuser2'
set +x
echo "Проверка доступа testuser2 после удаления из группы (должно завершиться ошибкой):"
set -x
ydb -p default --user testuser2 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== БЛОК 8: Добавление пользователя в несколько групп ==="
set -x
ydb -p default sql -s 'ALTER GROUP readers ADD USER testuser2'
ydb -p default sql -s 'ALTER GROUP writers ADD USER testuser2'
set +x
echo "Проверка доступа testuser2 (теперь в двух группах):"
set -x
ydb -p default --user testuser2 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
ydb -p default --user testuser2 sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("multi_group_key")'
set +x
pause

echo "=== БЛОК 9: Вложенные роли (группа в группе) ==="
echo "Создаем группу all_users, которая включает группы readers и writers:"
set -x
ydb -p default sql -s 'ALTER GROUP all_users ADD GROUP readers'
ydb -p default sql -s 'ALTER GROUP all_users ADD GROUP writers'
set +x
echo "Добавляем testuser3 в группу all_users:"
set -x
ydb -p default sql -s 'ALTER GROUP all_users ADD USER testuser3'
set +x
echo "testuser3 наследует права обеих групп (readers и writers):"
set -x
ydb -p default --user testuser3 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
ydb -p default --user testuser3 sql -s 'INSERT INTO `/Root/database/folder1/subfolder2/test_table`(id) VALUES("nested_role_key")'
ydb -p default --user testuser3 sql -s 'SELECT * FROM `/Root/database/folder1/subfolder2/test_table`'
set +x
pause

echo "=== ОЧИСТКА: Удаление всех созданных объектов ==="
set -x
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM GROUP readers'
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM GROUP writers'
ydb -p default sql -s 'DROP GROUP IF EXISTS all_users'
ydb -p default sql -s 'DROP GROUP IF EXISTS readers'
ydb -p default sql -s 'DROP GROUP IF EXISTS writers'
ydb -p default sql -s 'DROP USER IF EXISTS testuser'
ydb -p default sql -s 'DROP USER IF EXISTS testuser2'
ydb -p default sql -s 'DROP USER IF EXISTS testuser3'
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`'
set +x
echo ""
echo "=== Демонстрация завершена ==="


