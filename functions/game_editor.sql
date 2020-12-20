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
