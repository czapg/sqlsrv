/*
	Create_Date: 2026/06/24
	Desc: Last Active Sessions
*/

;with UserSessions as
(
	SELECT
		db_name(s.database_id) as DatabaseName,
		s.login_name,
		s.last_request_end_time,
		ROW_NUMBER() OVER
		(
			PARTITION BY DB_NAME(s.database_id), s.login_name
			ORDER BY s.last_request_end_time DESC
		) as rn
	FROM
		sys.dm_exec_sessions as s
	WHERE
		s.is_user_process = 1 and
		s.database_id > 4 and
		s.login_name is not null
)
SELECT
	DatabaseName,
	login_name,
	last_request_end_time as LastActivity
FROM
	UserSessions as u
WHERE
	u.rn = 1
ORDER BY
	last_request_end_time DESC