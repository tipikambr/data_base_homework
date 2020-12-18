-- users
INSERT INTO common.user (username) VALUES
    ('Player1'),
    ('Player2'),
    ('Player3'),
    ('Player4');

-- friends
INSERT INTO common.friend (user_id1, user_id2, direction) VALUES
    (1, 2, 0),
    (1, 3, 1),
    (1, 4, 0),
    (2, 3, -1),
    (3, 4, 1);

-- Games
INSERT INTO game.game (name, owner_id) VALUES
    ('Game1', 1),
    ('Game2', 4);

-- participants
INSERT INTO common.participant (game_id, user_id) VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4),
    (2, 1);

-- Characters
INSERT INTO game.character (game_id, user_id, name) VALUES
    (1, 1, 'Thor'),
    (1, 2, 'Odin'),
    (1, 1, 'GLaDOS'), 
    (2, 3, 'Dude'),
    (2, 1, 'Witcher'),
    (2, 4, 'Daenerys Stormborn of House Targaryen, Rightful heir to the Iron Throne, Rightful Queen of the Andals and the First Men, Protector of the Seven Kingdoms, the Mother of Dragons, the Khaleesi of the Great Grass Sea, the Unburnt, the Breaker of Chains.');

-- Maps
INSERT INTO game.map (name) VALUES
    ('map1'),
    ('map2');

-- profiles
/*
INSERT INTO common.user_profile (user_id, status, last_seen) VALUES
    (...)
*/

-- TODO
