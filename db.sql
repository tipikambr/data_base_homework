--create schema main
--create schema map

--create type access_type as enum ('user', 'master', 'author');
--create type object_state as enum ('under constuction', 'ready', 'busy')

create table main.user 
(
	login text primary key,
	password_hash bigint,	--IMPORTANT
	access_level access_type NOT NULL
);

create table main.setting
(
	setting_name text primary key,
	author_id text REFERENCES main.user (login),
	setting_state object_state not null
);

create table main.game
(
	game_id uuid primary key,
	setting_id text REFERENCES main.setting (setting_name),
	master_id text REFERENCES main.user (login),
	game_state object_state not null
);

create table map.map
(
	map_id int primary key,
	parent_id int references map.map (map_id)
	map_name text,
	map_description text
);

create table map.area_type 
(
	area_type_id serial primary key,
	type_name text
);

create table map.area_shape
(
	area_shape_id serial primary key,
	shape_name text
);

create table map.area 
(
	area_id serial primary key,
	map_id int references map.map (map_id) not null,
	area_type int references map.area_type (area_type_id) not null,
	area_shape int references map.area_shape (area_shape_id) not null,
	area_point point not null
);

CREATE INDEX map.area_map ON map.area ( map_id  ASC );

create table map.link_type
(
	link_type_id serial primary key,
	link_name text
);

create table map.link
(
	link_id serial,
	area_from_id int references map.area (area_id) not null,
	area_to_id int references map.area (area_id),
	map_id int references map.map (map_id) not null,
	link_type int references map.link_type (link_type_id) not null,
	description text,
	primary key (link_id, area_from_id)
);

create table map.object_type
(
	object_type_id serial primary key,
	object_name text
);

create table map.object
(
	object_id bigint primary key,
	object_type_id int references map.object_type (object_type_id) not null,
	parent_id bigint references map.object (object_id),
	link_id int references map.link (link_id),
	object_point point,
	description text
);