#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 36: Поддержка дискреционной (DAC) модели управления доступом
# ============================================

header "КРИТЕРИЙ 36: Поддержка дискреционной (DAC) модели управления доступом"

comment "YDB поддерживает обычную модель разрешений, выдаваемых пользователям на объекты в БД"
pause

# Очистка
ydb -p default sql -s 'DROP USER IF EXISTS testuser' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser2' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`' 2>/dev/null

comment "Создадим пользователя и таблицу, вставим туда данные:"

run "ydb -p default sql -s \"CREATE USER testuser PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default sql -s 'CREATE TABLE \`/Root/database/folder1/subfolder2/test_table\`(id string not null, primary key (id))'"

run "ydb -p default sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"some_key\")'"

pause

comment "Проверим доступ без прав (должно завершиться ошибкой):"

run "ydb -p default --user testuser sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`' || true"

pause

comment "Разрешим выполнять SELECT и проверим доступ еще раз:"

run "ydb -p default sql -s 'GRANT SELECT ON \`/Root/database/folder1/subfolder2/test_table\` to testuser'"

run "ydb -p default --user testuser sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

pause

comment "Отываем SELECT - опять должно завершиться ошибкой:"

run "ydb -p default sql -s 'REVOKE SELECT ON \`/Root/database/folder1/subfolder2/test_table\` FROM testuser'"

run "ydb -p default --user testuser sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`' || true"

pause

################################################################################################
header "Выдача прав на папку"

comment "YDB позволяет выдать права на папку - все содежимое унаследует права:"

run "ydb -p default sql -s 'GRANT SELECT, INSERT ON \`/Root/database/folder1\` to testuser'"

run "ydb -p default --user testuser sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

pause

comment "Отзываем права на папку:"

run "ydb -p default sql -s 'REVOKE ALL ON \`/Root/database/folder1\` FROM testuser'"

pause

################################################################################################
header "WITH GRANT OPTION"

comment "Выдадим права с опцией WITH GRANT OPTION:"

run "ydb -p default sql -s 'GRANT SELECT, INSERT ON \`/Root/database/folder1\` to testuser WITH GRANT OPTION'"

pause

comment "Создадим второго пользователя и делегируем ему права:"

run "ydb -p default sql -s \"CREATE USER testuser2 PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default --user testuser sql -s 'GRANT SELECT, INSERT ON \`/Root/database/folder1\` to testuser2'"

run "ydb -p default --user testuser2 sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"other_key\")'"

run "ydb -p default --user testuser2 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

pause

# Очистка
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1` FROM testuser' 2>/dev/null
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1` FROM testuser2' 2>/dev/null
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM testuser' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser2' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`' 2>/dev/null

# ============================================
# КРИТЕРИЙ 37: Поддержка ролевой (RBAC) модели управления доступом
# ============================================

header "КРИТЕРИЙ 37: Поддержка ролевой (RBAC) модели управления доступом"

comment "YDB позволяет создавать группы и допбавлять в них пользователей."
comment "Пользователи получают все права, назначеные группам, в которые они входят"
pause

# Очистка
ydb -p default sql -s 'DROP USER IF EXISTS testuser' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser2' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser3' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS readers' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS writers' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS allusers' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`' 2>/dev/null

comment "Создадим пользователей и таблицу:"

run "ydb -p default sql -s \"CREATE USER testuser PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default sql -s \"CREATE USER testuser2 PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default sql -s \"CREATE USER testuser3 PASSWORD 'PASSw0rd!!!'\""

run "ydb -p default sql -s 'CREATE TABLE \`/Root/database/folder1/subfolder2/test_table\`(id string not null, primary key (id))'"

run "ydb -p default sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"some_key\")'"

pause

comment "Создадим группы (роли):"

run "ydb -p default sql -s 'CREATE GROUP readers'"

run "ydb -p default sql -s 'CREATE GROUP writers'"

run "ydb -p default sql -s 'CREATE GROUP allusers'"

pause

comment "Назначим права группам:"

run "ydb -p default sql -s 'GRANT SELECT ON \`/Root/database/folder1/subfolder2/test_table\` TO readers'"

run "ydb -p default sql -s 'GRANT SELECT, INSERT ON \`/Root/database/folder1/subfolder2/test_table\` TO writers'"

pause

comment "Добавим пользователей в группы:"

run "ydb -p default sql -s 'ALTER GROUP readers ADD USER testuser'"

run "ydb -p default sql -s 'ALTER GROUP writers ADD USER testuser2'"

pause

comment "Проверим права testuser (группа readers - только SELECT):"

run "ydb -p default --user testuser sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

comment "Попытка INSERT (должна завершиться ошибкой):"

run "ydb -p default --user testuser sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"reader_key\")' || true"

pause

comment "Проверим права testuser2 (группа writers - SELECT, INSERT, UPDATE):"

run "ydb -p default --user testuser2 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

run "ydb -p default --user testuser2 sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"writer_key\")'"

run "ydb -p default --user testuser2 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

pause

comment "Удалим пользователя из группы:"

run "ydb -p default sql -s 'ALTER GROUP writers DROP USER testuser2'"

comment "Проверим доступ testuser2 после удаления из группы (должно завершиться ошибкой):"

run "ydb -p default --user testuser2 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`' || true"

pause

comment "Добавим пользователя в несколько групп:"

run "ydb -p default sql -s 'ALTER GROUP readers ADD USER testuser2'"

run "ydb -p default sql -s 'ALTER GROUP writers ADD USER testuser2'"

comment "Проверим доступ testuser2 (теперь в двух группах):"

run "ydb -p default --user testuser2 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

run "ydb -p default --user testuser2 sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"multi_group_key\")'"

pause

comment "Вложенные роли (группа в группе):"
comment "Создаем группу allusers, которая включает группы readers и writers:"

run "ydb -p default sql -s 'ALTER GROUP allusers ADD readers'"

run "ydb -p default sql -s 'ALTER GROUP allusers ADD writers'"

comment "Добавляем testuser3 в группу allusers:"

run "ydb -p default sql -s 'ALTER GROUP allusers ADD USER testuser3'"

comment "testuser3 наследует права обеих групп (readers и writers):"

run "ydb -p default --user testuser3 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

run "ydb -p default --user testuser3 sql -s 'INSERT INTO \`/Root/database/folder1/subfolder2/test_table\`(id) VALUES(\"nested_role_key\")'"

run "ydb -p default --user testuser3 sql -s 'SELECT * FROM \`/Root/database/folder1/subfolder2/test_table\`'"

pause

comment "Документация по управлению доступом:"
comment ""

link "https://ydb.tech/docs/ru/security/access-management?version=v25.2"

comment ""

pause

# Очистка
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM readers' 2>/dev/null
ydb -p default sql -s 'REVOKE ALL ON `/Root/database/folder1/subfolder2/test_table` FROM writers' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS allusers' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS readers' 2>/dev/null
ydb -p default sql -s 'DROP GROUP IF EXISTS writers' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser2' 2>/dev/null
ydb -p default sql -s 'DROP USER IF EXISTS testuser3' 2>/dev/null
ydb -p default sql -s 'DROP TABLE IF EXISTS `/Root/database/folder1/subfolder2/test_table`' 2>/dev/null
