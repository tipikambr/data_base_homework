/*------------------------------------------------------------------------------
                                    Item
------------------------------------------------------------------------------*/

-- Create item
CREATE OR REPLACE FUNCTION game.create_item (
        name         text,
        description  text,
        effect_array jsonb,
    OUT ret_id       bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.item (
        name,
        description,
        effect_array
    ) VALUES (
        name,
        description,
        effect_array
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not create an Item - %, %', name, description;
    END IF;
END;
$$;

-- Delete item
CREATE OR REPLACE PROCEDURE game.delete_item (
    item_id bigint
) LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.item
        WHERE id = item_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item % not found', item_id;
    END IF;
END;
$$;

-- Update item
CREATE OR REPLACE PROCEDURE game.update_item (
    item_id      bigint,
    name         text,
    description  text,
    effect_array jsonb
) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.item i
        SET i.name         = name,
            i.description  = description,
            i.effect_array = effect_array
        WHERE id = item_id;
    IF NOT FOUND THEN
        RAISE 'Item % not found', item_id;
    END IF;
END;
$$;

-- Get item
CREATE OR REPLACE FUNCTION game.get_item (
        item_id bigint
) RETURNS TABLE (LIKE game.item) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.item i
    WHERE i.id = item_id;
END;
$$;

-- Get items allowed in a game
CREATE OR REPLACE FUNCTION game.get_allowed_items (
        game_id bigint
) RETURNS TABLE (LIKE game.item) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.item.*
    FROM game.item i
    INNER JOIN game.allowed_items ai
        ON ai.item_id = i.id
    WHERE ai.game_id = game_id;
END;
$$;

-- Add item to a game
CREATE OR REPLACE FUNCTION game.add_item_to_game(
        item_id bigint,
        game_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.allowed_items (
        item_id,
        game_id
    ) VALUES (
        game_id,
        item_id
    );

    IF NOT FOUND THEN
        RAISE 'Could not add an Item % to Game %', item_id, game_id;
    END IF;
END;
$$;

-- Delete an item from a game
CREATE OR REPLACE PROCEDURE game.disallow_item (
    item_id bigint,
    game_id bigint
) LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.allowed_items ai
        WHERE ai.game_id = game_id AND ai.item_id = item_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item % not found in allowed items for Game %', item_id, game_id;
    END IF;
END;
$$;
