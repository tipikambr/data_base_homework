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
    user_id     integer REFERENCES common.user(id) ON DELETE CASCADE,
    avatar_link text,
    status      integer,
    last_seen   TIMESTAMP
);

CREATE TABLE common.friend
(
    -- TODO: when deleting user should check if both fields are NULL now -> DELETE
    user_id1  integer REFERENCES common.user(id) ON DELETE SET NULL,
    user_id2  integer REFERENCES common.user(id) ON DELETE SET NULL,
    direction integer,
    PRIMARY KEY (user_id1, user_id2)
);

CREATE TABLE common.user_to_group
(
    user_id INTEGER REFERENCES common.user(id)   ON DELETE CASCADE,
    group_id INTEGER REFERENCES common.group(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE common.permission_to_group
(
    group_id INTEGER REFERENCES common.group(id)           ON DELETE CASCADE,
    permission_id INTEGER REFERENCES common.permission(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, permission_id)
); 

CREATE TABLE game.game
(
    id       bigserial PRIMARY KEY,
    name     text,
    status   boolean,
    owner_id integer REFERENCES common.USER(id) ON DELETE SET NULL
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
    -- TODO: if DELETE a game with active session, set NULL for master, but let the game be
    -- also exclude from search
    -- On the end of active sessions - DELETE game
    id      bigserial PRIMARY KEY,
    active  boolean,
    master  bigint    REFERENCES common.user(id) ON DELETE SET NULL,
    game_id bigint    REFERENCES game.game(id)   ON DELETE RESTRICT
);

CREATE TABLE game.character
(
    id          bigserial PRIMARY KEY,
    session_id  bigint    REFERENCES game.game_session(id) ON DELETE CASCADE,
    user_id     integer   REFERENCES common.user(id)       ON DELETE CASCADE,
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
    trait_id     bigint REFERENCES game.trait(id)     ON DELETE CASCADE,
    character_id bigint REFERENCES game.character(id) ON DELETE CASCADE,
    value        integer,
    PRIMARY KEY (id, trait_id)
);

CREATE TABLE common.participant
(
    session_id bigint    REFERENCES game.game_session(id) ON DELETE CASCADE,
    user_id    integer   REFERENCES common.user(id)       ON DELETE CASCADE,
    PRIMARY KEY (session_id, user_id)
);

CREATE TABLE game.map_copy
(
    id           bigserial PRIMARY KEY,
    -- requires full copy before DELETE or UPDATE to keep the active sessions alive
    -- TODO: implement a custom trigger checking for active sessions
    -- no active sessions - just delete/update. Active - full copy, then proceed
    map_id       bigint REFERENCES game.map(id)          ON DELETE RESTRICT ON UPDATE RESTRICT,
    session_id   bigint REFERENCES game.game_session(id) ON DELETE CASCADE,
    name         text,
    description  text,
    preview_link text,
    x            float,
    y            float
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
    character_id bigint    REFERENCES game.character(id) ON DELETE CASCADE,
    effect_id    bigint    REFERENCES game.effect(id)    ON DELETE CASCADE,
    steps_left   integer
);

CREATE TABLE game.area_type
(
    id          bigint,
    -- TODO: custom trigger
    map_id      bigint                REFERENCES game.map(id)               ON DELETE CASCADE,
    map_copy_id bigint                REFERENCES game.map_copy(id)          ON DELETE CASCADE,
	image_link  text,
	name        text,
	effect_id   bigint                REFERENCES game.effect(id)            ON DELETE SET NULL,
    PRIMARY KEY (map_id, map_copy_id, id),
    UNIQUE      (map_id, map_copy_id, name)
);

CREATE TABLE game.area
(
    id           bigint,
    map_id       bigint               REFERENCES game.map(id)      ON DELETE CASCADE,
    map_copy_id  bigint               REFERENCES game.map_copy(id) ON DELETE CASCADE,
    x            integer,
    y            integer,
	area_type_id bigint,
	FOREIGN KEY (map_id, map_copy_id, area_type_id) REFERENCES game.area_type(map_id, map_copy_id, id),
	PRIMARY KEY (map_id, map_copy_id, id),
    UNIQUE      (map_copy_id, x, y),
    UNIQUE      (map_copy_id, id)
);

CREATE TABLE game.effect_area
(
	id          bigserial PRIMARY KEY,
	area_id     bigint,
    -- TODO: custom trigger (reset map_copy_id)
    map_id      bigint                         REFERENCES game.map(id)                       ON DELETE SET NULL,
    map_copy_id bigint                         REFERENCES game.map_copy(id)                  ON DELETE CASCADE,
	effect_id   bigint                         REFERENCES game.effect(id)                    ON DELETE CASCADE,
	FOREIGN KEY (area_id, map_id, map_copy_id) REFERENCES game.area(id, map_id, map_copy_id) ON DELETE CASCADE,
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

	FOREIGN KEY (
        from_area_id,
        from_map_id,
        from_map_copy_id
    ) REFERENCES game.area(id, map_id, map_copy_id) ON DELETE SET NULL,

	FOREIGN KEY (
        to_area_id,
        to_map_id,
        to_map_copy_id
    ) REFERENCES game.area(id, map_id, map_copy_id) ON DELETE SET NULL,

	PRIMARY KEY (
        from_area_id,
        from_map_id,
        from_map_copy_id,
        to_area_id,
        to_map_id,
        to_map_copy_id
    )
);

CREATE TABLE game.link_long
(
	from_map_id bigint REFERENCES game.map(id) ON DELETE SET NULL,
	to_map_id   bigint REFERENCES game.map(id) ON DELETE SET NULL,
	PRIMARY     KEY (from_map_id, to_map_id)
);

CREATE TABLE game.object_type
(
	id         serial PRIMARY KEY,
	image_link text,
	effect_id  bigint REFERENCES game.effect(id) ON DELETE SET NULL
);

CREATE TABLE game.object
(
	id             bigserial,
	object_type_id integer REFERENCES game.object_type(id) ON DELETE RESTRICT,
	area_id        bigint,
    -- TODO: custom trigger - reset map_copy_id
    map_id         bigint REFERENCES game.map(id)          ON DELETE SET NULL,
    map_copy_id    bigint,
    orientation    float,

	FOREIGN KEY (
        area_id, map_id,
        map_copy_id
    ) REFERENCES game.area(id, map_id, map_copy_id)        ON DELETE CASCADE,

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
	item_id bigint REFERENCES game.item(id) ON DELETE RESTRICT,
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
	item_id      bigint REFERENCES game.item(id)       ON DELETE RESTRICT,
	character_id bigint REFERENCES game.character(id)  ON DELETE CASCADE,
	prefix_id    bigint REFERENCES game.prefix(id)     ON DELETE SET NULL,
	postfix_id   bigint REFERENCES game.postfix(id)    ON DELETE SET NULL,
	equipped     boolean
);

CREATE TABLE game.allowed_items
(
	item_id bigint REFERENCES game.item(id) ON DELETE CASCADE,
	game_id bigint REFERENCES game.game(id) ON DELETE CASCADE,
	PRIMARY KEY (item_id, game_id)
);
