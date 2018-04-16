
create or replace function toint(text) returns int LANGUAGE sql immutable as $$
select case 
when $1 is NULL or $1 = 'unknown' or $1='' or $1 = 'ž' then NULL
when $1='no' then 0
when $1 = 'yes' then 1
else cast(btrim($1, '~ cars') as int)
end
$$ ;

drop table if exists parkingplaces;

create table www.parkingplaces as 
select osm_id, name, ref, toint(tags->'capacity') as capacity, toint(tags->'capacity:disabled') as capacity_disabled, tags->'access' as access, 
tags, geography(way) as way
from fresh_osm_polygon where amenity='parking';

insert into parkingplaces
select osm_id, name, ref, toint(tags->'capacity') as capacity, toint(tags->'capacity:disabled' ) as capacity_disabled, tags->'access' as access,
tags, geography(way) as way
from fresh_osm_point where amenity='parking' and osm_id not in (select osm_id from parkingplaces);

insert into parkingplaces
select osm_id, name, ref, toint(tags->'capacity') as capacity, toint(tags->'capacity:disabled') as capacity_disabled, tags->'access' as access,
tags, geography(way) as way
from fresh_osm_line where amenity='parking' and osm_id not in (select osm_id from parkingplaces);


-- todo: a lot of work needed here
insert into parkingplaces
select osm_id, name, ref, 
toint(tags->'parking:lane:capacity') + toint(tags->'parking:lane:right:capacity') + toint(tags->'parking:lane:left:capacity') as capacity,
toint(tags->'parking:lane:capacity:disabled') + toint(tags->'parking:lane:right:capacity:disabled') + toint(tags->'parking:lane:left:capacity:disabled') as capacity_disabled,
tags->'parking:condition:both' as access,
tags, geography(way) as way
from fresh_osm_line where (exist(tags,'parking:lane') or exist(tags,'parking:lane:right') or exist(tags,'parking:lane:left') or exist(tags,'parking:lane:both') ) 
and osm_id not in (select osm_id from parkingplaces);

create index on parkingplaces using gist(way);
vacuum analyze parkingplaces;

