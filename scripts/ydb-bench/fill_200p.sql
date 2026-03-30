$maxaid = SELECT max(aid) FROM `bench/accounts_200p`;

REPLACE INTO `bench/accounts_200p`(aid, bid, abalance, filler)
SELECT aid+$maxaid, aid+$maxaid, 0, null
FROM  `bench/accounts_200p`
WHERE aid BETWEEN 1 AND 500000;


