/*
	Date: 2026/06/26
	Desc: Query plan statistics
*/

;with [Data]
as
(
	SELECT TOP 50
		q.query_hash,
		count(*) as [Plan Count],
		MIN(q.creation_time) as [Cached Time],
		MAX(q.last_execution_time) as [Last Exec Time],
		SUM(q.execution_count) as [Exec Cnt],
		SUM(q.total_logical_reads) as [Total Reads],
		SUM(q.total_logical_writes) as [Total Writes],
		SUM(q.total_worker_time / 1000) as [Total Worker Time],
		SUM(q.total_elapsed_time / 1000) as [Total Elapsed Time],
		SUM(q.total_rows) as [Total Rows],
		SUM(q.total_physical_reads) as [Total Physical Reads],
		SUM(q.total_grant_kb) as [Total Grant KB],
		SUM(q.total_used_grant_kb) as [Total Used Grant KB],
		SUM(q.total_ideal_grant_kb) as [Total Ideal Grant KB],
		SUM(q.total_columnstore_segment_reads) as [Total CSI Segments Read],
		MAX(q.[max_dop]) as [Max DOP],
		SUM(q.total_spills) as [Total Spills]
	FROM
		sys.dm_exec_query_stats as q with (NOLOCK)
	GROUP BY
		q.query_hash
	ORDER BY
		SUM((q.total_logical_reads + q.total_logical_writes) / q.execution_count) DESC
)
SELECT 
	d.[Cached Time],
	d.[Last Exec Time],
	d.[Plan Count],
	p.[SQL],
	p.[Query Plan],
	d.[Exec Cnt],
	convert(decimal(10,5),IIF(datediff(second,d.[Cached Time], d.[Last Exec Time]) = 0, NULL, 1.0 * d.[Exec Cnt]/datediff(second,d.[Cached Time], d.[Last Exec Time]))) as [Exec Per Second],
	(d.[Total Reads] + d.[Total Writes]) / d.[Exec Cnt] as [Avg IO],
	(d.[Total Worker Time] / d.[Exec Cnt] / 1000) as [Avg CPU(ms)],
	d.[Total Reads],
	d.[Total Writes],
	d.[Total Worker Time],
	d.[Total Elapsed Time],
	d.[Total Rows],
	d.[Total Rows] / d.[Exec Cnt] as [Avg Rows],
	d.[Total Physical Reads],
	d.[Total Physical Reads] / d.[Exec Cnt] as [Avg Physical Reads],
	d.[Total Grant KB],
	d.[Total Grant KB] / d.[Exec Cnt] as [Avg Grant KB],
	d.[Total Used Grant KB],
	d.[Total Used Grant KB] / d.[Exec Cnt] as [Avg Used Grant KB],
	d.[Total Ideal Grant KB],
	d.[Total Ideal Grant KB] / d.[Exec Cnt] as [Avg Ideal Grant KB],
	d.[Total CSI Segments Read],
	d.[Total CSI Segments Read] / d.[Exec Cnt] as [AVG CSI Segments Read],
	d.[Max DOP],
	d.[Total Spills],
	d.[Total Spills] / d.[Exec Cnt] as [Avg Spills]
FROM 
	[Data] as d
	CROSS APPLY
	(
		SELECT TOP 1
			SUBSTRING(
				t.text,
				(q.statement_start_offset/2)+1,
				((CASE q.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE q.statement_end_offset END - q.statement_start_offset)/2)+1
			) as [SQL],
			TRY_CONVERT(XML,p.query_plan) as [Query Plan]
		FROM
			sys.dm_exec_query_stats as q
			OUTER APPLY sys.dm_exec_sql_text(q.sql_handle) as t
			OUTER APPLY sys.dm_exec_text_query_plan(q.plan_handle,q.statement_start_offset,q.statement_end_offset) as p
		WHERE
			q.query_hash = d.query_hash and
			ISNULL(t.text,'') <> ''
	) as p
ORDER BY
	[Avg IO] DESC
OPTION (RECOMPILE,MAXDOP 1);