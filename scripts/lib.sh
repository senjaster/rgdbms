#!/bin/sh

# ============================================
# Библиотека вспомогательных функций для демо-скриптов YDB
# ============================================

# Цвета для вывода
COLOR_HEADER="\033[0;36m"      # Cyan для заголовков и комментариев
COLOR_RUN="\033[0;33m"         # Yellow для команд
COLOR_LINK="\033[0;35m"        # Magenta для ссылок
COLOR_PAUSE="\033[0;32m"       # Green для паузы
COLOR_RESET="\033[0m"          # Сброс цвета
UNDERLINE="\033[4m"            # Подчеркивание

# Функция для вывода заголовка с линиями
# Использование: header "Текст заголовка"
header() {
    local text="$1"
    local line="========================================"
    printf "${COLOR_HEADER}%s\n%s\n%s${COLOR_RESET}\n" "$line" "$text" "$line"
}

# Функция для вывода комментария
# Использование: comment "Текст комментария"
comment() {
    printf "${COLOR_HEADER}%s${COLOR_RESET}\n" "$1"
}

# Функция для вывода и выполнения команды
# Использование: run "команда для выполнения"
run() {
    if command -v colorize >/dev/null 2>&1; then
        echo "$1" | colorize
    else
        printf "${COLOR_RUN}+ %s${COLOR_RESET}\n" "$1"
    fi
    eval "$1"
}

# Функция паузы (нажмите любую клавишу для продолжения)
# Использование: pause
pause() {
    echo ""
    printf "${COLOR_PAUSE}Нажмите Enter для продолжения...${COLOR_RESET}"
    read -r
    echo ""
}

# Функция для вывода URL в подчеркнутом magenta цвете
# Использование: link "url"
link() {
    local url="$1"
    printf "${COLOR_LINK}${UNDERLINE}%s${COLOR_RESET}\n" "$url"
}
