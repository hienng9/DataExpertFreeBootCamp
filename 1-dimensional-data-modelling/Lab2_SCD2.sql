create table players_scd (  
	player_name text,
	scoring_class scoring_class,
	is_active boolean,
	current_season integer,
	start_season integer,
	end_season integer,
	primary key(player_name, current_season)
)


select player_name, scoring_class, is_active
from players p 
where current_season  = 1996;