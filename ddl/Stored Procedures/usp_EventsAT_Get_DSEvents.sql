
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_DSEvents]
	-- MANDATORY
	@PK_Locale INT
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:		dbo.usp_EventsAT_Get_DSEvents

USE:
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventsAT_Get_DSEvents
					 @PK_Locale = 77
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: On Manage DS Access Page, this SP call is a lookup for populating dropdown showing all the MasterEvents - SubTypeEvents
			 for Distributor Events (DE) only. 

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-11-15	SandhyaP	Initial
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

/******************************************************************************
Retrieve Master Events and SubEvents for Distributor Events (DE) only
******************************************************************************/
BEGIN TRY
	
	SELECT DISTINCT 
		SGM.PK_EventSubTypeGroupMaster,
		SGM.EventSubTypeGroupMasterName,
		SG.PK_EventSubTypeGroup,
		EST.PK_EventSubType,
		EST.EventSubType,
		ESTL.PK_EventSubTypeLocaleDesc,
		SGM.IsAtomic
	FROM		
		dbo.EventSubTypeGroupMaster SGM WITH(NOLOCK)
	INNER JOIN 
		dbo.EventSubTypeGroup SG WITH(NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SG.PK_EventSubTypeGroupMaster
	INNER JOIN
		dbo.EventSubTypeGroupLocale	SGL WITH(NOLOCK)
	ON
		SGL.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster
		AND
		SGL.PK_Locale = @PK_Locale	
	INNER JOIN
		dbo.EventSubTypes EST WITH(NOLOCK)
	ON
		EST.PK_EventSubTypeGroup = SG.PK_EventSubTypeGroup
		AND
		EST.PK_EventType = SG.PK_EventType		
	INNER JOIN
		dbo.EventSubTypeLocaleDesc ESTL WITH(NOLOCK)
	ON
		EST.PK_EventSubType = ESTL.PK_EventSubType
		AND
		ESTL.PK_Locale= @PK_Locale			
	WHERE
		SG.PK_EventType = 3
		AND 
		SGM.IsActive = 1
		AND
		EST.IsActive = 1
	ORDER BY 
		2,5	
			
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
	END Procedure
******************************************************************************/
END
