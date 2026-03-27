#!/bin/sh

# Тестовый скрипт для проверки функций из lib.sh

# Загружаем библиотеку
. ./lib.sh

# Тест 1: header
header "Тест функции header"
comment "Это тестовый комментарий"
comment "Комментарии используют тот же цвет, что и заголовки"

run "echo 'Привет из функции run!'"
run "date"
run "ls -la lib.sh"

# Тест 4: link
link "https://ydb.tech/docs"
link "https://github.com/ydb-platform/ydb"

# Тест 5: pause
pause
