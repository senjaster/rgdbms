~/kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server yandex-ydb-1.ydb-cluster.com:31005 \
    --topic demo-topic  \
    --group demo-consumer \
    --from-beginning \
    --consumer-property check.crcs=false \
    --consumer-property partition.assignment.strategy=org.apache.kafka.clients.consumer.RoundRobinAssignor