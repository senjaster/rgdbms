#!/bin/sh

# Загружаем библиотеку вспомогательных функций
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

header "КРИТЕРИЙ 4: Инструментарий для анализа производительности"

comment "YDB предоставляет следующие инструменты:"
comment "1. Системные вью в схеме .sys"
link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&diagnosticsTab=schema&database=%2FRoot%2Fdatabase&schema=%2FRoot%2Fdatabase%2F.sys%2Ftop_partitions_one_hour"

comment "2. Отчеты, использующие данные из схемы .sys"
link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&queryTab=history&diagnosticsTab=topQueries&database=%2FRoot%2Fdatabase&schema=%2FRoot%2Fdatabase&queryMode=top"

comment "3. Счетчики производительности"
link "https://10.40.13.21:8765/counters"

pause


# ============================================
# КРИТЕРИЙ 15: Наличие агента для сбора информации
# ============================================

header "КРИТЕРИЙ 15: Наличие агента для сбора информации о сервере СУБД"

comment "YDB предоставляет метрики в формате Prometheus:"
link "https://10.40.13.21:8765/counters/counters%3Dgrpc/prometheus"

comment "В официальную документацию включена инструкция по настройке мониторринга с помощью Prometheus"
link "https://ydb.tech/docs/ru/devops/observability/monitoring?version=v25.2"

comment "Вот пример настроенного инстанса prometheus"
link "http://localhost:9090/targets?pool=ydb%2Fcompile"
comment "Документация:"

pause


# ============================================
# КРИТЕРИЙ 12: Наличие преднастроенных метрик
# ============================================

header "КРИТЕРИЙ 12: Наличие преднастроенных метрик в графической консоли"

comment "Дашборд, встроеный в WebUI позволяет получить общее представление о текущем состоянии кластера"
link "https://10.40.13.21:8765/monitoring/cluster/tenants"

comment "Мы предоставляем готовые дашборды Grafana"
comment "для мониторинга состояния и производительности СУБД."
link "https://ydb.tech/docs/ru/reference/observability/metrics/grafana-dashboards?version=v25.2"
link "http://localhost:3000/dashboards"
pause

# ============================================
# КРИТЕРИЙ 13: Возможность добавления собственных метрик
# ============================================

header "КРИТЕРИЙ 13: Возможность добавления собственных метрик"

comment "Создать метрику полностью с нуля невозможно. Однако объем экспортируемой в виде счетчиков информации очень"
comment "велик. В стандартных дашбордах выводится только наиболее высокоуровневые и часто используемые метрики."
comment "Поэтому существует возможность создания доолнительных дашбордов на основе существующих метрик."

link "http://localhost:3000/explore?schemaVersion=1&panes=%7B%22txj%22%3A%7B%22datasource%22%3A%22bfgi0luvhcx6ob%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22A%22%2C%22expr%22%3A%22%22%2C%22range%22%3Atrue%2C%22instant%22%3Atrue%2C%22datasource%22%3A%7B%22type%22%3A%22prometheus%22%2C%22uid%22%3A%22bfgi0luvhcx6ob%22%7D%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-1h%22%2C%22to%22%3A%22now%22%7D%2C%22compact%22%3Afalse%7D%7D&orgId=1"

pause

# ============================================
# КРИТЕРИЙ 14: Просмотр исторических данных
# ============================================

header "КРИТЕРИЙ 14: Просмотр исторических данных по объектам мониторинга"

comment "Исторические данные доступны при использовании внешней системы сбора метрик производительности"

link "http://localhost:3000/d/ro4f4sx/db-status?orgId=1&from=now-6h&to=now&timezone=browser&var-database=%2FRoot%2Fdatabase&var-ds=bfgi0luvhcx6ob&viewPanel=panel-67"

pause