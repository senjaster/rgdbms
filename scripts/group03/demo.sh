#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# КРИТЕРИЙ 10: Наличие графической консоли мониторинга и управления
# ============================================

header "КРИТЕРИЙ 10: Наличие графической консоли мониторинга и управления"

comment "YDB предоставляет графическую консоль (WebUI) для мониторинга и управления кластером"
link "https://10.40.13.21:8765/monitoring/cluster/tenants"

pause

# ============================================
# КРИТЕРИЙ 19: Возможность выполнения запросов к СУБД непосредственно из графической консоли
# ============================================

header "КРИТЕРИЙ 19: Возможность выполнения запросов к СУБД непосредственно из графической консоли
КРИТЕРИЙ 20: Возможность графического представления планов выполнения запросов"

comment "В графической консоли можно выполнять SQL-запросы напрямую"
comment "Там же можно просмотреть план выполнения запроса в графическом виде"
comment ""
comment "Выполним запрос с помощью WebUI:"
echo "
SELECT count(*) as customer_count
FROM
    warehouse AS w
    INNER JOIN district AS d
        ON w.W_ID = d.D_W_ID
    LEFT OUTER JOIN customer AS c
        ON w.W_ID = c.C_W_ID
        AND d.D_ID = c.C_D_ID
WHERE
    w.W_ID = 100
    AND c.C_LAST LIKE 'B%'
"

link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=query&diagnosticsTab=topQueries&database=%2FRoot%2Fdatabase&queryMode=running&schema=%2FRoot%2Fdatabase"

pause

# ============================================
# КРИТЕРИЙ 21: Возможность просмотра информации о структуре и размерах БД, объектах БД
# ============================================

header "КРИТЕРИЙ 21: Возможность просмотра информации о структуре и размерах БД, объектах БД"

comment "В графической консоли доступна информация о структуре таблиц, их размерах и других объектах БД"
link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&queryTab=history&diagnosticsTab=overview&summaryTab=schema&database=%2FRoot%2Fdatabase&queryMode=running&schema=%2FRoot%2Fdatabase%2Foorder"

pause