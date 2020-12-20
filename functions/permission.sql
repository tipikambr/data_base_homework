/*------------------------------------------------------------------------------
                                    Permissions
------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION common.add_user_to_group (
    user_id   int,
    _group_id int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.user_to_group (
        user_id, 
        group_id
    )
    VALUES (
        user_id, 
        _group_id
    );
END;
$$;
    
-- TODO: check. doesn't seem to be right. 
CREATE OR REPLACE FUNCTION common.add_user_to_group (
    user_name text, 
    group_name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.user_to_group (
        user_id, 
        group_id
    )
    SELECT * FROM (
        SELECT id FROM common.user WHERE username = user_name
    ) AS t1, (
        SELECT id FROM common.group WHERE name = group_name
    ) AS t2;
END;
$$;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group (
    permission_id int, 
    group_id int
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.permission_to_group (
        group_id, 
        permission_id
    ) VALUES (
        group_id,
        permission_id
    );
END;
$$;
    
-- CHECKME
CREATE OR REPLACE FUNCTION common.add_permission_to_group (
    permission_name text, 
    group_name text
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO common.permission_to_group (
        group_id, 
        permission_id
    )
    SELECT * FROM (
        SELECT id FROM common.group WHERE name = group_name
    ) AS t1, (
        SELECT id FROM common.permission WHERE code_name = permission_name
    ) AS t2;
END;
$$;
    
CREATE OR REPLACE FUNCTION common.get_all_permissions (
    id_user int
) RETURNS TABLE (LIKE common.permission) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.permission
    WHERE EXISTS (
        SELECT * FROM
            common.permission_to_group,
            common.user_to_group
        WHERE   common.permission_to_group.permission_id = common.permission.id
            AND common.permission_to_group.group_id      = common.user_to_group.group_id
            AND common.user_to_group.user_id             = id_user);
END;
$$;
