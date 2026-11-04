
CREATE PROCEDURE [dbo].[usp_Utility_UpdateProcessingLog]
	@StoredProcedureName varchar(100)
	,@StoredProcedureParameters varchar(100) = NULL
	,@StartTime datetime

AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@EndTime datetime
	,@InitSeconds int
	,@h int, @m int, @s int

SET @EndTime = GETUTCDATE()
SET @InitSeconds = DATEDIFF(SECOND,@StartTime,@EndTime)
SET @h = (@InitSeconds/3600)
SET @m = (@InitSeconds-floor(@h*3600))/60
SET @s = (@InitSeconds-floor(@h*3600)-floor(@m*60))

INSERT
	dbo.ProcessingLog
(
	ProcedureName
	,ProcedureParameters
	,StartTime
	,EndTime
	,RunTime
)
SELECT
	@StoredProcedureName
	,@StoredProcedureParameters
	,@StartTime
	,@EndTime
	,RIGHT('0'+CONVERT(varchar,@h),2) + ':' +
		RIGHT('0'+CONVERT(varchar,@m),2) + ':' +
		RIGHT('0'+CONVERT(varchar,@s),2)

/******************************************************************************
	end procedure
******************************************************************************/
END