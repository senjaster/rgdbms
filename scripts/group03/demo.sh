#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

header "Графическая консоль - базовый мониторинг и выполнение запросов"
comment "КРИТЕРИЙ 10. Наличие графической консоли мониторинга и управления" 
comment ""
link "https://10.40.13.21:8765/monitoring/cluster/tenants"
pause

comment "КРИТЕРИЙ 19. Возможность выполнения запросов к СУБД непосредственно из графической консоли"
comment "КРИТЕРИЙ 20. Возможность графического представления планов выполнения запросов"

comment "Выполним запрос с помощью WebUI"
echo "
SELECT count(*) as customer_count`
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

comment "КРИТЕРИЙ 21. Возможность просмотра информации о структуре и размерах БД, объектах БД"

link "https://10.40.13.21:8765/monitoring/tenant?tenantPage=diagnostics&queryTab=history&diagnosticsTab=overview&summaryTab=schema&database=%2FRoot%2Fdatabase&queryMode=running&schema=%2FRoot%2Fdatabase%2Foorder"

pause