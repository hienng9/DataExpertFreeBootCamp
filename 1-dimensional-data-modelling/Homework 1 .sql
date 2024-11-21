-- CREATE TYPE FILMS
create type films as( 
	film text,
	votes integer,
	rating real,
	filmid text
); 

-- CREATE TYPE QUALITY_CLASS
create type quality_class as enum('star', 'good', 'average', 'bad');
drop table actors;

--CREATE TABLE actors
create table actors ( 
	actorid text,
	actor text,
	films films[],
	quality_class quality_class,
	is_active boolean,
	current_year INTEGER,
	primary KEY(actorid, current_year)
);

-- INSERT INTO TABLE actors
-- CUUMULATIVE TABLE GENERATION QUERY
insert into actors
with years as (
	select generate_series(1970, 2023) as year
),
first_year as (
	select actorid ,actor,  min("year") as first_year
	from actor_films af2 
	group by 1, 2
),
actors_years as (
	select actorid, actor, first_year, year as current_year
	from first_year
	join years
	on first_year <= year
),
actors_agg as (
	select actorid, year, avg(rating) as avg_rating
	from actor_films af 
	group by 1, 2
),
actors_by_year as (
	select af.*, a.year, a.film, a.filmid, a.rating, a.votes--, a.avg_rating
	from actors_years af 
	left join actor_films a
	on a.actorid = af.actorid and af.current_year = a.year
),
actor_agg_films as (
	select a.actorid, actor, current_year, a.year,
	array_remove(
	array_agg(
		case when a.year is not null 
		then Row(film, votes,rating, filmid) :: films
		else null end
		) 
	over (partition by a.actorid order by coalesce(a.year, a.current_year)), null)
	as films,-- avg_rating
	array_remove(
			array_agg(
			case when a.year is not null
					then avg_rating
					else null end)
			over ( 
				partition by a.actorid 
				order by current_year--coalesce(a.year, a.current_year)
				)
			, null) as avg_rating
	from actors_by_year a
	left join actors_agg a1
	on a.actorid = a1.actorid and a.year = a1.year
)
select 
distinct
	actorid
	, actor
	, films
	,case 
		when (avg_rating[cardinality(avg_rating)])> 8 then 'star' 
		when (avg_rating[cardinality(avg_rating)]) > 7 then 'good'
		when (avg_rating[cardinality(avg_rating)]) > 6 then 'average'
		else 'bad' end :: quality_class
		as quality_class,
	case when current_year = year then true else false end as is_active
	, current_year
from actor_agg_films;

-- actors_history_scd

create table actors_history_scd (
	actorid TEXT,
	actor TEXT,
	quality_class quality_class,
	is_active BOOLEAN,
	start_date INTEGER,
	end_date INTEGER
);

--select * from actors order by actorid , current_year ;
insert into actors_history_scd
with actors_lag as(
	select 
		actorid,
		actor,
		quality_class,
		is_active,
		current_year,
		lag(quality_class, 1) over (partition by actorid order by current_year) as previous_quality_class,
		lag(is_active, 1) over (partition by actorid order by current_year) as previous_is_active
	from actors
),
change_indicators as (
	select *,
--		actorid,
--		actor,
		quality_class != previous_quality_class as is_change_QC,
		is_active != previous_is_active as is_change_active
	from actors_lag
),
streaks as (
	select actorid,
	actor,
	current_year,
	quality_class,
	is_active,
	Sum(case when is_change_qc or is_change_active then 1 else 0 end) 
	over (partition by actorid order by current_year) as streaks
	from change_indicators
)
select 
	actorid,
	actor,
	quality_class,
	is_active,
	min(current_year) as start_date,
	max(current_year) as end_date
from streaks
group by actorid, actor, quality_class, is_active, streaks;

-- 4. Backfill query for actors_history_scd

-- 4. Backfill query for actors_history_scd

with years as (
	select generate_series(1970, 2023) as years 
),
actors_years as (
	select *
	from (	
		select 
			actorid, min(start_date) as start_year 
		from actors_history_scd 
		group by actorid
		) a
	join years y
	on a.start_year <= y.years
)
select y.years, y.actorid, a.actor, a.quality_class, a.is_active--, a.start_date, a.end_date
from actors_years y
left join actors_history_scd  a
on a.actorid = y.actorid and y.years between a.start_date and a.end_date;





























