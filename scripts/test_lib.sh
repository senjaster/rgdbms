#!/bin/sh

# Тестовый скрипт для проверки функций из lib.sh

# Загружаем библиотеку
. ./lib.sh

# Тест 1: header
header "Тест функции header"

# Тест 2: comment
comment "Это тестовый комментарий"
comment "Комментарии используют тот же цвет, что и заголовки"

# Тест 3: run
header "Тест функции run"
comment "Выполняем простую команду:"
run "echo 'Привет из функции run!'"
run "date"
run "ls -la lib.sh"

# Тест 4: link
header "Тест функции link"
comment "Ссылки с OSC 8 (работают в терминалах с поддержкой гиперссылок):"
link "Документация YDB" "https://ydb.tech/docs"
link "GitHub YDB" "https://github.com/ydb-platform/ydb"

# Тест 5: pause
header "Тест функции pause"
comment "Сейчас будет вызвана функция паузы"
pause

# Финальное сообщение
header "Все тесты завершены"
comment "Библиотека lib.sh работает корректно!"
