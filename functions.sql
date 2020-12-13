-- 1.1
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
-- TODO
