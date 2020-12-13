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
    id BIGSERIAL PRIMARY KEY,
    name text,
    preview_link text,
    x FLOAT,
    y FLOAT
);

CREATE TABLE game.map_copy
(
    id BIGSERIAL,
    name text,
    description text,
    preview_link text,
    game_id BIGINT REFERENCES game.game(id),
    map_id BIGINT REFERENCES game.map(id),
    x FLOAT,
    y FLOAT,
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

CREATE TABLE game.area
(
    id BIGSERIAL,
    map_id BIGINT,
    map_copy_id BIGINT,
    
    x INTEGER,
    y INTEGER
);
CREATE TABLE game.effect_area
(

);
