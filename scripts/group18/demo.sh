#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 7: Возможность квотирования или приоритезации ресурсов (cpu, ram, disk)
# ============================================

header "КРИТЕРИЙ 7: Возможность квотирования или приоритезации ресурсов (cpu, ram, disk)"

comment "В YDB есть компонент под названием Workload Manager который позволяет ограничивать потребление ресурсов"
comment "различными группами пользователей."
comment ""
link "https://ydb.tech/docs/ru/dev/resource-consumption-management?version=v25.2"
comment ""
comment "Данный функционал находится в стадии Preview."
pause
