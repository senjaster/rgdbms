 ydb -p default topic read \
  cdc_demo_table/cdc_demo_feed \
  --consumer=demo-consumer \
  --format=newline-delimited \
  --wait
