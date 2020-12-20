CREATE SCHEMA common;
CREATE SCHEMA game;

CREATE TABLE common.user 
(
    id       serial PRIMARY KEY,
    pwd_hash bigint,
    username text,
    email    text
);

CREATE TABLE common.group 
(
    id   serial PRIMARY KEY,
    name text
);

CREATE TABLE common.permission
(
    id        integer PRIMARY KEY,
    code_name text
);

CREATE TABLE common.user_profile
(
    id          serial PRIMARY KEY,
    user_id     integer REFERENCES common.user(id),
    avatar_link text,
    status      integer,
    last_seen   TIMESTAMP
);

CREATE TABLE common.friend
(
    user_id1  integer REFERENCES common.user(id),
    user_id2  integer REFERENCES common.user(id),
    direction integer,
    PRIMARY KEY (user_id1, user_id2)
);

CREATE TABLE common.user_to_group
(
    user_id INTEGER REFERENCES common.user(id),
    group_id INTEGER REFERENCES common.group(id),
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE common.permission_to_group
(
    group_id INTEGER REFERENCES common.group(id),
    permission_id INTEGER REFERENCES common.permission(id),
    PRIMARY KEY (group_id, permission_id)
); 

CREATE TABLE game.game
(
    id       bigserial PRIMARY KEY,
    name     text,
    status   boolean,
    owner_id integer REFERENCES common.USER(id)
);

CREATE TABLE game.map
(
    id           bigserial PRIMARY KEY,
    name         text,
    description  text,
    preview_link text,
    x            float,
    y            float,
	pattern      integer
);

CREATE TABLE game.game_session
(
    id      bigserial PRIMARY KEY,
    master  bigint    REFERENCES common.user(id),
    active  boolean,
    game_id bigint    REFERENCES game.game(id)
);

CREATE TABLE game.character
(
    id          bigserial PRIMARY KEY,
    session_id  bigint REFERENCES game.game_session(id),
    user_id     integer REFERENCES common.user(id),
    name        text,
    avatar_link text
);

CREATE TABLE game.trait 
(
    id      bigserial PRIMARY KEY,
    game_id bigint REFERENCES game.game(id),
    name    text,
    UNIQUE (game_id, name)
);

CREATE TABLE game.trait_value
(
    id           bigserial,
    trait_id     bigint REFERENCES game.trait(id),
    character_id bigint REFERENCES game.character(id),
    value        integer,
    PRIMARY KEY (id, trait_id)
);

CREATE TABLE common.participant
(
    session_id bigint    REFERENCES game.game_session(id),
    user_id    integer   REFERENCES common.user(id),
    PRIMARY KEY (session_id, user_id)
);

CREATE TABLE game.map_copy
(
    id           bigserial,
    map_id       bigint REFERENCES game.map(id),
    session_id   bigint REFERENCES game.game_session(id),
    name         text,
    description  text,
    preview_link text,
    x            float,
    y            float,
    PRIMARY KEY (id, map_id)
);

CREATE TABLE game.effect
(
    id         bigserial PRIMARY KEY,
    effect_key text,
    start_time timestamp,
    end_time   timestamp
);

CREATE TABLE game.effect_instance
(
    id           bigserial PRIMARY KEY,
    character_id bigint    REFERENCES game.character(id),
    effect_id    bigint    REFERENCES game.effect(id),
    steps_left   integer
);

CREATE TABLE game.area_type
(
    id          bigint,
    map_id      bigint REFERENCES game.map(id),
    map_copy_id bigint,
	image_link  text,
	name        text,
	effect_id   bigint REFERENCES game.effect(id),
    PRIMARY KEY (map_id, map_copy_id, id),
	FOREIGN KEY (map_id, map_copy_id) REFERENCES game.map_copy(map_id, id),
    UNIQUE      (map_id, map_copy_id, name)
);

CREATE TABLE game.area
(
    id           bigint,
    map_id       bigint               REFERENCES game.map(id),
    map_copy_id  bigint,
    x            integer,
    y            integer,
	area_type_id bigint,
	FOREIGN KEY (map_id, map_copy_id) REFERENCES game.map_copy(map_id, id),
	FOREIGN KEY (map_id, map_copy_id, area_type_id) REFERENCES game.area_type(map_id, map_copy_id, id),
	PRIMARY KEY (map_id, map_copy_id, id),
    UNIQUE      (map_copy_id, x, y),
    UNIQUE      (map_copy_id, id)
);

CREATE TABLE game.effect_area
(
	id          bigserial PRIMARY KEY,
	area_id     bigint,
    map_id      bigint ,
    map_copy_id bigint ,
	effect_id   bigint REFERENCES game.effect(id),
	
	FOREIGN KEY (area_id, map_id, map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	values float[]
);


CREATE TABLE game.link_short
(
	from_area_id     bigint,
    from_map_id      bigint,
    from_map_copy_id bigint,
	to_area_id       bigint,
    to_map_id        bigint,
    to_map_copy_id   bigint,

	FOREIGN KEY (from_area_id, from_map_id, from_map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	FOREIGN KEY (to_area_id, to_map_id, to_map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	PRIMARY KEY (from_area_id,from_map_id,from_map_copy_id, to_area_id,to_map_id,to_map_copy_id)
);

CREATE TABLE game.link_long
(
	from_map_id bigint REFERENCES game.map(id),
	to_map_id   bigint  REFERENCES game.map(id),
	PRIMARY     KEY (from_map_id, to_map_id)
);

CREATE TABLE game.object_type
(
	id         serial PRIMARY KEY,
	image_link text,
	effect_id  bigint REFERENCES game.effect(id)
);

CREATE TABLE game.object
(
	id             bigserial,
	object_type_id integer REFERENCES game.object_type(id),
	area_id        bigint,
    map_id         bigint,
    map_copy_id    bigint,
    orientation    float,

	FOREIGN KEY (area_id, map_id, map_copy_id) REFERENCES game.area(id, map_id, map_copy_id),
	PRIMARY KEY (id, object_type_id)
);

CREATE TABLE game.item
(
	id           bigserial PRIMARY KEY,
	name         text,
	description  text,
	effect_array text
);

CREATE TABLE game.dropped_item
(
	id      bigserial PRIMARY KEY,
	item_id bigint REFERENCES game.item(id),
	area_id bigint
);

CREATE TABLE game.prefix
(
	id           bigserial PRIMARY KEY,
	name         text,
	effect_array text
);

CREATE TABLE game.postfix
(
	id           bigserial PRIMARY KEY,
	name         text,
	effect_array text
);

CREATE TABLE game.item_instance
(
	id           bigserial,
	item_id      bigint REFERENCES game.item(id),
	character_id bigint REFERENCES game.character(id),
	prefix_id    bigint REFERENCES game.prefix(id),
	postfix_id   bigint REFERENCES game.postfix(id),
	equipped     boolean
);

CREATE TABLE game.allowed_items
(
	item_id bigint REFERENCES game.item(id),
	game_id bigint REFERENCES game.game(id),
	PRIMARY KEY (item_id, game_id)
);
