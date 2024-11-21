create type vertex_type as enum('player', 'team', 'game');

create table vertices (
	identifier text,
	type vertex_type,
	properties json,
	primary key (identifier, type)
);

drop type edge_type;
create type edge_type as enum('plays_against', 'shares_team', 'plays_in', 'plays_on');

create table edges (
	subject_identifier text,
	subject_type vertex_type,
	object_identifier text,
	object_type vertex_type,
	edge_type edge_type,
	properties json,
	primary key (
		subject_identifier,
		subject_type ,
		object_identifier ,
		object_type ,
		edge_type 
		)
);
	
insert into vertices
select 
 game_id as identifier,
 'game' :: vertex_type as type,
 json_build_object(
 	'pts_home', pts_home,
 	'pts_away', pts_away,
 	'winning_team', case when home_team_wins = 1 then home_team_id else visitor_team_id end ) as properties
from  games g ;

insert into vertices
with players_agg as (
select 
	player_id as identifier,
	max(player_name) as player_name,
	count(1) as number_of_games,
	sum(pts) as total_points,
	array_agg(distinct team_id) as teams 
from game_details gd 
group by player_id )
select identifier,
'player':: vertex_type as type,
json_build_object(
	'player_name', player_name,
	'number_of_games', number_of_games,
	'total_points', total_points,
	'teams', teams
) as properties
from players_agg;


insert into vertices
select 
	 team_id  as identifier,
	'team' :: vertex_type as type
	,json_build_object(
	'abbreviation', abbreviation ,
	'nickname', nickname ,
	'city', city,
	'arena', arena ,
	'year_founded', yearfounded
		) as properties
from (select distinct * from teams) t 


-- PLAYS IN EDGE TYPE: PLAYER PLAYS IN TEAM

--create table edges (
--	subject_identifier text,
--	subject_type vertex_type,
--	object_identifier text,
--	object_type vertex_type,
--	edge_type edge_type,
--	properties json,
--	primary key (
--		subject_identifier,
--		subject_type ,
--		object_identifier ,
--		object_type ,
--		edge_type 
--		)
--);
insert into edges
with players_play_in_teams as (
	select distinct player_id , game_id, start_position, pts, team_id, team_abbreviation
	from game_details gd
)
select 
	player_id as subject_identifier,
	'player'::vertex_type as subject_type,
	game_id as object_identifier,
	'game' :: vertex_type as object_type,
	'plays_in':: edge_type as edge_type,
		json_build_object(
		'start_position', start_position,
		'pts', pts,
		'team_id', team_id,
		'team_abbreviation', team_abbreviation
		) as properties
from players_play_in_teams;

select v.properties->>'player_name' as player_name,
Max(e.properties->>'pts') as max_points--count( distinct player_id , team_id )
from vertices v
join edges e
on e.subject_identifier = v.identifier and e.subject_type = v.type
group by 1
order by 2 desc;
select 'plays_in'::edge_type;

with players_play_in_games as (
	select distinct *--player_id , game_id, start_position, pts, team_id, team_abbreviation
	from game_details gd
) 
select g1.game_id,  g1.player_name, g2.player_name, g1.start_position
from players_play_in_games g1
join players_play_in_games g2
on g1.game_id = g2.game_id and g1.team_id <> g2.team_id and g1.start_position = g2.start_position
where g1.game_id = 11600001 --and 



