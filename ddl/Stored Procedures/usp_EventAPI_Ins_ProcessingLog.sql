

CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_ProcessingLog]
	@ModifiedBy varchar(50)
	,@ProcedureName varchar(100)
	,@ProcedureParameters varchar(100)
	,@StartTime datetime
	,@EndTime datetime
	,@RunTime varchar(10)
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Ins_ProcessingLog

USE:		EXEC usp_EventAPI_Ins_ProcessingLog
					@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@ModifiedBy = ''
					,@ProcedureName = ''
					,@ProcedureParameters = ''
					,@StartTime = ''
					,@EndTime = ''
					,@RunTime = ''
					,@IsDevQA = 0

DESCRIPTION:	Inserts record into dbo.ProcessingLog

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.ProcessingLog

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
SET @Error = 0
SET @ErrorMessage = 'No Error.'
/******************************************************************************
	be sure end time >= start time
******************************************************************************/
IF @StartTime > @EndTime
BEGIN
	SET @Error = 71
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @ProcedureName
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
insert record
******************************************************************************/
BEGIN TRY
INSERT
	dbo.ProcessingLog
(
	[ModifiedBy]
	,[ProcedureName]
	,[ProcedureParameters]
	,[StartTime]
	,[EndTime]
	,[RunTime]
)
SELECT
	@ModifiedBy 
	,@ProcedureName
	,@ProcedureParameters 
	,@StartTime 
	,@EndTime 
	,@RunTime
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @ProcedureName = ERROR_PROCEDURE()
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @ProcedureName
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @ProcedureName
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END