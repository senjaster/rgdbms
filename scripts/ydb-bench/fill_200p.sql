$maxaid = SELECT max(aid) FROM `bench/accounts_200p`;

REPLACE INTO `bench/accounts_200p`(aid, bid, abalance, filler)
SELECT aid+COALESCE($maxaid,0), aid+COALESCE($maxaid,0), 0, null
FROM  `bench/accounts`
WHERE aid BETWEEN 1 AND 1000000;


