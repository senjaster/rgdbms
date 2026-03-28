#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/../lib.sh"

# ============================================
# Конфигурация S3
# ============================================
S3_ENDPOINT="http://10.40.13.20:9000/ydb-data"
S3_ACCESS_KEY="root"
S3_SECRET_KEY="PASSw0rd!!!"
S3_REGION="us-east-1"

# Очистка (без вывода)
ydb -p default sql -s 'DROP EXTERNAL TABLE IF EXISTS `s3/warehouse`' 2>/dev/null
ydb -p default sql -s 'DROP EXTERNAL DATA SOURCE IF EXISTS object_storage' 2>/dev/null
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_access_key_id (TYPE SECRET)' 2>/dev/null
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_secret_access_key (TYPE SECRET)' 2>/dev/null

# ============================================
# КРИТЕРИЙ 80: Возможность выгрузки данных штатными средствами из СУБД в parquet файлы
# ============================================

header "КРИТЕРИЙ 80: Возможность выгрузки данных штатными средствами из СУБД в parquet файлы"

comment "Создадим секреты для доступа к S3"
run "ydb -p default sql -s \"CREATE OBJECT s3_access_key_id (TYPE SECRET) WITH (value='$S3_ACCESS_KEY')\""
run "ydb -p default sql -s \"CREATE OBJECT s3_secret_access_key (TYPE SECRET) WITH (value='$S3_SECRET_KEY')\""

pause

comment "Создадим внешний источник данных (S3)"
run "ydb -p default sql -s \"CREATE EXTERNAL DATA SOURCE object_storage WITH (
    SOURCE_TYPE=\\\"ObjectStorage\\\",
    LOCATION=\\\"$S3_ENDPOINT\\\",
    AUTH_METHOD=\\\"AWS\\\",
    AWS_ACCESS_KEY_ID_SECRET_NAME=\\\"s3_access_key_id\\\",
    AWS_SECRET_ACCESS_KEY_SECRET_NAME=\\\"s3_secret_access_key\\\",
    AWS_REGION=\\\"$S3_REGION\\\"
)\""

pause

comment "Выгрузим данные в S3 в формате Parquet"
run "ydb -p default sql -s 'INSERT INTO object_storage.\`warehouse/\`
WITH
(
    FORMAT = \"parquet\"
)
SELECT *
FROM warehouse
'"

pause

# ============================================
# КРИТЕРИЙ 81: Возможность обращения штатными средствами СУБД к parquet файлам для выполнения аналитических запросов
# ============================================

header "КРИТЕРИЙ 81: Возможность обращения штатными средствами СУБД к parquet файлам для выполнения аналитических запросов"

comment "Ad-hoc чтение данных из произвольной папки"
run "ydb -p default sql -s 'SELECT *
FROM object_storage.\`warehouse/\`
WITH
(
  FORMAT = \"parquet\",
  SCHEMA =
  (
    W_ID Int32,
    W_YTD Double,
    W_TAX Double,
    W_NAME Utf8,
    W_STREET_1 Utf8,
    W_STREET_2 Utf8,
    W_CITY Utf8,
    W_STATE Utf8,
    W_ZIP Utf8
  )
)
LIMIT 3
'"

pause

comment "Создадим внешнюю таблицу для работы с Parquet в S3"
run "ydb -p default sql -s 'CREATE EXTERNAL TABLE \`s3/warehouse\` (
    W_ID Int32,
    W_YTD Double,
    W_TAX Double,
    W_NAME Utf8,
    W_STREET_1 Utf8,
    W_STREET_2 Utf8,
    W_CITY Utf8,
    W_STATE Utf8,
    W_ZIP Utf8
  ) WITH (
  DATA_SOURCE=\"object_storage\",
  LOCATION=\"warehouse/\",
  FORMAT=\"parquet\"
)'"

pause

comment "Прочитаем данные через внешнюю таблицу"
run "ydb -p default sql -s 'SELECT * FROM \`s3/warehouse\` LIMIT 3'"

pause

# ============================================
# КРИТЕРИЙ 82: Возможность использования в одном запросе данных, хранимых в СУБД и parquet файлах
# ============================================

header "КРИТЕРИЙ 82: Возможность использования в одном запросе данных, хранимых в СУБД и parquet файлах"

comment "Выполним JOIN между данными из S3 (Parquet) и данными из БД"
run "ydb -p default sql -s '
    SELECT count(*) 
    FROM  
      \`s3/warehouse\` as w
      INNER JOIN \`oorder\` as o
         ON w.W_ID = o.O_W_ID
'"

pause

# Очистка (без вывода)
ydb -p default sql -s 'DROP EXTERNAL TABLE IF EXISTS `s3/warehouse`' 2>/dev/null
ydb -p default sql -s 'DROP EXTERNAL DATA SOURCE IF EXISTS object_storage' 2>/dev/null
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_access_key_id (TYPE SECRET)' 2>/dev/null
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_secret_access_key (TYPE SECRET)' 2>/dev/null

mcmc alias set myminio http://10.40.13.20:9000 "$S3_ACCESS_KEY" "$S3_SECRET_KEY" &>/dev/null
mcmc rm --recursive --force myminio/ydb-data/warehouse/ &>/dev/null
