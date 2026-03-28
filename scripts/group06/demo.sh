#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

header "КРИТЕРИЙ 24: Возможность использования корпоративного TLS/SSL сертификата для компонентов решения"

comment "YDB использует TLS сертификаты для шифрования траффика API между клиентом и сервером (протокол GRPCS),"
comment "и при использовании веб-интерфейса (HTTPS). Кроме того, можно включить шифрование траффика между узлами"
comment "крастера, но это негативно сказывается на производительности."
comment ""
comment "Сервер YDB не умеет самостоятельно генерировать сертификаты, их нужно обязательно сгенерировать и подписать"
comment "в каком-то внешнем УЦ."
pause

less -p node.crt ~/ydb-setup/3-nodes-mirror-3-dc/files/config.yaml
ssh yandex-ydb-1 sudo cat /opt/ydb/certs/node.crt | less

comment "Для подключения нужно обязательно указать корневой сертификат, которым подписаны сертификаты узлов"
comment "Обычная команда подключения:"
comment "ydb --endpoint grpcs://entrypoint.ydb-cluster.com:2135 -d /Root/database --user root --ca-file ~/ca.crt"
comment "Попробуем подключиться без сертификата:"
run "ydb --endpoint grpcs://entrypoint.ydb-cluster.com:2135 -d /Root/database --user petrov@ldap"

pause

header "КРИТЕРИЙ 35: Наличие инструментов прозрачного шифрования данных на уровне хранения"

comment "YDB может прозрачно шифровать данные при записи на диск."
comment "Используется алгоритм ChaCha8."
comment ""

link  "https://ydb.tech/docs/ru/security/encryption/data-at-rest?version=v25.2"
pause
