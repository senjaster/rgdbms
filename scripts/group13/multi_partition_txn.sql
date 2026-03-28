-- Многоузловая транзакция: изменяем строки в разных партициях
UPDATE `{table_folder}/test_distributed_txn`
SET value = value + 1
WHERE id = 10;

UPDATE `{table_folder}/test_distributed_txn`
SET value = value - 1
WHERE id = 30;
