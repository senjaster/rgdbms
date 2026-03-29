#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 84: Расширенное управление очередями (Advanced Queueing)
# ============================================

header "КРИТЕРИЙ 84: Расширенное управление очередями (Advanced Queueing)"

comment "YDB поддерживает работу с топиками (topics) - распределенными очередями сообщений."
comment "Топики обеспечивают надежную доставку сообщений, поддержку множественных потребителей,"
comment "партиционирование для масштабирования и различные кодеки сжатия."

pause

# Очистка (без вывода)
ydb -p default topic drop demo-topic 2>/dev/null

comment "Создадим топик с поддержкой сжатия (raw, gzip)"
run "ydb -p default topic create --supported-codecs raw,gzip demo-topic"

pause

comment "Посмотрим описание созданного топика"
run "ydb -p default scheme describe demo-topic"

pause

comment "Добавим потребителя (consumer) к топику"
run "ydb -p default topic consumer add --consumer demo-consumer demo-topic"

pause

comment "Проверим обновленное описание топика с потребителем"
run "ydb -p default scheme describe demo-topic"

pause

comment "Удалим потребителя"
run "ydb -p default topic consumer drop --consumer demo-consumer demo-topic"

pause

# Очистка (без вывода)
ydb -p default topic drop demo-topic 2>/dev/null
