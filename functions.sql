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

/*------------------------------------------------------------------------------
                                    Game editor
------------------------------------------------------------------------------*/

-- Change title
CREATE OR REPLACE PROCEDURE game.set_game_name(
    game_id  BIGINT,
    new_name TEXT
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
        g_id       BIGINT,
        trait_name TEXT,
    OUT ret_id     BIGINT
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
    g_id BIGINT
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
            map_id       BIGINT,
            x            INTEGER,
            y            INTEGER,
            preview_link TEXT,
            pattern      INTEGER
        OUT ret_id       BIGINT
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
            map_id       BIGINT,
            map_copy_id  BIGINT,
            x            INTEGER,
            y            INTEGER,
            area_type_id BIGINT,
        OUT ret_id       BIGINT
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
            map_id         BIGINT,
            map_copy_id    BIGINT,
            x              INTEGER,
            y              INTEGER,
            area_type_name TEXT,
        OUT ret_id         BIGINT
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
            map_id       BIGINT,
            map_copy_id  BIGINT,
            cell_id      BIGINT,
            x            INTEGER,
            y            INTEGER,
            area_type_id BIGINT
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
            map_id         BIGINT,
            map_copy_id    BIGINT,
            cell_id        BIGINT,
            x              INTEGER,
            y              INTEGER,
            area_type_name TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.area a
    SET
        a.x = x,
        a.y = y,
        a.area_type_id = (SELECT id FROM game.area_type t WHERE t.name = area_type_name)
    WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id AND a.id = cell_id;

    IF NOT FOUND THEN
        RAISE 'Could not update Area (%, %) of AreaType % for MapCopy %', x, y, area_type_name, map_copy_id;
    END IF;
END;
$$;
