/*
	Create_Date: 2026/06/23
	Desc: List of the most important types of wait in SQL Server. Analysis of waiting statistics.
*/

;WITH Waits
AS
(
	SELECT
		wait_type,
		wait_time_ms,
		waiting_tasks_count,
		signal_wait_time_ms,
		wait_time_ms - signal_wait_time_ms as resource_wait_time_ms,
		100.00 * wait_time_ms / SUM(wait_time_ms) OVER() as Pct,
		100.00 * SUM(wait_time_ms) OVER(ORDER BY wait_time_ms DESC) / NULLIF(SUM(wait_time_ms) OVER(),0) as RunningPct,
		ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) as RowNum
	FROM
		sys.dm_os_wait_stats with (NOLOCK)
	WHERE
		-- odfiltrowanie mniej waznych statystyk oczekiwania
		wait_type NOT IN
		(
			N'BROKER_EVENTHANDLER',N'BROKER_RECEIVE_WAITFOR',N'BROKER_TASK_STOP',N'BROKER_TO_FLUSH',
			N'BROKER_TRANSMITTER',N'CHECKPOINT_QUEUE',N'CHKPT',N'CLR_SEMAPHORE',N'CLR_AUTO_EVENT',
			N'CLR_MANUAL_EVENT',N'DBMIRROR_DBM_EVENT',N'DBMIRROR_EVENTS_QUEUE',N'DBMIRROR_WORKER_QUEUE',
			N'DBMIRRORING_CMD',N'DIRTY_PAGE_POLL',N'DISPATCHER_QUEUE_SEMAPHORE',N'EXECSYNC',N'FSAGENT',
			N'FT_IFTS_SCHEDULER_IDLE_WAIT',N'FT_IFTSHC_MUTEX',N'HADR_CLUSAPI_CALL',N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
			N'HADR_LOGCAPTURE_WAIT',N'HADR_NOTIFICATION_DEQUEUE',N'HADR_TIMER_TASK',N'HADR_WORK_QUEUE',
			N'KSOURCE_WAKEUP',N'LAZYWRITER_SLEEP',N'LOGMGR_QUEUE',N'ONDEMAND_TASK_QUEUE',N'PARALLEL_REDO_WORKER_WAIT_WORK',
			N'PARALLEL_REDO_DRAIN_WORKER',N'PARALLEL_REDO_LOG_CACHE',N'PARALLEL_REDO_TRAN_LIST',N'PARALLEL_REDO_WORKER_SYNC',
			N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',N'PREEMPTIVE_OS_LIBRARYOPS',N'PREEMPTIVE_OS_COMOPS',
			N'PREEMPTIVE_OS_PIPEOPS','PREEMPTIVE_OS_GENERICOPS','PREEMPTIVE_OS_VERIFYTRUST','PREEMPTIVE_OS_FILEOPS',
			N'PREEMPTIVE_OS_DEVICE_OPS',N'PREEMPTIVE_OS_QUERYREGISTRY',N'PREEMPTIVE_XE_CALLBACKEXECUTE',
			N'PREEMPTIVE_XE_DISPATCHER',N'PREEMPTIVE_XE_GETTARGETSTATE',N'PREEMPTIVE_XE_SESSIONCOMMIT',
			N'PREEMPTIVE_XE_TARGETINIT',N'PREEMPTIVE_XE_TARGETFINALIZE',N'PWAIT_ALL_COMPONENTS_INITIALIZED',
			N'PWAIT-_DIRECTLOGCONSUMER_GETNEXT',N'PWAIT_EXTENSIBILITY_CLEANUP_TASK'

		)
)
SELECT
	w.wait_type as [Wait_Type],
	w.waiting_tasks_count as [Wait Count],
	CONVERT(decimal(12,3), w.wait_time_ms / 1000.00) as [Wait Time],
	CONVERT(decimal(12,1), w.wait_time_ms / w.waiting_tasks_count) as [AVG Wait Time],
	CONVERT(decimal(12,3), w.signal_wait_time_ms / 1000.00) as [Signal Wait Time],
	CONVERT(decimal(12,1), w.signal_wait_time_ms / w.waiting_tasks_count) as [AVG Signal Wait Time],
	CONVERT(decimal(12,3), w.resource_wait_time_ms / 1000.00) as [Resouce Wait Time],
	CONVERT(decimal(12,1), w.resource_wait_time_ms / w.waiting_tasks_count) as [AVG Resource Wait Time],
	CONVERT(decimal(6,3), w.Pct) as [Percent],
	CONVERT(decimal(6,3), w.RunningPct) as [Running Percent]
FROM
	Waits as w
WHERE
	w.RunningPct <=99 OR w.RowNum = 1
ORDER BY
	w.RunningPct ASC
OPTION (RECOMPILE, MAXDOP 1);
