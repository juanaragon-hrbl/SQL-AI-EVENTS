CREATE PROCEDURE [dbo].[ usp_EventAPI_Get_EventSKUType ]	
	-- REQUIRED
	@PK_EventSKUType int	
	-- OPTIONAL
	,@Error int OUTPUT 
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_EventSKUType

USE:			EXEC usp_EventAPI_Get_EventSKUType
					@PK_EventSKUType = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Retrieves record from dbo.EventSKUType

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventSKUType

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
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_EventSKUType'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_EventSKUType FROM dbo.EventSKUType WITH (NOLOCK) WHERE PK_EventSKUType = @PK_EventSKUType)
BEGIN
	SET @Error = 187
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
select record
******************************************************************************/
BEGIN TRY
	SELECT
		[PK_EventSKUType]
		,[EventSKUTypeDesc]
		,[CreatedDateUTC] 
		,[CreatedBy] 
		,[ModifiedDateUTC] 
		,[ModifiedBy] 
	FROM 
		dbo.EventSKUType(NOLOCK)
	WHERE 
		PK_EventSKUType = @PK_EventSKUType
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