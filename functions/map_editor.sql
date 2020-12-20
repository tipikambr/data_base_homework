/*------------------------------------------------------------------------------
                                    Local map editor
------------------------------------------------------------------------------*/

-- Add a cell
CREATE OR REPLACE FUNCTION game.add_cell(
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
CREATE OR REPLACE FUNCTION game.add_cell(
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
CREATE OR REPLACE FUNCTION game.update_cell(
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
CREATE OR REPLACE FUNCTION game.update_cell(
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
CREATE OR REPLACE FUNCTION game.get_local_map(
        _map_id bigint
) RETURNS TABLE (LIKE game.map) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.map.*
    FROM game.map m
    WHERE m.id = _map_id;
END;
$$;

-- Get all cells for a local map
CREATE OR REPLACE FUNCTION game.get_local_map_cells(
        _map_id bigint
) RETURNS TABLE (LIKE game.area) LANGUAGE plpgsql AS $$
BEGIN
    SELECT game.area.*
    FROM game.area a
    WHERE a.map_id = _map_id;
END;
$$;

-- TODO: get all cells for a local map copy (copy exclusive)
-- TODO: get all cells for a local map copy (original + copy override by (x,y))
-- TODO: add object to a cell
-- TODO: short links

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

/*
-- Delete a Short link (a link between cells)
CREATE OR REPLACE FUNCTION game.delete_short_link(
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
        l.from_area_id = _from_area_id,
        l.from_map_id = ,
        l.from_map_copy_id,
        l.to_area_id,
        l.to_map_id,
        l.to_map_copy_id
      AND to_id   = l.to_map_id;
    -- All the minor objects are removed with ON DELETE CASCADE

    IF NOT FOUND THEN
        RAISE 'Could not delete Long Link % -> %', from_id, to_id;
    END IF;
END;
$$;
*/
