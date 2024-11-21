--drop type scd_type;
--create type scd_type as (
--	scoring_class scoring_class,
--	is_active boolean,
--	start_season integer,
--	end_season integer
--);

with last_season_scd as (
	select *
	from players_scd ps 
	where current_season = 2021 and end_season = 2021
), historical_scd as (  
	select *
	from players_scd ps 
	where current_season = 2021 and end_season < 2021
),
this_season_data as (
	select *
	from players 
	where current_season = 2022
),
unchanged_records as (
	select 
		ls.player_name,
		ls.scoring_class,
		ls.is_active,
		ls.start_season,
		ts.current_season as end_season,
		2022 as current_season
	from last_season_scd ls
	join this_season_data ts
	on ls.player_name = ts.player_name
	where ls.scoring_class = ts.scoring_class and ls.is_active = ts.is_active
),
new_records as (
select 
		ts.player_name,
		ts.scoring_class,
		ts.is_active,
		ts.current_season as start_season,
		ts.current_season as end_season,
		2022 as current_season
	from this_season_data ts
	left join last_season_scd ls
	on ls.player_name = ts.player_name
	where ls.player_name is null
),
changed_records as (  
select 
	player_name, 
	(a::scd_type).scoring_class,
	(a::scd_type).is_active,
	(a::scd_type).start_season,
	(a::scd_type).end_season,
	2022 as current_season
from (
	select 
		ls.player_name,
		unnest (Array[
		row(ls.scoring_class,
		ls.is_active,
		ls.start_season,
		ls.end_season) :: scd_type,
		row(
		ts.scoring_class,
		ts.is_active,
		ts.current_season,
		ts.current_season
		) :: scd_type
		]) as a
	from last_season_scd ls
	join this_season_data ts
	on ls.player_name = ts.player_name
	where (ls.scoring_class <> ts.scoring_class or ls.is_active <> ts.is_active)
	) abc
) 
select * from historical_scd
union all
select * from new_records
union all
select * from changed_records
union all
select * from unchanged_records
order by player_name, start_season
