/*------------------------------------------------------------------------------
                                    Character view edit
------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION game.get_character(session_id BIGINT, id_user INTEGER) RETURNS TABLE (LIKE game.character)
    AS
    $$
        SELECT * FROM game.character
            WHERE game.character.session_id = session_id AND game.character.user_id = id_user;
    $$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION game.get_characters(session_id BIGINT) RETURNS TABLE (LIKE game.character)
    AS
    $$
        SELECT * FROM game.character
            WHERE game.character.session_id = session_id;
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
