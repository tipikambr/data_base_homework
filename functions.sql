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
                                    Room
--------------------------------------------------------------------------------
*/

-- Create game
CREATE OR REPLACE FUNCTION game.create_game(_id int, _name text, _status bool, _is_active bool, _map_id bigint, _description text) RETURNS VOID
    AS
    $$
    INSERT INTO game.game (name, status, is_active, owner_id) VALUES
        (_name, _status, _is_active, _id);
        
    INSERT INTO game.map_copy (map_id, game_id, name, preview_link, x, y) VALUES
        (_map_id, 
        (SELECT id 
        FROM game.game
        WHERE _name = name AND _id = owner_id),
        (SELECT name
        FROM game.map
        where id = _map_id
        ),
        (SELECT preview_link
        FROM game.map
        where id = _map_id
        ),
        (SELECT x
        FROM game.map
        where id = _map_id
        ),
        (SELECT y
        FROM game.map
        where id = _map_id
        )
        );
        
    INSERT INTO common.participant (game_id, user_id) VALUES
        ((
        SELECT id 
        FROM game.game
        WHERE _name = name AND _id = owner_id),
         _id
        );
    $$
    LANGUAGE SQL;

-- List of Games
CREATE OR REPLACE FUNCTION game.get_games() RETURNS TABLE (LIKE game.game)
    AS
    $$
    SELECT * FROM game.game
    $$
    LANGUAGE SQL;

-- Delete room
CREATE OR REPLACE FUNCTION game.delete_game(g_id bigint) RETURNS VOID
    AS
    $$
    DELETE FROM game.effect_instance
    WHERE character_id IN 
        (
        SELECT id 
        FROM game.character
        WHERE game_id = g_id
        );
        
    DELETE FROM game.item_instance
    WHERE character_id IN (
        SELECT 
        id 
            FROM game.character
            WHERE game_id = g_id
        );
        
    DELETE FROM game.trait_value
    WHERE character_id IN (
        SELECT 
            id 
            FROM game.character
            WHERE game_id = g_id
        );
        
    DELETE FROM game.character
    WHERE game_id = g_id;
    
    DELETE FROM game.allowed_items
    WHERE game_id = g_id;
        
    DELETE FROM game.trait
    WHERE game_id = g_id;
    
    DELETE FROM game.dropped_item
    WHERE area_id IN (
        SELECT 
            id 
            FROM game.area
            WHERE map_copy_id IN (
                SELECT
                    id
                    FROM game.map_copy
                    WHERE game_id = g_id
                )
        );
    
    DELETE FROM game.object
    WHERE area_id IN (
        SELECT 
            id 
            FROM game.area
            WHERE map_copy_id IN (
                SELECT
                    id
                    FROM game.map_copy
                    WHERE game_id = g_id
                )
        );
        
    DELETE FROM game.effect_area
    WHERE area_id IN (
        SELECT 
            id 
            FROM game.area
            WHERE map_copy_id IN (
                SELECT
                    id
                    FROM game.map_copy
                    WHERE game_id = g_id
                )
        );
        
    DELETE FROM game.link_short
    WHERE (from_area_id, from_map_id, from_map_copy_id) IN (
        SELECT 
            id, map_id, map_copy_id 
            FROM game.area
            WHERE map_copy_id IN (
                SELECT
                    id
                    FROM game.map_copy
                    WHERE game_id = g_id
                )
        ) or (to_area_id, to_map_id, to_map_copy_id) IN (
        SELECT 
            id, map_id, map_copy_id  
            FROM game.area
            WHERE map_copy_id IN (
                SELECT
                    id
                    FROM game.map_copy
                    WHERE game_id = g_id
                )
        );
    
    DELETE FROM game.area
    WHERE map_copy_id IN (
        SELECT
            id
            FROM game.map_copy
            WHERE game_id = g_id
        );
    
    DELETE FROM game.map_copy
    WHERE game_id = g_id;
    
    DELETE FROM common.participant
    WHERE g_id = game_id;
    
    DELETE FROM game.game
    WHERE g_id = id;
    $$
    LANGUAGE SQL;

-- List of players in game
CREATE OR REPLACE FUNCTION game.get_players_in_game_list(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                user_id
                FROM common.participant
                WHERE game_id = _id
            );

    $$
    LANGUAGE SQL;

-- Connect to room
CREATE OR REPLACE FUNCTION game.user_connect_game(u_id int, g_id bigint) RETURNS VOID
    AS
    $$
    INSERT INTO common.participant (game_id, user_id) VALUES
        (g_id, u_id);
    $$
    LANGUAGE SQL;

-- List of player characters in game
CREATE OR REPLACE FUNCTION game.get_characters_in_game_list(u_id int, g_id bigint) RETURNS TABLE (LIKE game.character)
    AS
    $$
    SELECT * FROM game.character x
        WHERE x.id IN (
            SELECT
                id
                FROM game.character
                WHERE game_id = g_id and user_id = u_id
            );

    $$
    LANGUAGE SQL;

-- Create character
CREATE OR REPLACE FUNCTION game.create_character(u_id int, g_id bigint, _name text, _avatar_link text) RETURNS VOID
    AS
    $$
    INSERT INTO game.character (game_id, user_id, name, avatar_link) VALUES
        (g_id, u_id, _name, _avatar_link);
    $$
    LANGUAGE SQL;

-- Change character avatar
CREATE OR REPLACE FUNCTION game.change_character_avatar(_id int, _avatar_link text) RETURNS VOID
    AS
    $$
    UPDATE game.character 
    SET avatar_link = _avatar_link
    WHERE id = _id
    $$
    LANGUAGE SQL;

-- Change character name
CREATE OR REPLACE FUNCTION game.change_character_avatar(_id int, _name text) RETURNS VOID
    AS
    $$
    UPDATE game.character 
    SET name = _name
    WHERE id = _id
    $$
    LANGUAGE SQL;