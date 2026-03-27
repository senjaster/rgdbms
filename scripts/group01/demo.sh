#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 1: Возможность установки СУБД в закрытом контуре
# ============================================

header "КРИТЕРИЙ 1: Возможность установки СУБД в закрытом контуре"

comment "YDB поддерживает установку в закрытом контуре без доступа к интернету."
comment "Дистрибутив должен быть заранее скачан на машину, с которой производится установка"
comment "Демонстрация установки YDB через Ansible playbook:"

pause

# Воспроизводим запись установки
scriptreplay -t "${SCRIPT_DIR}/criteria01_timingfile.tm" -m 2 -d 2 "${SCRIPT_DIR}/criteria01_session.log"

pause

# ============================================
# КРИТЕРИЙ 2: Поддержка автоматизированной установки СУБД
# на операционных системах, входящих в состав ЕРРПО
# ============================================

header "КРИТЕРИЙ 2: Поддержка автоматизированной установки СУБД"

comment "YDB предоставляет Ansible-коллекцию для автоматизированной установки."
comment "Поддерживаемые ОС: РЕДОС, ALT Linux, Astra Linux, SberLinux OS Server и др."
comment ""
comment "Список поддерживаемых дистрибутивов в Ansible-роли YDB:"

run "ls -1 /home/user/.ansible/collections/ansible_collections/ydb_platform/ydb/roles/packages/vars/distributions/"

pause

# ============================================
# КРИТЕРИЙ 3: Поддержка автоматизированного обновления
# между минорными и мажорными версиями
# ============================================

header "КРИТЕРИЙ 3: Поддержка автоматизированного обновления между версиями"

comment "YDB поддерживает автоматизированное обновление"
comment "с помощью плейбуков Ansible"
comment ""
comment "Демонстрация процесса обновления YDB:"

pause

# Воспроизводим запись обновления
scriptreplay -t "${SCRIPT_DIR}/criteria03_timingfile.tm" -m 2 -d 2 "${SCRIPT_DIR}/criteria03_session.log"

pause

# ============================================
# ЗАВЕРШЕНИЕ
# ============================================
comment "Документация по развертыванию:"
link "https://ydb.tech/docs/ru/devops/deployment-options/ansible/initial-deployment?version=v25.2"

comment "Документация по обновлению:"
link "https://ydb.tech/docs/ru/devops/deployment-options/ansible/update-executable?version=v25.2"


