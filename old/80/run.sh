#!/bin/sh

# ============================================
# Конфигурация S3
# ============================================
S3_ENDPOINT="http://10.40.13.20:9000/ydb-data"
S3_ACCESS_KEY="root"
S3_SECRET_KEY="PASSw0rd!!!"
S3_REGION="us-east-1"

# Функция паузы
pause() {
    echo ""
    echo "Нажмите Enter для продолжения..."
    read -r
    echo ""
}

# Очистка
ydb -p default sql -s 'DROP EXTERNAL TABLE IF EXISTS `s3/warehouse`'
ydb -p default sql -s 'DROP EXTERNAL DATA SOURCE IF EXISTS object_storage'
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_access_key_id (TYPE SECRET)'
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_secret_access_key (TYPE SECRET)'

echo "=== ПОДГОТОВКА: Создание секретов для доступа к S3 ==="
set -x
ydb -p default sql -s "CREATE OBJECT s3_access_key_id (TYPE SECRET) WITH (value='$S3_ACCESS_KEY')"
ydb -p default sql -s "CREATE OBJECT s3_secret_access_key (TYPE SECRET) WITH (value='$S3_SECRET_KEY')"
set +x
pause

echo "=== ПОДГОТОВКА: Создание внешнего источника данных (S3) ==="
set -x
ydb -p default sql -s "CREATE EXTERNAL DATA SOURCE object_storage WITH (
    SOURCE_TYPE=\"ObjectStorage\",
    LOCATION=\"$S3_ENDPOINT\",
    AUTH_METHOD=\"AWS\",
    AWS_ACCESS_KEY_ID_SECRET_NAME=\"s3_access_key_id\",
    AWS_SECRET_ACCESS_KEY_SECRET_NAME=\"s3_secret_access_key\",
    AWS_REGION=\"$S3_REGION\"
)"
set +x
pause

echo "=== КРИТЕРИЙ 80: Выгрузка данных в S3 в формате Parquet ==="
set -x
ydb -p default sql -s 'INSERT INTO object_storage.`warehouse/`
WITH
(
    FORMAT = "parquet"
)
SELECT *
FROM warehouse
'
set +x
pause

echo "=== КРИТЕРИЙ 81: Чтение данных из S3 в формате Parquet ==="
echo "=== Ad-hoc чтение данных из произвольной папки ==="
set -x
ydb -p default sql -s 'SELECT *
FROM object_storage.`warehouse/`
WITH
(
  FORMAT = "parquet",
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
'
set +x
pause

echo "=== Создание внешней таблицы для работы с Parquet в S3 ==="
set -x
ydb -p default sql -s 'CREATE EXTERNAL TABLE `s3/warehouse` (
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
  DATA_SOURCE="object_storage",
  LOCATION="warehouse/",
  FORMAT="parquet"
)'
set +x
pause

echo "=== Чтение данных через внешнюю таблицу ==="
set -x
ydb -p default sql -s 'SELECT * FROM `s3/warehouse` LIMIT 3'
set +x
pause

echo "=== КРИТЕРИЙ 82: Использование данных из БД и Parquet в одном запросе ==="
set -x
ydb -p default sql -s '
    SELECT count(*) 
    FROM  
      `s3/warehouse` as w
      INNER JOIN `oorder` as o
         ON w.W_ID = o.O_W_ID
'
set +x
pause

ydb -p default sql -s 'DROP EXTERNAL TABLE IF EXISTS `s3/warehouse`'
ydb -p default sql -s 'DROP EXTERNAL DATA SOURCE IF EXISTS object_storage'
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_access_key_id (TYPE SECRET)'
ydb -p default sql -s 'DROP OBJECT IF EXISTS s3_secret_access_key (TYPE SECRET)'

mcmc alias set myminio http://10.40.13.20:9000 "$S3_ACCESS_KEY" "$S3_SECRET_KEY" &>/dev/null
mcmc rm --recursive --force myminio/ydb-data/warehouse/ &>/dev/null
set +x
echo ""
echo "=== Демонстрация завершена ==="


