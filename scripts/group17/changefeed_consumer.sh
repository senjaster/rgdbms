#!/bin/sh

# Скрипт для чтения changefeed из таблицы через Kafka API

~/kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server yandex-ydb-1.ydb-cluster.com:31005 \
    --topic /Root/database/cdc_demo_table/cdc_feed \
    --group demo-consumer \
    --from-beginning \
    --consumer-property check.crcs=false \
    --consumer-property partition.assignment.strategy=org.apache.kafka.clients.consumer.RoundRobinAssignor
