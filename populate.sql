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
    
INSERT INTO common.group (name) VALUES
('admin'),
('moderator'),
('user');

INSERT INTO common.permission (id, code_name) VALUES
(1, 'friends'),
(2, 'manage_games'),
(3, 'play'),
(4, 'manage_users'),
(5, 'view_all_games'),
(6, 'manage_moderators'),
(7, 'edit_all_games');

INSERT INTO common.user (username) VALUES
('Moderator1'),
('Moderator2'),
('Admin');

SELECT common.add_user_to_group('Player1', 'user');
SELECT common.add_user_to_group('Player2', 'user');
SELECT common.add_user_to_group('Player3', 'user');
SELECT common.add_user_to_group('Player4', 'user');
SELECT common.add_user_to_group('Admin', 'user');
SELECT common.add_user_to_group('Moderator1', 'user');
SELECT common.add_user_to_group('Moderator2', 'user');
SELECT common.add_user_to_group('Admin', 'admin');
SELECT common.add_user_to_group('Moderator1', 'moderator');
SELECT common.add_user_to_group('Moderator2', 'moderator');

SELECT common.add_permission_to_group('friends', 'user');
SELECT common.add_permission_to_group('play', 'user');
SELECT common.add_permission_to_group('manage_games', 'user');
SELECT common.add_permission_to_group('manage_users', 'moderator');
SELECT common.add_permission_to_group('view_all_games', 'moderator');
SELECT common.add_permission_to_group('manage_moderators', 'admin');
SELECT common.add_permission_to_group('edit_all_games', 'admin');
SELECT common.add_permission_to_group('manage_users', 'admin');
SELECT common.add_permission_to_group('view_all_games', 'admin');

-- profiles
/*
INSERT INTO common.user_profile (user_id, status, last_seen) VALUES
    (...)
*/

-- TODO
