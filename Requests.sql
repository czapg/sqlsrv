/*
	Create_Date: 2026/06/23
	Desc: Current CPU Intensive Task, Connection Data Details.
*/

SELECT
	er.[session_id],
	er.[request_id],
	DB_NAME(er.database_id) as [database],
	er.[start_time],
	CONVERT(decimal(21,3),er.total_elapsed_time / 1000.00) as [duration],
	er.[cpu_time],
	substring
	(	qt.text,
		(er.statement_start_offset/2)+1,
		((CASE er.statement_end_offset WHEN -1 THEN DATALENGTH(qt.[text]) ELSE er.statement_end_offset END - er.statement_start_offset)/2)+1
	) as [statement],
	er.[status],
	er.[wait_type],
	er.[wait_time],
	er.[wait_resource],
	er.blocking_session_id,
	er.last_wait_type,
	er.reads,
	er.logical_reads,
	er.writes,
	er.granted_query_memory,
	er.dop,
	er.row_count,
	er.percent_complete,
	es.login_time,
	es.original_login_name,
	es.[host_name],
	es.[program_name],
	c.client_net_address,
	ib.event_info as [buffer],
	qt.[text] as [sql],
	TRY_CONVERT(XML,p.[query_plan]) as [query_plan]
FROM
	sys.dm_exec_requests as er WITH (NOLOCK)
	OUTER APPLY sys.dm_exec_input_buffer(er.[session_id], er.request_id) as ib
	OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt
	OUTER APPLY sys.dm_exec_text_query_plan(er.plan_handle,er.statement_start_offset,er.statement_end_offset) as p
	LEFT JOIN sys.dm_exec_connections as c WITH (NOLOCK) ON er.[session_id] = c.[session_id]
	LEFT JOIN sys.dm_exec_sessions as es WITH (NOLOCK) on er.[session_id] = es.[session_id]
WHERE
	er.[status] <> 'background' and
	er.[session_id] > 50
ORDER BY
	er.cpu_time desc
OPTION (RECOMPILE,MAXDOP 1);