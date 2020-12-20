/*------------------------------------------------------------------------------
                                    Map
------------------------------------------------------------------------------*/

-- Add a cell
CREATE OR REPLACE FUNCTION game.add_cell (
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
CREATE OR REPLACE FUNCTION game.add_cell (
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
CREATE OR REPLACE FUNCTION game.update_cell (
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
    WHERE a.map_id      = map_id
      AND a.map_copy_id = map_copy_id
      AND a.id          = cell_id;

    IF NOT FOUND THEN
        RAISE 'Could not update Area (%, %) of AreaType % for MapCopy %', x, y, area_type_id, map_copy_id;
    END IF;
END;
$$;

-- Update a cell (with area_type_name)
CREATE OR REPLACE FUNCTION game.update_cell (
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

-- Get local map
CREATE OR REPLACE FUNCTION game.get_local_map (
        _map_id bigint
) RETURNS TABLE (LIKE game.map) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.map.*
    FROM game.map m
    WHERE m.id = _map_id;
END;
$$;

-- Get all cells for a local map
CREATE OR REPLACE FUNCTION game.get_map_cells (
    _map_id bigint
) RETURNS TABLE (LIKE game.area) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.area.*
    FROM game.area a
    WHERE a.map_id = _map_id AND a.map_copy_id IS NULL;
END;
$$;

-- get all cells for a local map copy (copy exclusive)
CREATE OR REPLACE FUNCTION game.get_map_copy_cells (
    map_id      bigint,
    map_copy_id bigint
) RETURNS TABLE (LIKE game.area) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.area.*
    FROM game.area a
    WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id;
END;
$$;

-- get all cells for a local map copy (original + copy override by (x,y))
CREATE OR REPLACE FUNCTION game.get_map_copy_cells (
    map_id      bigint,
    map_copy_id bigint
) RETURNS TABLE (LIKE game.area) LANGUAGE plpgsql AS $$
BEGIN
    WITH overriden_areas AS (
        SELECT *
        FROM game.area a
        WHERE a.map_id = map_id AND a.map_copy_id = map_copy_id
    )
    SELECT
        (CASE WHEN overriden_areas.id IS NULL THEN ar.* ELSE overriden_areas.* END)
    FROM game.area ar
    FULL OUTER JOIN overriden_areas
        ON ar.x = overriden_areas.x AND ar.y = overriden_areas.y
    WHERE ar.map_id = map_id AND ar.map_copy_id IS NULL;
END;
$$;


-- Add a Short link (a link between cells)
CREATE OR REPLACE FUNCTION game.create_short_link (
	_from_area_id     bigint,
    _from_map_id      bigint,
    _from_map_copy_id bigint,
	_to_area_id       bigint,
    _to_map_id        bigint,
    _to_map_copy_id   bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.map (
        from_area_id,
        from_map_id,
        from_map_copy_id,
        to_area_id,
        to_map_id,
        to_map_copy_id
    ) VALUES (
        _from_area_id,
        _from_map_id,
        _from_map_copy_id,
        _to_area_id,
        _to_map_id,
        _to_map_copy_id
    );

    IF NOT FOUND THEN
        RAISE 'Could not create Long Link % -> %', from_id, to_id;
    END IF;
END;
$$;

-- Delete a Short link (a link between cells)
CREATE OR REPLACE FUNCTION game.delete_short_link (
	_from_area_id     bigint,
    _from_map_id      bigint,
    _from_map_copy_id bigint,
	_to_area_id       bigint,
    _to_map_id        bigint,
    _to_map_copy_id   bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.link_short l
    WHERE
            l.from_area_id     = _from_area_id
        AND l.from_map_id      = _from_map_id
        AND l.from_map_copy_id = _from_map_copy_id
        AND l.to_area_id       = _to_area_id
        AND l.to_map_id        = _to_map_id
        AND l.to_map_copy_id   = _to_map_copy_id;

    IF NOT FOUND THEN
        RAISE 'Could not delete Long Link % -> %', from_id, to_id;
    END IF;
END;
$$;

-- Get all Short Links for a map
CREATE OR REPLACE FUNCTION game.get_map_short_links (
        _map_id bigint
) RETURNS TABLE (LIKE game.link_short) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.link_short l
    WHERE l.map_id = _map_id;
END;
$$;

-- Add an object for a cell
CREATE OR REPLACE FUNCTION game.add_object (
            map_id         bigint,
            map_copy_id    bigint,
            area_id        bigint,
            object_type_id integer,
            orientation    float,
        OUT ret_id         bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.object (
        object_type_id,
        area_id,
        map_id,
        map_copy_id,
        orientation
    )
    VALUES (
        object_type_id,
        area_id,
        map_id,
        map_copy_id,
        orientation
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not create an Object of Type % for Area (%,%,%)',
            object_type_id, map_id, map_copy_id, area_id;
    END IF;
END;
$$;

-- Delete an object
CREATE OR REPLACE FUNCTION game.delete_short_link (
    object_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.object o
    WHERE o.id = object_id;

    IF NOT FOUND THEN
        RAISE 'Could not delete Object %', object_id;
    END IF;
END;
$$;

-- Get all Objects for a map
CREATE OR REPLACE FUNCTION game.get_map_objects (
        _map_id bigint
) RETURNS TABLE (LIKE game.object) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.object o
    WHERE o.map_id = _map_id;
END;
$$;

-- TODO: CRUD item

-- Add a Dropped Item
CREATE OR REPLACE FUNCTION game.add_dropped_item (
            map_id      bigint,
            map_copy_id bigint,
            area_id     bigint,
            item_id     bigint,
            orientation float,
        OUT ret_id      bigint
) LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO game.dropped_item (
        item_id,
        map_id,
        map_copy_id,
        area_id
    )
    VALUES (
        object_type_id,
        map_id,
        map_copy_id,
        area_id
    )
    RETURNING id INTO ret_id;

    IF NOT FOUND THEN
        RAISE 'Could not create a Dropped Item for Item % for Area (%,%,%)',
            item_id, map_id, map_copy_id, area_id;
    END IF;
END;
$$;

-- Delete a Dropped Item
CREATE OR REPLACE FUNCTION game.delete_dropped_item (
    d_item_id bigint
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM game.dropped_item i
    WHERE i.id = d_item_id;

    IF NOT FOUND THEN
        RAISE 'Could not delete Dropped Item %', d_item_id;
    END IF;
END;
$$;

-- Get all dropped items on map
CREATE OR REPLACE FUNCTION game.get_map_dropped_items (
        _map_id bigint
) RETURNS TABLE (LIKE game.dropped_item) LANGUAGE plpgsql AS $$
BEGIN
    SELECT *
    FROM game.dropped_item i
    WHERE i.map_id = _map_id;
END;
$$;
