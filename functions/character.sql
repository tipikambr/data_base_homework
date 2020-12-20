/*------------------------------------------------------------------------------
                                    Character
------------------------------------------------------------------------------*/

-- List of player characters in game session
CREATE OR REPLACE FUNCTION game.get_characters_in_session (
    user_id int,
    session_id bigint
) RETURNS TABLE (LIKE game.character) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * 
    FROM game.character c
    WHERE c.session_id = session_id AND c.user_id = user_id;
END;
$$;

-- Create character
CREATE OR REPLACE FUNCTION game.create_character (
    user_id      int,
    session_id   bigint,
    _name        text,
    _avatar_link text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.character (
        session_id,
        user_id,
        name,
        avatar_link
    ) VALUES (
        session_id,
        user_id,
        _name,
        _avatar_link
    );
END;
$$;

-- Change character avatar
CREATE OR REPLACE FUNCTION game.change_character_avatar(
    _id         int,
    avatar_link text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.character c
    SET    c.avatar_link = avatar_link
    WHERE  id = _id;
END;
$$;

-- Change character name
CREATE OR REPLACE FUNCTION game.change_character_name(
    _id   int,
    name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.character c
    SET    c.name = name
    WHERE  c.id   = _id;
END;
$$;

CREATE OR REPLACE FUNCTION game.get_character(
    session_id bigint,
    id_user integer
) RETURNS TABLE (LIKE game.character) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.character c
    WHERE c.session_id = session_id
      AND c.user_id    = id_user;
END;
$$;

CREATE OR REPLACE FUNCTION game.get_characters(
    session_id BIGINT
) RETURNS TABLE (LIKE game.character) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.character c
    WHERE c.session_id = session_id;
END;
$$;

CREATE OR REPLACE FUNCTION game.set_character_trait(
    id_character BIGINT,
    id_trait BIGINT,
    value_trait int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE game.trait_value
    SET value = value_trait
    WHERE trait_id     = id_trait
      AND character_id = id_character;
END;
$$;

CREATE OR REPLACE FUNCTION game.add_character_trait(
    id_character BIGINT, 
    id_trait BIGINT, 
    value_trait int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.trait_value (
        character_id,
        trait_id,
        value
    ) VALUES (
        id_character,
        id_trait,
        value_trait
    );
END;
$$;

CREATE OR REPLACE FUNCTION game.remove_character_trait(
    id_character BIGINT,
    id_trait BIGINT
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.trait_value
    WHERE character_id = id_character
      AND trait_id     = id_trait;
END;
$$;

CREATE OR REPLACE FUNCTION game.get_character_traits(
    id_character bigint
) RETURNS TABLE(
    trait_id    bigint,
    trait_name  text,
    trait_value INT
) LANGUAGE plpgsql AS $$
BEGIN
    SELECT
        tt.id AS trait_id,
        tt.name AS trait_name, 
        tv.value AS trait_value
    FROM game.trait_value AS tv,
         game.trait AS tt
    WHERE tv.character_id = id_character
      AND tv.trait_id     = tt.id;
END;
$$;
