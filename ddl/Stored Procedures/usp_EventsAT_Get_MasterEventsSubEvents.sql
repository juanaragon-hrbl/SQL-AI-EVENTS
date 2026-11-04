
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_MasterEventsSubEvents]	
	-- OPTIONAL
	@Error int = 0 OUTPUT 
	,@ErrorMessage varchar(200) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:		dbo.usp_EventsAT_Get_MasterEventsSubEvents

USE:		DECLARE @e int, @em varchar(200)	
			EXEC usp_EventsAT_Get_MasterEventsSubEvents
					@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 0
			Print @em
DESCRIPTION:	Validations: given DSID is valid or not, whether the DSID belongs to the region of loggedinuser and the distributor belongs to the market 

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
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventsAT_Get_MasterEventsSubEvents'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'


/******************************************************************************
Retrieve Master Events and SubEvents for all Event Types (CE, CP & DE)
******************************************************************************/
BEGIN TRY
	
	SELECT DISTINCT 
		SGM.PK_EventSubTypeGroupMaster,
		SGM.EventSubTypeGroupMasterName,
		SG.PK_EventSubTypeGroup,
		EST.PK_EventSubType,
		EST.EventSubType
	FROM		
		dbo.EventSubTypeGroupMaster SGM (NOLOCK)
	INNER JOIN 
		dbo.EventSubTypeGroup SG (NOLOCK)
	ON
		SGM.PK_EventSubTypeGroupMaster = SG.PK_EventSubTypeGroupMaster
	INNER JOIN
		dbo.EventSubTypes EST (NOLOCK)
	ON
		EST.PK_EventSubTypeGroup = SG.PK_EventSubTypeGroup
		AND
		EST.PK_EventType = SG.PK_EventType
	WHERE
		SGM.IsActive = 1
	ORDER BY 1, 3, 4	
			
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



/******************************************************************************
	END Procedure
******************************************************************************/
END
