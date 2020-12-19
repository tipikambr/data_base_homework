/*
--------------------------------------------------------------------------------
                                    Friend
--------------------------------------------------------------------------------
*/
-- 1.1
-- Get list of user friends
CREATE OR REPLACE FUNCTION common.get_friends(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                CASE user_id1 WHEN _id THEN user_id2 ELSE user_id1 END
                FROM common.friend
                WHERE (user_id1 = _id OR user_id2 = _id) AND direction = 0
        );

    $$
    LANGUAGE SQL;

-- 1.2
-- Outcoming friend requests
CREATE OR REPLACE FUNCTION common.get_outcoming_friend_requests(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                user_id2
                FROM common.friend
                WHERE user_id1 = _id AND direction = 1
            );

    $$
    LANGUAGE SQL;

-- 1.3
-- Incoming friend requests
CREATE OR REPLACE FUNCTION common.get_incoming_friend_requests(_id int) RETURNS TABLE (LIKE common.user)
    AS
    $$
    SELECT * FROM common.user u
        WHERE u.id IN (
            SELECT
                user_id2
                FROM common.friend
                WHERE user_id2 = _id AND direction = 1
            );

    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    Local map editor
--------------------------------------------------------------------------------
*/
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
