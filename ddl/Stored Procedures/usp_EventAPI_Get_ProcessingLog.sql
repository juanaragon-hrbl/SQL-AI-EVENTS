

CREATE PROCEDURE [dbo].[usp_EventAPI_Get_ProcessingLog]
	-- REQUIRED
	@PK_ProcessingLog int
	-- OPTIONAL
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_ProcessingLog

USE:			EXEC usp_EventAPI_Get_ProcessingLog
					@PK_ProcessingLog = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Retrieves record from dbo.ProcessingLog

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.ProcessingLog

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial
2   2019-10-17  SushmaA	SRE updates for NOLOCK, NOCOUNT, SELECT *

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_ProcessingLog'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_ProcessingLog FROM dbo.ProcessingLog with (nolock) WHERE PK_ProcessingLog = @PK_ProcessingLog)
BEGIN
	SET @Error = 195
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
Select record
******************************************************************************/
BEGIN TRY
	SELECT
		[PK_ProcessingLog]
		,[CreatedDateUTC] 
		,[CreatedBy]
		,[ModifiedBy] 
		,[ProcedureName]
		,[ProcedureParameters] 
		,[StartTime] 
		,[EndTime]
		,[RunTime]
	FROM 
		dbo.ProcessingLog(NOLOCK) 
	WHERE 
		PK_ProcessingLog = @PK_ProcessingLog
END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END