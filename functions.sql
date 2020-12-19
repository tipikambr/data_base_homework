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
                                    Permissions
--------------------------------------------------------------------------------
*/

CREATE OR REPLACE FUNCTION common.add_user_to_group(user_id int, group_id int) RETURNS VOID
    AS
    $$
        INSERT INTO common.user_to_group (user_id, group_id) VALUES
            (user_id, group_id);
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_user_to_group(user_name TEXT, group_name TEXT) RETURNS VOID
    AS
    $$
        INSERT INTO common.user_to_group (user_id, group_id)
        SELECT * FROM
            (SELECT id FROM common.user WHERE username = user_name) AS t1,
             (SELECT id FROM common.group WHERE name = group_name) AS t2;
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group(permission_id int, group_id int) RETURNS VOID
    AS
    $$
        INSERT INTO common.permission_to_group (group_id, permission_id) VALUES
            (group_id, permission_id);
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.add_permission_to_group(permission_name TEXT, group_name TEXT) RETURNS VOID
    AS
    $$
        INSERT INTO common.permission_to_group (group_id, permission_id)
            SELECT * FROM
                (SELECT id FROM common.group WHERE name = group_name) AS t1,
                (SELECT id FROM common.permission WHERE code_name = permission_name) AS t2;
    $$
    LANGUAGE SQL;
    
CREATE OR REPLACE FUNCTION common.get_all_permissions(id_user int) RETURNS TABLE (LIKE common.permission)
    AS
    $$
        SELECT * FROM common.permission WHERE
            EXISTS (SELECT * FROM common.permission_to_group, common.user_to_group
                   WHERE common.permission_to_group.permission_id = common.permission.id AND
                   common.permission_to_group.group_id = common.user_to_group.group_id AND
                   common.user_to_group.user_id = id_user);
    $$
    LANGUAGE SQL;

/*
--------------------------------------------------------------------------------
                                    Friend
--------------------------------------------------------------------------------
*/
