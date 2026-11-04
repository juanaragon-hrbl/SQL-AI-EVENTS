CREATE PROCEDURE [dbo].[usp_EventAPI_Del_Event]
	--Required
	@PK_Event int
	-- Optional
	,@Error	INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = NULL OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Del_Event

USE:		EXEC usp_EventAPI_Del_Event
				@PK_Event = 116
				--,@Error = @e OUTPUT  /* @e must be defined in the local call */
				--,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			

DESCRIPTION:	Deletes record from dbo.Event
NOTES:			
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
	1.1.0	2008-10-16	   Aarti		Initial
	1.2.0	2019-10-14     puertac	    SRE Implementation 

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 119
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
delete record
******************************************************************************/
BEGIN TRY
	DELETE FROM [dbo].[Event] WHERE PK_Event = @PK_Event
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH
/******************************************************************************
	end procedure
******************************************************************************/
END