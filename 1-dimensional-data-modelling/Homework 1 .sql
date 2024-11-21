-- CREATE TYPE FILMS
create type films as( 
	film text,
	votes integer,
	rating real,
	filmid text
); 

-- CREATE TYPE QUALITY_CLASS
create type quality_class as enum('star', 'good', 'average', 'bad');
--drop table actors;

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
insert into actors
with years as (
	select generate_series(1970, 2023) as year
),
first_year as (
	select actorid , min("year") as first_year
	from actor_films af2 
	group by actorid
),
actors_years as (
	select actorid, first_year, year as current_year
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
	select af.*, a.actor, a.year, a.film, a.filmid, a.rating, a.votes--, a.avg_rating
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
	current_year = year as is_active
	, current_year
from actor_agg_films;

select * from actors order by actorid , current_year ;





