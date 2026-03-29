#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 1: Возможность установки СУБД в закрытом контуре
# ============================================

header "КРИТЕРИЙ 1: Возможность установки СУБД в закрытом контуре"

comment "YDB поддерживает установку в закрытом контуре без доступа в интернету"
comment "Для установки используется Ansible, нужно заранее загрузить и установить коллекцию ydb_platform.ydb"
run "ansible-galaxy collection list"
pause

comment "Дистрибутив должен быть заранее скачан на машину, с которой производится установка:"
run "ls -l ~/ydb-setup/ydbd*"
comment ""
comment "В ansible inventory нужно указать путь к заранее скачанному архиву с бинарными файлами:"
pause

less -p ydb_archive: ~/ydb-setup/3-nodes-mirror-3-dc-init/inventory/50-inventory.yaml

comment ""
comment "В ходе установки Ansible может установать на хосты ydb дополнительные пакеты. Нужно либо позаботиться чтобы"
comment "все требуемые пакеты уже были установлены, либо обеспечить наличие зеркала репозиториев в закрытом контурре."

pause
comment "Демонстрация установки YDB через Ansible playbook:"

pause

# Воспроизводим запись установки
scriptreplay -t "${SCRIPT_DIR}/criteria01_timingfile.tm" -m 2 -d 2 "${SCRIPT_DIR}/criteria01_session.log"

comment "Документация по развертыванию:"
link "https://ydb.tech/docs/ru/devops/deployment-options/ansible/initial-deployment?version=v25.2"

pause

# ============================================
# КРИТЕРИЙ 2: Поддержка автоматизированной установки СУБД
# на операционных системах, входящих в состав ЕРРПО
# ============================================

header "КРИТЕРИЙ 2: Поддержка автоматизированной установки СУБД на операционных системах входящих в состав ЕРРПО"

comment "Ansible-коллекция ydb_platform.ydb поддеживает несколько дистрибутивов Linux:"

run "ls -1 /home/user/.ansible/collections/ansible_collections/ydb_platform/ydb/roles/packages/vars/distributions/"

comment ""
comment "В ЕРРПО входят РЕД ОС, Astra Linux и SberLinux OS Server"


pause

# ============================================
# КРИТЕРИЙ 3: Поддержка автоматизированного обновления
# между минорными и мажорными версиями
# ============================================

header "КРИТЕРИЙ 3: Поддержка автоматизированного обновления между версиями"

comment "YDB поддерживает автоматизированное обновление с помощью плейбуков Ansible"
comment "Необходимо указать в inventory путь к новому дистрибутиву и запустить плейбук update_executable"
less -p ydb_archive: ~/ydb-setup/3-nodes-mirror-3-dc/inventory/50-inventory.yaml
comment ""
comment "Демонстрация процесса обновления YDB:"

pause

# Воспроизводим запись обновления
scriptreplay -t "${SCRIPT_DIR}/criteria03_timingfile.tm" -m 2 -d 2 "${SCRIPT_DIR}/criteria03_session.log"

pause

# ============================================
# ЗАВЕРШЕНИЕ
# ============================================

comment "Документация по обновлению:"
link "https://ydb.tech/docs/ru/devops/deployment-options/ansible/update-executable?version=v25.2"


