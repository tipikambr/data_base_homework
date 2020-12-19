CREATE SCHEMA common;
CREATE SCHEMA game;

CREATE TABLE common.user 
(
    id SERIAL PRIMARY KEY,
    pwd_hash BIGINT,
    username TEXT,
    email TEXT
);

CREATE TABLE common.group 
(
    id SERIAL,
    name TEXT 
);

CREATE TABLE common.permission
(
    id INTEGER PRIMARY KEY,
    code_name TEXT
);

CREATE TABLE common.user_profile
(
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES common.user(id),
    avatar_link TEXT,
    status INTEGER,
    last_seen TIMESTAMP
);

CREATE TABLE common.friend
(
    user_id1 INTEGER REFERENCES common.user(id),
    user_id2 INTEGER REFERENCES common.user(id),
    direction integer,
    PRIMARY KEY (user_id1, user_id2)
);

CREATE TABLE game.game
(
    id BIGSERIAL PRIMARY KEY,
    name TEXT,
    status BOOLEAN,
    is_active BOOLEAN,
    owner_id INTEGER REFERENCES common.USER(id)
);

CREATE TABLE game.character
(
    id BIGSERIAL PRIMARY KEY,
    game_id BIGINT REFERENCES game.game(id),
    user_id INTEGER REFERENCES common.user(id),
    name text,
    avatar_link text 
);

CREATE TABLE game.trait 
(
    id BIGSERIAL PRIMARY KEY,
    game_id BIGINT REFERENCES game.game(id),
    name text
);

CREATE TABLE game.trait_value
(
    id BIGSERIAL,
    trait_id BIGINT REFERENCES game.trait(id),
    character_id BIGINT REFERENCES game.character(id),
    value INTEGER,
    PRIMARY KEY (id, trait_id)
);

CREATE TABLE common.participant
(
    id BIGSERIAL PRIMARY KEY,
    game_id BIGINT REFERENCES game.game(id),
    user_id INTEGER REFERENCES common.user(id)
);

CREATE TABLE game.map
(
    id           BIGSERIAL PRIMARY KEY,
    name         text,
    preview_link text,
    x            FLOAT,
    y            FLOAT,
	pattern      INTEGER
);

CREATE TABLE game.map_copy
(
    id           BIGSERIAL,
    name         text,
    description  text,
    preview_link text,
    game_id      BIGINT REFERENCES game.game(id),
    map_id       BIGINT REFERENCES game.map(id),
    x            FLOAT,
    y            FLOAT,
    PRIMARY KEY (id, map_id)
);

CREATE TABLE game.effect
(
    id BIGSERIAL PRIMARY KEY,
    effect_key TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP
);

CREATE TABLE game.effect_instance
(
    id BIGSERIAL PRIMARY KEY,
    character_id BIGINT REFERENCES game.character(id),
    effect_id BIGINT REFERENCES game.effect(id),
    steps_left integer
);

CREATE TABLE game.area_type
(
    id          BIGINT,
    map_id      BIGINT REFERENCES game.map(id),
    map_copy_id BIGINT,
	image_link  TEXT,
	name        TEXT,
	effect_id   BIGINT REFERENCES game.effect(id),
    PRIMARY KEY (map_id, map_copy_id, id),
	FOREIGN KEY (map_id, map_copy_id) REFERENCES game.map_copy(map_id, id),
    UNIQUE      (map_id, map_copy_id, name)
);

CREATE TABLE game.area
(
    id           BIGINT,
    map_id       BIGINT               REFERENCES game.map(id),
    map_copy_id  BIGINT,
    x            INTEGER,
    y            INTEGER,
	area_type_id BIGINT,
	FOREIGN KEY (map_id, map_copy_id) REFERENCES game.map_copy(map_id, id),
	FOREIGN KEY (map_id, map_copy_id, area_type_id) REFERENCES game.area_type(map_id, map_copy_id, id),
	PRIMARY KEY (map_id, map_copy_id, id),
    UNIQUE      (map_copy_id, x, y),
    UNIQUE      (map_copy_id, id)
);

CREATE TABLE game.effect_area
(
	id BIGSERIAL PRIMARY KEY,
	area_id BIGINT,
    map_id BIGINT ,
    map_copy_id BIGINT ,
	effect_id BIGINT REFERENCES game.effect(id),
	
	FOREIGN KEY (area_id, map_id, map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	values FLOAT[]
);


CREATE TABLE game.link_short
(
	from_area_id BIGINT,
    from_map_id BIGINT,
    from_map_copy_id BIGINT,
	to_area_id BIGINT,
    to_map_id BIGINT,
    to_map_copy_id BIGINT,

	FOREIGN KEY (from_area_id, from_map_id, from_map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	FOREIGN KEY (to_area_id, to_map_id, to_map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	PRIMARY KEY (from_area_id,from_map_id,from_map_copy_id, to_area_id,to_map_id,to_map_copy_id)
);

CREATE TABLE game.link_long
(
	from_map_id BIGINT REFERENCES game.map(id),
	to_map_id BIGINT  REFERENCES game.map(id),
	PRIMARY KEY (from_map_id, to_map_id)
);

CREATE TABLE game.object_type
(
	id SERIAL PRIMARY KEY,
	image_link TEXT,
	effect_id BIGINT REFERENCES game.effect(id)
);

CREATE TABLE game.object
(
	id BIGSERIAL,
	object_type_id INTEGER REFERENCES game.object_type(id),
	area_id BIGINT,
    map_id BIGINT,
    map_copy_id BIGINT,
    orientation FLOAT,

	FOREIGN KEY (area_id, map_id, map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	PRIMARY KEY (id, object_type_id)
);

CREATE TABLE game.item
(
	id BIGSERIAL PRIMARY KEY,
	name TEXT,
	description TEXT,
	effect_array TEXT
);

CREATE TABLE game.dropped_item
(
	id BIGSERIAL PRIMARY KEY,
	item_id BIGINT REFERENCES game.item(id),
	area_id BIGINT
);

CREATE TABLE game.prefix
(
	id BIGSERIAL PRIMARY KEY,
	name TEXT,
	effect_array TEXT
);

CREATE TABLE game.postfix
(
	id BIGSERIAL PRIMARY KEY,
	name TEXT,
	effect_array TEXT
);

CREATE TABLE game.item_instance
(
	id BIGSERIAL,
	item_id BIGINT REFERENCES game.item(id),
	character_id BIGINT REFERENCES game.character(id),
	prefix_id BIGINT REFERENCES game.prefix(id),
	postfix_id BIGINT REFERENCES game.postfix(id),
	equipped BOOLEAN
);

CREATE TABLE game.allowed_items
(
	item_id BIGINT REFERENCES game.item(id),
	game_id BIGINT REFERENCES game.game(id),
	PRIMARY KEY (item_id, game_id)
);
