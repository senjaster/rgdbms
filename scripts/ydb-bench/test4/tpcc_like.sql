UPDATE `bench/accounts` SET abalance = abalance + $delta WHERE aid = $aid;

SELECT abalance FROM `bench/accounts` WHERE aid = $aid;

UPDATE `bench/tellers` SET tbalance = tbalance + $delta WHERE tid = $tid;

UPDATE `bench/branches` SET bbalance = bbalance + $delta WHERE bid = $bid;

INSERT INTO `bench/history` (tid, bid, aid, delta, mtime)
VALUES ($tid, $bid, $aid, $delta, CurrentUtcTimestamp());
