/*------------------------------------------------------------------------------
                                    Game
------------------------------------------------------------------------------*/

-- Create game
CREATE OR REPLACE FUNCTION game.create_game(
        owner        int,
        _name        text,
        -- TODO: enum {'closed', 'open', 'pending deleting'}
        _status      bool, -- is open for search
        _description text,
    OUT ret_id       bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.game (
        name,
        description,
        status,
        owner_id
    ) VALUES (
        _name,
        _description,
        _status,
        owner
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not create a game - %, owner:%', name, owner;
    END IF;
END;
$$;

-- Change title and description
CREATE OR REPLACE PROCEDURE game.set_game_name(
    game_id         bigint,
    new_name        text,
    new_description text
) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.game
        SET name        = new_name,
            description = new_description
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

-- Create a map
CREATE OR REPLACE FUNCTION game.create_map(
        name         text,
        description  text,
        preview_link text,
        x            integer,   -- position on the global map
        y            integer,   -- position on the global map
        pattern      integer,   -- cell shape (e.g. 6 for hexagone)
    OUT ret_id       bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.map (
        name,
        description,
        preview_link,
        x, 
        y,
        pattern
    ) VALUES (
        name,
        description,
        preview_link,
        x,
        y,
        pattern
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not create Map %', name;
    END IF;
END;
$$;

-- Add map to Game
CREATE OR REPLACE FUNCTION game.create_map(
    _game_id bigint,
    _map_id  bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.game_to_map (
        game_id,
        map_id
    ) VALUES (
        _game_id,
        _map_id
    );

    IF NOT FOUND THEN
        RAISE 'Could not add Map % to Game %', _map_id, _game_id;
    END IF;
END;
$$;

-- TODO: trigger on DELETE from game.map to make dependant MapCopy objects safe

-- Delete a map
CREATE OR REPLACE FUNCTION game.delete_map(
    map_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
/*
Assuming deleting is safe - all dependencies in MapCopy entities resolved.
(this is implemented with a trigger on DELETE)
Otherwise this function shouldn't be invoked
*/
BEGIN
    DELETE FROM game.map
    WHERE id = map_id; 
    -- All the minor objects are removed with ON DELETE CASCADE

    IF NOT FOUND THEN
        RAISE 'Could not delete Map %', map_id;
    END IF;
END;
$$;

-- Add a Long link (a link between maps)
CREATE OR REPLACE FUNCTION game.create_long_link (
    from_id bigint,
    to_id   bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.map (
        from_id,
        to_id
    ) VALUES (
        from_id,
        to_id
    );

    IF NOT FOUND THEN
        RAISE 'Could not create Long Link % -> %', from_id, to_id;
    END IF;
END;
$$;

-- Delete a Long link (a link between maps)
CREATE OR REPLACE FUNCTION game.delete_long_link(
    from_id bigint,
    to_id   bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.link_long l
    WHERE from_id = l.from_map_id
      AND to_id   = l.to_map_id;
    -- All the minor objects are removed with ON DELETE CASCADE

    IF NOT FOUND THEN
        RAISE 'Could not delete Long Link % -> %', from_id, to_id;
    END IF;
END;
$$;

-- Get local maps
CREATE OR REPLACE FUNCTION game.get_local_maps(
        game_id bigint
) RETURNS TABLE (LIKE game.map) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.map.*
    FROM game.map m
    INNER JOIN game.game_to_map g
        ON g.map_id = m.id
    WHERE g.id = game_id;
END;
$$;
