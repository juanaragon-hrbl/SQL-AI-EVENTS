
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventATAccessUserTypes]
	-- MANDATORY
	@UserID nVARCHAR(30)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:			dbo.usp_EventsAT_Get_EventATAccessUserTypes

USE:	
	DECLARE @e int, @em varchar(4000)
		
	EXEC usp_EventsAT_Get_EventATAccessUserTypes
					@UserID = 'veerarjuna'
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventATAccessUserTypes

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessUserTypes

VERSIONS
--------------------------------------------------------------------
1	2012-08-07	OrlandoL	Initial
2	2019-08-08	OrlandoL	Refactor code (SRE)
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/**************************************************************************************
 Verify if the LoggedUser is a valid User
****************************************************************************************/

IF NOT EXISTS (SELECT PK_EventATAccessUser FROM dbo.EventATAccessUser ET WITH(NOLOCK) WHERE EventATAccessUserName = @UserID)
BEGIN
		SET @Error = 280
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

;WITH UserAuthority (PK_EventATAccessUserType)
 AS (SELECT 
		PK_EventATAccessUserType
    FROM
		dbo.EventATAccessUser  WITH	(NOLOCK)
	WHERE
		EventATAccessUserName = @UserID)
SELECT 
	AUT.PK_EventATAccessUserType
	,AUT.EventATAccessUserType
FROM 
	dbo.EventATAccessUserTypes AUT WITH(NOLOCK)	
WHERE
		AUT.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM UserAuthority WITH(NOLOCK))	

			
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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END
