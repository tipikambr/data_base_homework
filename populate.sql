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

-- profiles
/*
INSERT INTO common.user_profile (user_id, status, last_seen) VALUES
    (...)
*/

-- TODO

-- game.area
