/*------------------------------------------------------------------------------
                                    Game session
------------------------------------------------------------------------------*/

-- Delete game session
CREATE OR REPLACE FUNCTION game.delete_game_session(
    session_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.object
    WHERE area_id IN (
        SELECT id 
        FROM game.area
        WHERE map_copy_id IN (
            SELECT id
            FROM game.map_copy c
            WHERE c.session_id = session_id
        )
    );
        
    DELETE FROM game.link_short
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
                FROM game.map_copy c
                WHERE c.game_id = session_id
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
            FROM game.map_copy c
            WHERE c.session_id = session_id
        )
    );
    
    DELETE FROM game.game_session s
    WHERE  s.id = session_id;
END;
$$;

-- List of players in game
CREATE OR REPLACE FUNCTION game.get_players_in_session(
    session_id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT user_id
        FROM common.participant p
        WHERE p.session_id = session_id
    );
END;
$$;

-- Connect to session
CREATE OR REPLACE FUNCTION game.user_connect_to_session (
    u_id int,
    s_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.participant (
        session_id,
        user_id
    ) VALUES (
        s_id,
        u_id
    );
END;
$$;
