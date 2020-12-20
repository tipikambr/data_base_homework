/*------------------------------------------------------------------------------
                                    Friend
------------------------------------------------------------------------------*/
-- Get list of user friends
CREATE OR REPLACE FUNCTION common.get_friends(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            CASE user_id1 WHEN _id THEN user_id2 ELSE user_id1 END
            FROM common.friend
            WHERE (user_id1 = _id OR user_id2 = _id) AND direction = 0
    );
END;
$$;

-- Outcoming friend requests
CREATE OR REPLACE FUNCTION common.get_outcoming_friend_requests(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            user_id2
        FROM common.friend
        WHERE user_id1 = _id AND direction = 1
    );
END;
$$;

-- Incoming friend requests
CREATE OR REPLACE FUNCTION common.get_incoming_friend_requests(
    _id int
) RETURNS TABLE (LIKE common.user) LANGUAGE plpgsql AS $$
BEGIN
    SELECT * FROM common.user u
    WHERE u.id IN (
        SELECT
            user_id2
        FROM common.friend
        WHERE user_id2 = _id AND direction = 1
    );
END;
$$;
    
