$b_id = RandomNumber(1) % 1000000 + 1;
$a_id = RandomNumber(2) % 1000000 + 1;

select count(*) from `bench/accounts_200p` where aid=$a_id;
select count(*) from `bench/accounts_200p` where bid=$b_id;
