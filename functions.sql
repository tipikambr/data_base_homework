/*------------------------------------------------------------------------------
                                    Friend
------------------------------------------------------------------------------*/
-- Get list of user friends
CREATE OR REPLACE FUNCTION common.get_friends(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            CASE user_id1 WHEN _id THEN user_id2 ELSE user_id1 END
            FROM common.friend
            WHERE (user_id1 = _id OR user_id2 = _id) AND direction = 0
    );
END;
$$;

-- Outcoming friend requests
CREATE OR REPLACE FUNCTION common.get_outcoming_friend_requests(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            user_id2
        FROM common.friend
        WHERE user_id1 = _id AND direction = 1
    );
END;
$$;

-- Incoming friend requests
CREATE OR REPLACE FUNCTION common.get_incoming_friend_requests(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            user_id2
        FROM common.friend
        WHERE user_id2 = _id AND direction = 1
    );
END;
$$;
    
/*
--------------------------------------------------------------------------------
                                    Permissions
--------------------------------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION common.add_user_to_group (
    user_id   int,
    _group_id int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.user_to_group (
        user_id, 
        group_id
    )
    VALUES (
        user_id, 
        _group_id
    );
END;
$$;
    
-- TODO: check. doesn't seem to be right. 
CREATE OR REPLACE FUNCTION common.add_user_to_group (
    user_name text, 
    group_name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.user_to_group (
        user_id, 
        group_id
    )
    SELECT * FROM (
        SELECT id FROM common.user WHERE username = user_name
    ) AS t1, (
        SELECT id FROM common.group WHERE name = group_name
    ) AS t2;
END;
$$;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group (
    permission_id int, 
    group_id int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.permission_to_group (
        group_id, 
        permission_id
    ) VALUES (
        group_id,
        permission_id
    );
END;
$$;
    
-- CHECKME
CREATE OR REPLACE FUNCTION common.add_permission_to_group (
    permission_name text, 
    group_name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.permission_to_group (
        group_id, 
        permission_id
    )
    SELECT * FROM (
        SELECT id FROM common.group WHERE name = group_name
    ) AS t1, (
        SELECT id FROM common.permission WHERE code_name = permission_name
    ) AS t2;
END;
$$;
    
CREATE OR REPLACE FUNCTION common.get_all_permissions (
    id_user int
) RETURNS TABLE (LIKE common.permission) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.permission
    WHERE EXISTS (
        SELECT * FROM
            common.permission_to_group,
            common.user_to_group
        WHERE   common.permission_to_group.permission_id = common.permission.id
            AND common.permission_to_group.group_id      = common.user_to_group.group_id
            AND common.user_to_group.user_id             = id_user);
END;
$$;

/*
--------------------------------------------------------------------------------
                                    Room
--------------------------------------------------------------------------------
*/

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

/*------------------------------------------------------------------------------
                                    Game editor
------------------------------------------------------------------------------*/

-- Change title
CREATE OR REPLACE PROCEDURE game.set_game_name(
    game_id  bigint,
    new_name text
) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.game
        SET name = new_name
        WHERE id = game_id;
    IF NOT FOUND THEN
        RAISE 'Game % not found', game_id;
    END IF;
END;
$$;

-- Add a trait
CREATE OR REPLACE FUNCTION game.add_trait(
        g_id       bigint,
        trait_name text,
    OUT ret_id     bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.trait (
        game_id, 
        name
    )
    VALUES (
        g_id, 
        trait_name
    )
    RETURNING id INTO ret_id;
    IF NOT FOUND THEN
        RAISE 'Could not insert Game (..., %, %)', game_id, name;
    END IF;
END;
$$;

-- Delete a trait
CREATE OR REPLACE PROCEDURE game.rm_trait(
    g_id bigint
) LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.trait
        WHERE id = g_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Game % not found', g_id;
    END IF;
END;
$$;

-- Create a local map


-- Add a local map
/*
Requires DB restructuring:
    - Create Room / GameSession table
    - Take out some functionality of Game, assign it to GameSession
*/
CREATE OR REPLACE FUNCTION game.add_map(
            map_id       bigint,
            x            integer,
            y            integer,
            preview_link text,
            pattern      integer,
        OUT ret_id       bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.map (
        id,
        map_id,
        map_copy_id,
        x,
        y,
        area_type_id
    )
    VALUES (
        (SELECT max(id) + 1 FROM game.area a WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id),
        map_id,
        map_copy_id,
        x,
        y,
        area_type_id
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not insert Area (%, %) of AreaType % for MapCopy %', x, y, area_type_id, map_copy_id;
    END IF;
END;
$$;


/*------------------------------------------------------------------------------
                                    Local map editor
------------------------------------------------------------------------------*/

-- Add a cell
CREATE OR REPLACE FUNCTION game.add_cell(
            map_id       bigint,
            map_copy_id  bigint,
            x            integer,
            y            integer,
            area_type_id bigint,
        OUT ret_id       bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.area (
        id,
        map_id,
        map_copy_id,
        x,
        y,
        area_type_id
    )
    VALUES (
        (SELECT max(id) + 1 FROM game.area a WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id),
        map_id,
        map_copy_id,
        x,
        y,
        area_type_id
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not insert Area (%, %) of AreaType % for MapCopy %', x, y, area_type_id, map_copy_id;
    END IF;
END;
$$;

-- Add a cell (area_type_name)
CREATE OR REPLACE FUNCTION game.add_cell(
            map_id         bigint,
            map_copy_id    bigint,
            x              integer,
            y              integer,
            area_type_name text,
        OUT ret_id         bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.area (
        id,
        map_id,
        map_copy_id,
        x,
        y,
        area_type_id
    )
    VALUES (
        (SELECT max(id) + 1 FROM game.area a WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id),
        map_id,
        map_copy_id,
        x,
        y,
        (SELECT id FROM game.area_type t WHERE t.name = area_type_name)
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not insert Area (%, %) of AreaType % for MapCopy %', x, y, area_type_name, map_copy_id;
    END IF;
END;
$$;

-- Update a cell
CREATE OR REPLACE FUNCTION game.update_cell(
            map_id       bigint,
            map_copy_id  bigint,
            cell_id      bigint,
            x            integer,
            y            integer,
            area_type_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.area a
    SET
        a.x = x,
        a.y = y,
        a.area_type_id = area_type_id
    WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id AND a.id = cell_id;

    IF NOT FOUND THEN
        RAISE 'Could not update Area (%, %) of AreaType % for MapCopy %', x, y, area_type_id, map_copy_id;
    END IF;
END;
$$;

-- Update a cell (with area_type_name)
CREATE OR REPLACE FUNCTION game.update_cell(
            map_id         bigint,
            map_copy_id    bigint,
            cell_id        bigint,
            x              integer,
            y              integer,
            area_type_name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.area a
    SET
        a.x = x,
        a.y = y,
        a.area_type_id = (SELECT id FROM game.area_type t WHERE t.name = area_type_name)
    WHERE   a.map_id = map_id
        AND a.map_copy_id = map_copy_id 
        AND a.id = cell_id;

    IF NOT FOUND THEN
        RAISE 'Could not update Area (%, %) of AreaType % for MapCopy %', x, y, area_type_name, map_copy_id;
    END IF;
END;
$$;
