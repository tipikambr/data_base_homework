/*
--------------------------------------------------------------------------------
                                    Friend
--------------------------------------------------------------------------------
*/
-- 1.1
-- Get list of user friends
CREATE OR REPLACE FUNCTION common.get_friends(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                CASE user_id1 WHEN _id THEN user_id2 ELSE user_id1 END
                FROM common.friend
                WHERE (user_id1 = _id OR user_id2 = _id) AND direction = 0
        );

    $$
    LANGUAGE SQL;

-- 1.2
-- Outcoming friend requests
CREATE OR REPLACE FUNCTION common.get_outcoming_friend_requests(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                user_id2
                FROM common.friend
                WHERE user_id1 = _id AND direction = 1
            );

    $$
    LANGUAGE SQL;

-- 1.3
-- Incoming friend requests
CREATE OR REPLACE FUNCTION common.get_incoming_friend_requests(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                user_id2
                FROM common.friend
                WHERE user_id2 = _id AND direction = 1
            );

    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    Friend
--------------------------------------------------------------------------------
*/
    
    
/*
--------------------------------------------------------------------------------
                                    Permissions
--------------------------------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION common.add_user_to_group(user_id int, group_id int) RETURNS VOID
    AS
    $$
        INSERT INTO common.user_to_group (user_id, group_id) VALUES
            (user_id, group_id);
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_user_to_group(user_name TEXT, group_name TEXT) RETURNS VOID
    AS
    $$
        INSERT INTO common.user_to_group (user_id, group_id)
        SELECT * FROM
            (SELECT id FROM common.user WHERE username = user_name) AS t1,
             (SELECT id FROM common.group WHERE name = group_name) AS t2;
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group(permission_id int, group_id int) RETURNS VOID
    AS
    $$
        INSERT INTO common.permission_to_group (group_id, permission_id) VALUES
            (group_id, permission_id);
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group(permission_name TEXT, group_name TEXT) RETURNS VOID
    AS
    $$
        INSERT INTO common.permission_to_group (group_id, permission_id)
            SELECT * FROM
                (SELECT id FROM common.group WHERE name = group_name) AS t1,
                (SELECT id FROM common.permission WHERE code_name = permission_name) AS t2;
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.get_all_permissions(id_user int) RETURNS TABLE (LIKE common.permission)
    AS
    $$
        SELECT * FROM common.permission WHERE
            EXISTS (SELECT * FROM common.permission_to_group, common.user_to_group
                   WHERE common.permission_to_group.permission_id = common.permission.id AND
                   common.permission_to_group.group_id = common.user_to_group.group_id AND
                   common.user_to_group.user_id = id_user);
    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    Permissions
--------------------------------------------------------------------------------
*/

/*
--------------------------------------------------------------------------------
                                    Character view edit
--------------------------------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION game.get_character(id_game BIGINT, id_user INTEGER) RETURNS TABLE (LIKE game.character)
    AS
    $$
        SELECT * FROM game.character
            WHERE game.character.game_id = id_game AND game.character.user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.get_characters(id_game BIGINT) RETURNS TABLE (LIKE game.character)
    AS
    $$
        SELECT * FROM game.character
            WHERE game.character.game_id = id_game;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.set_character_trait(id_character BIGINT, id_trait BIGINT, value_trait int) RETURNS VOID
    AS
    $$
        UPDATE game.trait_value
            SET value = value_trait
            WHERE trait_id = id_trait AND character_id = id_character;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.add_character_trait(id_character BIGINT, id_trait BIGINT, value_trait int) RETURNS VOID
    AS
    $$
        INSERT INTO game.trait_value (character_id, trait_id, value) VALUES
        (id_character, id_trait, value_trait);
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.remove_character_trait(id_character BIGINT, id_trait BIGINT) RETURNS VOID
    AS
    $$
        DELETE FROM game.trait_value
            WHERE character_id = id_character AND trait_id = id_trait;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.get_character_traits(id_character BIGINT) RETURNS TABLE(trait_id BIGINT,
trait_name TEXT, trait_value int)
    AS
    $$
        SELECT tt.id AS trait_id, tt.name AS trait_name, tv.value AS trait_value
        FROM game.trait_value AS tv, game.trait AS tt
            WHERE tv.character_id = id_character AND
                  tv.trait_id = tt.id;
    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    Character view edit
--------------------------------------------------------------------------------
*/


/*
--------------------------------------------------------------------------------
                                    User profile
--------------------------------------------------------------------------------
 */

CREATE OR REPLACE FUNCTION common.set_user_status(id_user int, status_user int) RETURNS VOID
    AS
    $$
        UPDATE common.user_profile
            SET status = status_user
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.get_user_status(id_user int) RETURNS int
    AS
    $$
        SELECT status FROM common.user_profile
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.set_user_avatar(id_user int, link_avatar TEXT) RETURNS VOID
    AS
    $$
        UPDATE common.user_profile
            SET avatar_link = link_avatar
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.get_user_avatar(id_user int) RETURNS TEXT
    AS
    $$
        SELECT avatar_link FROM common.user_profile
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.set_user_last_presence(id_user int, seen_last TIMESTAMP) RETURNS VOID
    AS
    $$
        UPDATE common.user_profile
            SET last_seen = seen_last
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.get_user_last_presence(id_user int) RETURNS TIMESTAMP
    AS
    $$
        SELECT last_seen FROM common.user_profile
            WHERE user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.get_games_user_owns(id_user int) RETURNS TABLE(LIKE game.game)
    AS
    $$
        SELECT * FROM game.game
            WHERE owner_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION common.get_games_user_plays(id_user int)  RETURNS TABLE(LIKE game.game)
    AS
    $$
        SELECT * FROM game.game AS g
            WHERE EXISTS (SELECT * FROM common.participant AS p
                            WHERE p.user_id = id_user AND g.id = p.game_id);
    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    User profile
--------------------------------------------------------------------------------
 */
