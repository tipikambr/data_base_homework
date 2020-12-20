/*------------------------------------------------------------------------------
                                    Room
------------------------------------------------------------------------------*/

-- Create game
-- TODO: exceptions
CREATE OR REPLACE FUNCTION game.create_game(
    _id          int,
    _name        text,
    _status      bool,
    _is_active   bool,
    _map_id      bigint,
    _description text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.game (name,
        status,
        is_active,
        owner_id
    ) VALUES (
        _name,
        _status,
        _is_active,
        _id
    );
        
    INSERT INTO game.map_copy (
        map_id,
        game_id,
        name,
        preview_link,
        x,
        y
    ) VALUES (      -- WTF is this? 5 inner queries?? The 4 last queries sample from the same record!
        -- TODO: fix this bullshit
        _map_id,
        (SELECT id           FROM game.game WHERE _name = name AND _id = owner_id),
        (SELECT name         FROM game.map  WHERE id    = _map_id),
        (SELECT preview_link FROM game.map  WHERE id    = _map_id),
        (SELECT x            FROM game.map  where id    = _map_id),
        (SELECT y            FROM game.map  where id    = _map_id)
    );
        
    INSERT INTO common.participant (
        game_id,
        user_id
    ) VALUES (
        (SELECT id FROM game.game g WHERE _name = g.name AND _id = g.owner_id LIMIT 1), -- WTF is this query? There is no unique constraint on  (name, owner_id)! Too bad!
        _id
    );
END;
$$;

-- List of Games
CREATE OR REPLACE FUNCTION game.get_games (
) RETURNS TABLE (LIKE game.game) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM game.game;
END;
$$;

-- Delete room
-- TODO: Exceptions, rollbacks
-- FIXME: these 100 lines should be replaced with a couple of DELETE CASCADE queries
CREATE OR REPLACE FUNCTION game.delete_game(
    g_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.effect_instance
    WHERE character_id IN (
        SELECT id FROM game.character 
        WHERE game_id = g_id
    );
        
    DELETE FROM game.item_instance
    WHERE character_id IN (
        SELECT id 
        FROM game.character
        WHERE game_id = g_id
    );
        
    DELETE FROM game.trait_value
    WHERE character_id IN (
        SELECT id 
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
        SELECT id 
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
            FROM game.map_copy
            WHERE game_id = g_id
        )
    );
    
    DELETE FROM game.object
    WHERE area_id IN (
        SELECT id 
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
            FROM game.map_copy
            WHERE game_id = g_id
        )
    );
        
    DELETE FROM game.effect_area
    WHERE area_id IN (
        SELECT id 
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
            FROM game.map_copy
            WHERE game_id = g_id
        )
    );
        
    DELETE FROM game.link_short -- FIXME: too many queries?
    WHERE (
        from_area_id,
        from_map_id,
        from_map_copy_id
    ) IN (
        SELECT
            id, map_id, map_copy_id 
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
                FROM game.map_copy
                WHERE game_id = g_id
        )
    )
    OR (
        to_area_id,
        to_map_id,
        to_map_copy_id
    ) IN (
        SELECT 
            id, map_id, map_copy_id  
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
            FROM game.map_copy
            WHERE game_id = g_id
        )
    );
    
    DELETE FROM game.area
    WHERE map_copy_id IN (
        SELECT id
        FROM game.map_copy
        WHERE game_id = g_id
    );
    
    DELETE FROM game.map_copy
    WHERE game_id = g_id;
    
    DELETE FROM common.participant
    WHERE g_id = game_id;
    
    DELETE FROM game.game
    WHERE g_id = id;
END;
$$;

-- List of players in game
CREATE OR REPLACE FUNCTION game.get_players_in_game_list(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT user_id
        FROM common.participant
        WHERE game_id = _id
    );
END;
$$;

-- Connect to room
CREATE OR REPLACE FUNCTION game.user_connect_game(
    u_id int,
    g_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.participant (
        game_id,
        user_id
    ) VALUES (
        g_id,
        u_id
    );
END;
$$;

-- List of player characters in game
CREATE OR REPLACE FUNCTION game.get_characters_in_game_list(
    u_id int,
    g_id bigint
) RETURNS TABLE (LIKE game.character) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM game.character x
    WHERE x.id IN (
        SELECT id
        FROM game.character
        WHERE game_id = g_id AND user_id = u_id
    );
END;
$$;

-- Create character
CREATE OR REPLACE FUNCTION game.create_character (
    u_id         int,
    g_id         bigint,
    _name        text,
    _avatar_link text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.character (
        game_id,
        user_id,
        name,
        avatar_link
    ) VALUES (
        g_id,
        u_id,
        _name,
        _avatar_link
    );
END;
$$;

-- Change character avatar
CREATE OR REPLACE FUNCTION game.change_character_avatar(
    _id          int,
    _avatar_link text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.character
    SET    avatar_link = _avatar_link
    WHERE  id = _id;
END;
$$;

-- Change character name
-- Couldn't you just test these functions to get them at least compiling?...
CREATE OR REPLACE FUNCTION game.change_character_name(
    _id   int,
    _name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.character
    SET    name = _name
    WHERE  id   = _id;
END;
$$;
