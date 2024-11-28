-- 1. deduplicate query
select distinct *
from game_details gd 

--2. DDL table user_devices_cumulated
--drop table user_devices_cumulated;
create table user_devices_cumulated (
	user_id numeric,
	browser_type text,
	device_activity_datelist date[],
	date date,
	primary key (user_id, browser_type, date)
);

--3. cumulative query
insert into user_devices_cumulated
with yesterday_data as (
	select *
	from user_devices_cumulated e
	where date = '2023-01-09'
), 
today_data as (
	select e.user_id, browser_type,  date(event_time) as event_date
	from events e 
	join devices d 
	on e.device_id  = d.device_id 
	where user_id is not null and date(event_time) = '2023-01-10'
	group by e.user_id, browser_type, date(event_time)
)
select 
	coalesce (t.user_id, y.user_id) as user_id,
	coalesce (t.browser_type, y.browser_type) as brower_type,
	case 
		when event_date is null then device_activity_datelist
		when event_date is not null then device_activity_datelist || event_date
	end as device_activity_datelist,
	coalesce(event_date, y.date + 1) as date
from yesterday_data y
full outer join today_data t
on y.user_id = t.user_id and y.browser_type = t.browser_type;

--4. datelist_int generation query

