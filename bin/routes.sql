drop table routes, route_trips, route_codes cascade;

create temp view trip_codes as
	select distinct trip, code
	from stops order by trip, code;

create temp view trip_code_lists as
	select trip, array_to_string(array_accum(code),',') as code_list
	from trip_codes group by trip;

create temp view trip_code_list_dirs as
	select trip, code_list, direction
	from trips natural join trip_code_lists;

create temp sequence route_index_seq;
create temp table route_dir_code_lists as select
	nextval('route_index_seq') as route,
	code_list,
	direction
from trip_code_list_dirs
group by code_list, direction
order by code_list, direction;

create table route_trips as
	select route, trip
	from route_dir_code_lists natural join trip_code_list_dirs
	order by route, trip;

create unique index route_trips_route_trip_idx on route_trips(route,trip);
create index route_trips_route_idx on route_trips (route);
create index route_trips_trip_idx on route_trips (trip);

create table route_codes as
	select distinct route, code
	from route_trips natural join trip_codes
	order by route, code;

create unique index route_codes_route_code_idx on route_codes(route,code);
create index route_codes_route_idx on route_codes (route);
create index route_codes_trip_idx on route_codes (code);

create table routes as select
	route, line, trip_line,	direction, orig_code,	dest_code, codes, trips
from route_trips
	natural join trips
	natural join (select route, count(*) as codes from route_codes group by route) cx
	natural join (select route, count(*) as trips from route_trips group by route) tx
group by route, line, trip_line,	direction, orig_code,	dest_code, codes, trips
order by route, line, trip_line,	direction, orig_code,	dest_code, codes, trips;

create unique index routes_route_idx on routes (route);
