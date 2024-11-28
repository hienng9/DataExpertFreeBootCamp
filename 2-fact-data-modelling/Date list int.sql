--insert into users_cumulated
--with yesterday as (
--	select *
--	from users_cumulated
--	where date = '2023-01-30'
--), today as (
--	select distinct cast(user_id as text) as user_id, date(cast(event_time as timestamp)) as date_active
--	from events
--	where date(cast(event_time as timestamp)) = '2023-01-31'
--	and user_id is not null
--)
--select coalesce (t.user_id, y.user_id) as user_id,
--	case when date_active is not null then dates_active || date_active
--		when date_active is null then dates_active end as dates_active,
--	coalesce (t.date_active, y.date + interval '1 day') as date
--from yesterday y
--full outer join today t 
--on y.user_id = t.user_id;


--create table users_cumulated (
--	user_id text,
--	dates_active DATE[], -- list of dates in the past where the user was active
--	date DATE, -- current date for user
--	primary key (user_id, date)
--);

--drop table users_cumulated;

--select * from events where user_id  = 1937370958855380000


with users as (
	select * 
	from users_cumulated 
	where date = '2023-01-31'--where user_id = '12439031879943100000';
),
	series as (
	select generate_series('2023-01-01', '2023-01-31', interval '1 day')  as series_dates
	),
placeholder_int as (
	select user_id, case 
		when 
		u.dates_active @> array[date(s.series_dates)]
		then cast(POW(2, 32 - (date - Date(series_dates))) as bigint)
		else 0
		end 
		as placeholder_int
	from users u 
	cross join series s
--	where user_id = '1937370958855380000'
)
select user_id,  
cast(cast(sum(placeholder_int) as bigint) as bit(32)) ,
bit_count(cast(cast(sum(placeholder_int) as bigint) as bit(32))) > 0  as is_monthly_active,
bit_count(cast('11111110000000000000000000000000' as bit(32)) & cast(cast(sum(placeholder_int) as bigint) as bit(32))) > 0 as is_dim_weekly_active
from placeholder_int
group by user_id




