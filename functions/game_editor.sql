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
